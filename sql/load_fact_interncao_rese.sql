-- load_fact_internacao.sql
-- Carrega a fact_internacao a partir de stg.stg_internacao
-- Pressupostos:
--  - staging: stg.stg_internacao com id_internacao (único por evento)
--  - dimensões: dwh.dim_paciente (SCD2), dwh.dim_hospital (SCD2), dwh.dim_diagnostico, dwh.dim_tempo
--  - dwh.fact_internacao já existe

-- Observações implementadas:
--  - Não duplica id_internacao (checa existência)
--  - Calcula dias_internado
--  - Calcula flag readmitido se houver alta anterior do mesmo paciente dentro de 30 dias anteriores à data_entrada

BEGIN;

-- 1) Garantir que as dimensões base estão com versões correntes (assume que merge_paciente/hospital rodaram)
-- 2) Inserir registros na tabela fato a partir da staging
INSERT INTO dwh.fact_internacao (
  id_internacao,
  dim_paciente_key,
  dim_hospital_key,
  dim_diagnostico_key,
  dim_tempo_key_admissao,
  dim_tempo_key_alta,
  data_entrada,
  data_alta,
  dias_internado,
  readmitido,
  custo_total,
  score_risco,
  created_at
)
SELECT
  s.id_internacao,
  -- paciente: pegar dim_paciente_key da versão corrente
  p.dim_paciente_key,
  -- hospital: versão corrente
  h.dim_hospital_key,
  -- diagnostico
  d.dim_diagnostico_key,
  -- tempo keys: vamos buscar (ou criar) na dim_tempo
  t_in.dim_tempo_key AS dim_tempo_key_admissao,
  t_out.dim_tempo_key AS dim_tempo_key_alta,
  -- datas e calculos
  s.data_entrada,
  s.data_alta,
  COALESCE( (s.data_alta::date - s.data_entrada::date), 0 )::INT AS dias_internado,
  -- readmitido: existe internacao anterior do mesmo paciente com data_alta between (data_entrada - 30 days) and (data_entrada - 1 day)
  CASE WHEN EXISTS (
        SELECT 1 FROM dwh.fact_internacao fprev
        WHERE fprev.dim_paciente_key = p.dim_paciente_key
          AND fprev.data_alta IS NOT NULL
          AND fprev.data_alta >= (s.data_entrada::date - INTERVAL '30 days')::date
          AND fprev.data_alta < s.data_entrada::date
      ) THEN true ELSE false END AS readmitido,
  COALESCE(s.custo_total, 0) AS custo_total,
  NULL::NUMERIC(5,2) AS score_risco,  -- placeholder: você pode atualizar esse campo via model ou regra
  now() as created_at
FROM stg.stg_internacao s
JOIN dwh.dim_paciente p
  ON p.paciente_id = s.paciente_id AND p.is_current = true
JOIN dwh.dim_hospital h
  ON h.hospital_id = s.hospital_id AND h.is_current = true
LEFT JOIN dwh.dim_diagnostico d
  ON d.codigo_cid = s.codigo_cid
-- tempo: admissão
LEFT JOIN dwh.dim_tempo t_in
  ON t_in.date = s.data_entrada::date
-- tempo: alta
LEFT JOIN dwh.dim_tempo t_out
  ON t_out.date = COALESCE(s.data_alta::date, s.data_entrada::date)
-- evitar duplicatas: inserir apenas se id_internacao ainda não estiver na fact
WHERE s.id_internacao IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM dwh.fact_internacao f WHERE f.id_internacao = s.id_internacao);

-- Nota: Se dim_tempo não contiver as datas, rode o script que popula dim_tempo antes (load_dim_tempo.sql).
COMMIT;

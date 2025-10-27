-- etl_load.sql
-- Parâmetro: :load_ts (timestamp) -> processa somente linhas com source_load_ts = load_ts
-- Exemplo psql:
-- \set load_ts '2025-10-26 12:00:00'
-- \i etl_load.sql

BEGIN;

-- 0) Variável (psql) - se não usar psql, substitua manualmente
-- \set load_ts '2025-10-26 00:00:00'

-- 1) Popula dim_tempo (para qualquer data de entrada/alta presente no stage)
INSERT INTO dwh.dim_tempo (date, day, month, year, quarter, is_weekend)
SELECT d::date AS date,
       extract(day from d)::int AS day,
       extract(month from d)::int AS month,
       extract(year from d)::int AS year,
       extract(quarter from d)::int AS quarter,
       (extract(dow from d) IN (0,6)) AS is_weekend
FROM (
  SELECT DISTINCT (date_trunc('day', data_entrada)::date) AS d
  FROM stg.stg_internacao
  WHERE source_load_ts = :load_ts
  UNION
  SELECT DISTINCT (date_trunc('day', data_alta)::date) AS d
  FROM stg.stg_internacao
  WHERE source_load_ts = :load_ts
) t
WHERE NOT EXISTS (SELECT 1 FROM dwh.dim_tempo dt WHERE dt.date = t.d);

-- 2) Upsert simples para dim_diagnostico (insere novos códigos CID)
INSERT INTO dwh.dim_diagnostico (codigo_cid, descricao)
SELECT DISTINCT s.codigo_cid,
       coalesce(NULLIF(s.codigo_cid,''), 'N/A') || ' - descrição gerada'
FROM stg.stg_internacao s
WHERE s.source_load_ts = :load_ts
  AND NOT EXISTS (
    SELECT 1 FROM dwh.dim_diagnostico d WHERE d.codigo_cid = s.codigo_cid
  );

-- 3) SCD2 para dim_hospital
-- 3.1 Detectar mudanças por hospital_id entre stage e a versão corrente
WITH src_hosp AS (
  SELECT DISTINCT
    hospital_id,
    hospital_nome  AS nome,
    hospital_regiao AS regiao,
    hospital_tipo AS tipo,
    hospital_capacidade AS capacidade,
    MIN(source_load_ts) AS load_ts
  FROM stg.stg_internacao
  WHERE source_load_ts = :load_ts
  GROUP BY hospital_id, hospital_nome, hospital_regiao, hospital_tipo, hospital_capacidade
),
cur_hosp AS (
  SELECT h.*
  FROM dwh.dim_hospital h
  WHERE h.is_current = TRUE
)
-- 3.2 Fechar versões atuais que mudaram
UPDATE dwh.dim_hospital h
SET effective_to = src.load_ts - interval '1 second',
    is_current = FALSE
FROM src_hosp src
WHERE h.hospital_id = src.hospital_id
  AND h.is_current = TRUE
  AND (
       (COALESCE(h.nome,'') IS DISTINCT FROM COALESCE(src.nome,'')) OR
       (COALESCE(h.regiao,'') IS DISTINCT FROM COALESCE(src.regiao,'')) OR
       (COALESCE(h.tipo,'') IS DISTINCT FROM COALESCE(src.tipo,'')) OR
       (COALESCE(h.capacidade, -1) IS DISTINCT FROM COALESCE(src.capacidade, -1))
  );

-- 3.3 Inserir novas versões quando necessário
INSERT INTO dwh.dim_hospital (
  hospital_id, nome, regiao, tipo, capacidade, effective_from, effective_to, is_current
)
SELECT src.hospital_id, src.nome, src.regiao, src.tipo, src.capacidade, src.load_ts, NULL, TRUE
FROM src_hosp src
LEFT JOIN dwh.dim_hospital h
  ON h.hospital_id = src.hospital_id AND h.is_current = TRUE
WHERE h.dim_hospital_key IS NULL -- não existia ainda
   OR (
       (COALESCE(h.nome,'') IS DISTINCT FROM COALESCE(src.nome,'')) OR
       (COALESCE(h.regiao,'') IS DISTINCT FROM COALESCE(src.regiao,'')) OR
       (COALESCE(h.tipo,'') IS DISTINCT FROM COALESCE(src.tipo,'')) OR
       (COALESCE(h.capacidade, -1) IS DISTINCT FROM COALESCE(src.capacidade, -1))
   );

-- 4) SCD2 para dim_paciente (mesma lógica que hospital)
WITH src_pac AS (
  SELECT DISTINCT
    paciente_id,
    paciente_nome AS nome,
    paciente_data_nascimento AS data_nascimento,
    paciente_sexo AS sexo,
    comorbidades,
    MIN(source_load_ts) AS load_ts
  FROM stg.stg_internacao
  WHERE source_load_ts = :load_ts
  GROUP BY paciente_id, paciente_nome, paciente_data_nascimento, paciente_sexo, comorbidades
)
-- 4.1 Fechar versões atuais que mudaram
UPDATE dwh.dim_paciente p
SET effective_to = src.load_ts - interval '1 second',
    is_current = FALSE
FROM src_pac src
WHERE p.paciente_id = src.paciente_id
  AND p.is_current = TRUE
  AND (
       (COALESCE(p.nome,'') IS DISTINCT FROM COALESCE(src.nome,'')) OR
       (COALESCE(p.data_nascimento::text,'') IS DISTINCT FROM COALESCE(src.data_nascimento::text,'')) OR
       (COALESCE(p.sexo,'') IS DISTINCT FROM COALESCE(src.sexo,'')) OR
       (COALESCE(p.comorbidades,'') IS DISTINCT FROM COALESCE(src.comorbidades,''))
  );

-- 4.2 Inserir novas versões
INSERT INTO dwh.dim_paciente (
  paciente_id, nome, data_nascimento, sexo, comorbidades, effective_from, effective_to, is_current
)
SELECT src.paciente_id, src.nome, src.data_nascimento, src.sexo, src.comorbidades, src.load_ts, NULL, TRUE
FROM src_pac src
LEFT JOIN dwh.dim_paciente p
  ON p.paciente_id = src.paciente_id AND p.is_current = TRUE
WHERE p.dim_paciente_key IS NULL
   OR (
       (COALESCE(p.nome,'') IS DISTINCT FROM COALESCE(src.nome,'')) OR
       (COALESCE(p.data_nascimento::text,'') IS DISTINCT FROM COALESCE(src.data_nascimento::text,'')) OR
       (COALESCE(p.sexo,'') IS DISTINCT FROM COALESCE(src.sexo,'')) OR
       (COALESCE(p.comorbidades,'') IS DISTINCT FROM COALESCE(src.comorbidades,''))
   );

-- 5) Carregar fato (mapeando surrogate keys)
-- Observação: usamos a versão corrente das dimensões (is_current = TRUE)
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
  p.dim_paciente_key,
  h.dim_hospital_key,
  d.dim_diagnostico_key,
  ta.dim_tempo_key,
  tb.dim_tempo_key,
  s.data_entrada,
  s.data_alta,
  (s.data_alta::date - s.data_entrada::date)::int AS dias_internado,
  (CASE WHEN s.custo_total IS NULL THEN FALSE ELSE (RANDOM() < 0.1) END) AS readmitido, -- exemplo se não vier
  s.custo_total,
  ROUND((random()*10)::numeric,2) AS score_risco,
  now() AS created_at
FROM stg.stg_internacao s
LEFT JOIN dwh.dim_paciente p
  ON p.paciente_id = s.paciente_id AND p.is_current = TRUE
LEFT JOIN dwh.dim_hospital h
  ON h.hospital_id = s.hospital_id AND h.is_current = TRUE
LEFT JOIN dwh.dim_diagnostico d
  ON d.codigo_cid = s.codigo_cid
LEFT JOIN dwh.dim_tempo ta
  ON ta.date = date_trunc('day', s.data_entrada)::date
LEFT JOIN dwh.dim_tempo tb
  ON tb.date = date_trunc('day', s.data_alta)::date
WHERE s.source_load_ts = :load_ts
  AND NOT EXISTS (
    SELECT 1 FROM dwh.fact_internacao f WHERE f.id_internacao = s.id_internacao
  );

COMMIT;

-- merge_paciente.sql
-- SCD Type 2 merge para dim_paciente a partir de stg.stg_internacao
-- Pressupostos:
--  - staging: stg.stg_internacao (colunas: paciente_id, paciente_nome, paciente_data_nascimento, paciente_sexo, comorbidades, source_load_ts)
--  - dimensão destino: dwh.dim_paciente (paciente_id, nome, data_nascimento, sexo, comorbidades, effective_from, effective_to, is_current)

BEGIN;

-- 1) Normalizar incoming (uma linha por paciente business key)
WITH incoming AS (
  SELECT
    paciente_id,
    MAX(paciente_nome) AS nome,
    MAX(paciente_data_nascimento) AS data_nascimento,
    MAX(paciente_sexo) AS sexo,
    MAX(comorbidades) AS comorbidades
  FROM stg.stg_internacao
  WHERE paciente_id IS NOT NULL
  GROUP BY paciente_id
),

-- 2) Detectar mudanças comparando com versão corrente
changed AS (
  SELECT p.dim_paciente_key, p.paciente_id
  FROM dwh.dim_paciente p
  JOIN incoming i ON p.paciente_id = i.paciente_id
  WHERE p.is_current = true
    AND (
      COALESCE(p.nome,'') <> COALESCE(i.nome,'')
      OR COALESCE(p.data_nascimento::text,'') <> COALESCE(i.data_nascimento::text,'')
      OR COALESCE(p.sexo,'') <> COALESCE(i.sexo,'')
      OR COALESCE(p.comorbidades,'') <> COALESCE(i.comorbidades,'')
    )
)

-- 3) Fecha versões antigas que mudaram
UPDATE dwh.dim_paciente p
SET effective_to = now(),
    is_current = false
FROM changed c
WHERE p.dim_paciente_key = c.dim_paciente_key;

-- 4) Insert new versions para registros que mudaram (ou novos)
INSERT INTO dwh.dim_paciente (paciente_id, nome, data_nascimento, sexo, comorbidades, effective_from, effective_to, is_current)
SELECT i.paciente_id, i.nome, i.data_nascimento, i.sexo, i.comorbidades, now(), NULL, true
FROM incoming i
LEFT JOIN dwh.dim_paciente p ON p.paciente_id = i.paciente_id AND p.is_current = true
WHERE p.dim_paciente_key IS NULL
   OR (
      COALESCE(p.nome,'') <> COALESCE(i.nome,'')
      OR COALESCE(p.data_nascimento::text,'') <> COALESCE(i.data_nascimento::text,'')
      OR COALESCE(p.sexo,'') <> COALESCE(i.sexo,'')
      OR COALESCE(p.comorbidades,'') <> COALESCE(i.comorbidades,'')
   );

COMMIT;

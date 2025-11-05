
UPDATE dwh.dim_paciente d
SET effective_to = NOW(), is_current = FALSE
FROM stg.dim_paciente s
WHERE d.paciente_id = s.paciente_id
  AND d.is_current = TRUE
  AND (
        d.nome IS DISTINCT FROM s.nome OR
        d.data_nascimento IS DISTINCT FROM s.data_nascimento OR
        d.sexo IS DISTINCT FROM s.sexo OR
        d.comorbidades IS DISTINCT FROM s.comorbidades
      );


INSERT INTO dwh.dim_paciente (paciente_id, nome, data_nascimento, sexo, comorbidades, effective_from, effective_to, is_current)
SELECT s.paciente_id, s.nome, s.data_nascimento, s.sexo, s.comorbidades, NOW(), NULL, TRUE
FROM stg.dim_paciente s
LEFT JOIN dwh.dim_paciente d
  ON s.paciente_id = d.paciente_id AND d.is_current = TRUE
WHERE d.paciente_id IS NULL
   OR (
        d.nome IS DISTINCT FROM s.nome OR
        d.data_nascimento IS DISTINCT FROM s.data_nascimento OR
        d.sexo IS DISTINCT FROM s.sexo OR
        d.comorbidades IS DISTINCT FROM s.comorbidades
      );

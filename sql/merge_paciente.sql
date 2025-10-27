UPDATE dwh.dim_paciente d
SET effective_to = now(), is_current = false
FROM stg.stg_dim_paciente s
WHERE d.paciente_id = s.paciente_id
AND d.is_current = true
AND (d.nome <> s.nome
        OR d.data_nascimento <> s.data_nascimento
        OR d.sexo <> s.sexo
        OR d.comorbidades <> s.comorbidades);

INSERT INTO dwh.dim_paciente (paciente_id, nome, data_nascimento, sexo, 
comorbidades, effective_from, effective_to, is_current)

SELECT 
    s.paciente_id, s.nome, s.data_nascimento, s.sexo, s.comorbidades,
    now(), NULL, true
FROM stg.stg_dim_paciente s
LEFT JOIN dwh.dim_paciente d
    ON s.id_paciente = d.id_paciente AND d.is_current = true
WHERE d.paciente_id IS NULL;




--dim_hospital_key,hospital_id,nome,regiao,tipo,capacidade,effective_from,effective_to,is_current
UPDATE dwh.dim_hospital d
SET effective_to = now(), 
    is_current = false
FROM stg.stg_dim_hospital s
WHERE d.hospital_id = s.hospital_id
AND d.is_current = true
AND (d.nome <> s.nome
    OR d.tipo <> s.tipo
    OR d.regiao <> s.regiao
    OR d.capacidade <> s.capacidade);

INSERT INTO dwh.dim_hospital (hospital_id, nome, regiao, tipo, capacidade, effective_from, effective_to, is_current)

SELECT
    s.hospital_id, s.nome, s.regiao, s.tipo, s.capacidade,
    now(), NULL, true
FROM stg.stg_dim_hospital s
LEFT JOIN dwh.dim_hospital d
    ON s.hospital_id = d.hospital_id AND d.is_current = true
WHERE d.hospital_key IS NULL;

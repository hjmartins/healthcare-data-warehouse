--dim_hospital_key,hospital_id,nome,regiao,tipo,capacidade,effective_from,effective_to,is_current

UPDATE dwh.dim_hospital d
SET effective_to = NOW(), is_current = FALSE
FROM stg.dim_hospital s
WHERE d.hospital_id = s.hospital_id
  AND d.is_current = TRUE
  AND (
        d.nome IS DISTINCT FROM s.nome OR
        d.regiao IS DISTINCT FROM s.regiao OR
        d.tipo IS DISTINCT FROM s.tipo OR
        d.capacidade IS DISTINCT FROM s.capacidade
      );

INSERT INTO dwh.dim_hospital (hospital_id, nome, regiao, tipo, capacidade, effective_from, effective_to, is_current)
SELECT s.hospital_id, s.nome, s.regiao, s.tipo, s.capacidade, NOW(), NULL, TRUE
FROM stg.dim_hospital s
LEFT JOIN dwh.dim_hospital d
  ON s.hospital_id = d.hospital_id AND d.is_current = TRUE
WHERE d.hospital_id IS NULL
   OR (
        d.nome IS DISTINCT FROM s.nome OR
        d.regiao IS DISTINCT FROM s.regiao OR
        d.tipo IS DISTINCT FROM s.tipo OR
        d.capacidade IS DISTINCT FROM s.capacidade
      );

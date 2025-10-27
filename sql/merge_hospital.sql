-- merge_hospital.sql
-- SCD Type 2 merge para dim_hospital a partir de stg.stg_internacao
-- Pressupostos:
--  - staging: stg.stg_internacao (hospital_id, hospital_nome, hospital_regiao, hospital_tipo, hospital_capacidade)
--  - dimensão destino: dwh.dim_hospital (hospital_id, nome, regiao, tipo, capacidade, effective_from, effective_to, is_current)

BEGIN;

INSERT INTO dwh.dim_hospital (
    hospital_id,
    nome,
    regiao,
    tipo,
    capacidade,
    effective_from,
    effective_to,
    is_current
)
SELECT
    st.hospital_id,
    st.hospital_nome,
    st.hospital_regiao,
    st.hospital_tipo,
    st.hospital_capacidade,
    NOW(),
    NULL,
    TRUE
FROM stg.stg_internacao st
LEFT JOIN dwh.dim_hospital dh
ON st.hospital_id = dh.hospital_id
AND dh.is_current = TRUE
WHERE dh.dim_hospital_key IS NULL OR (
    dh.nome <> st.hospital_nome
 OR dh.regiao <> st.hospital_regiao
 OR dh.tipo <> st.hospital_tipo
 OR dh.capacidade <> st.hospital_capacidade
);

UPDATE dwh.dim_hospital dh
SET effective_to = NOW(), is_current = FALSE
WHERE dh.hospital_id IN (
    SELECT hospital_id FROM stg.stg_internacao
)
AND dh.is_current = TRUE
AND dh.effective_to IS NULL
AND EXISTS (
    SELECT 1 FROM dwh.dim_hospital dh2
    WHERE dh2.hospital_id = dh.hospital_id
    AND dh2.is_current = TRUE
    AND dh2.dim_hospital_key <> dh.dim_hospital_key
);

COMMIT;

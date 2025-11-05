INSERT INTO dwh.dim_diagnostico (dim_diagnostico_key, codigo_cid, descricao)
SELECT s.dim_diagnostico_key, s.codigo_cid, s.descricao
FROM stg.dim_diagnostico s
ON CONFLICT (dim_diagnostico_key) DO UPDATE
SET descricao = EXCLUDED.descricao;
-- dim_diagnostico_key,codigo_cid,descricao
TRUNCATE TABLE dwh.dim_diagnostico;

INSERT INTO dwh.dim_diagnostico 
SELECT dim_diagnostico_key,codigo_cid,descricao
FROM stg.stg_dim_diagnostico;

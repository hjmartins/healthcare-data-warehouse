-- load_dim_diagnostico.sql
-- Carrega/atualiza a dimensão de diagnóstico (CID)
-- Pressuposto:
--  - stg.stg_internacao contém codigo_cid e possivelmente descricao
--  - dwh.dim_diagnostico (codigo_cid, descricao)

BEGIN;

INSERT INTO dwh.dim_diagnostico (codigo_cid, descricao)
SELECT DISTINCT
    codigo_cid,
    'CID Desconhecido'
FROM stg.stg_internacao st
LEFT JOIN dwh.dim_diagnostico d
ON st.codigo_cid = d.codigo_cid
WHERE d.dim_diagnostico_key IS NULL;

-- Opcional: se você tiver uma tabela de mapeamento código->descrição (master), você pode fazer UPDATE para popular descricao.
-- Exemplo:
-- UPDATE dwh.dim_diagnostico d
-- SET descricao = m.descricao
-- FROM master.cid_master m
-- WHERE d.codigo_cid = m.codigo_cid AND (d.descricao IS NULL OR d.descricao = '');

COMMIT;

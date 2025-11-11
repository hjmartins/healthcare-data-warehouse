CREATE OR REPLACE VIEW dwh.vw_readmissoes AS
SELECT
    t.year,
    t.month,
    COUNT(*) FILTER (WHERE f.readmitido = TRUE) AS total_readmitidos,
    COUNT(*) AS total_internacoes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE f.readmitido = TRUE) / COUNT(*), 2) AS percentual_readmissao
FROM dwh.fact_internacao f
JOIN dwh.dim_tempo t ON f.dim_tempo_key_admissao = t.dim_tempo_key
GROUP BY t.year, t.month
ORDER BY t.year, t.month;
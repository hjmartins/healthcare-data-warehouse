CREATE OR REPLACE VIEW dwh.interacao_mes_ano AS
SELECT
    t.year,
    t.month,
    COUNT(*) AS total_internacoes
FROM dwh.fact_internacao f
JOIN dwh.dim_tempo t
    ON t.dim_tempo_key = f.dim_tempo_key_admissao
GROUP BY t.year, t.month
ORDER BY t.year, t.month;

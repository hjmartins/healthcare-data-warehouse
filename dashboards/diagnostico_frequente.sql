CREATE OR REPLACE VIEW dwh.diagnostico_frequente AS
SELECT
    t.year,
    t.month,
    d.descricao AS diagnostico,
    COUNT(*) AS total
FROM dwh.fact_internacao f
JOIN dwh.dim_tempo t
    ON t.dim_tempo_key = f.dim_tempo_key_admissao
JOIN dwh.dim_diagnostico d
    ON d.dim_diagnostico_key = f.dim_diagnostico_key
GROUP BY t.year, t.month, d.descricao
ORDER BY t.year, t.month, total DESC;

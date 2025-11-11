CREATE OR REPLACE VIEW dwh.internacoes_trimestre AS
SELECT
    t.year,
    t.quarter,
    COUNT(*) AS total_internacoes
FROM dwh.fact_internacao f
JOIN dwh.dim_tempo t
    ON t.dim_tempo_key = f.dim_tempo_key_admissao
GROUP BY t.year, t.quarter
ORDER BY t.year, t.quarter;

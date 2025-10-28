SELECT
    t.year,
    t.month,
    COUNT(*) AS total_internacoes
FROM fact_internacao f
JOIN dim_tempo t
    ON t.dim_tempo_key = f.sk_tempo_admissao
GROUP BY t.year, t.month
ORDER BY t.year, t.month;

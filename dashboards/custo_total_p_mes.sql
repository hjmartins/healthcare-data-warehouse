SELECT
    t.year,
    t.month,
    SUM(f.custo_total) AS custo_total,
    ROUND(AVG(f.custo_total),2) AS custo_medio
FROM fact_internacao f
JOIN dim_tempo t
    ON t.dim_tempo_key = f.sk_tempo_admissao
GROUP BY t.year, t.month
ORDER BY t.year, t.month;

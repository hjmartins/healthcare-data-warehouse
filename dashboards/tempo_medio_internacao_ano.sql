SELECT
    t.year,
    ROUND(AVG(f.dias_internado), 2) AS media_dias
FROM fact_internacao f
JOIN dim_tempo t
    ON t.dim_tempo_key = f.sk_tempo_alta
GROUP BY t.year
ORDER BY t.year;

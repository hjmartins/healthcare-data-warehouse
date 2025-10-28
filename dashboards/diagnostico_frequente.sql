SELECT
    t.year,
    t.month,
    d.descricao AS diagnostico,
    COUNT(*) AS total
FROM fact_internacao f
JOIN dim_tempo t
    ON t.dim_tempo_key = f.sk_tempo_admissao
JOIN dim_diagnostico d
    ON d.sk_diagnostico = f.sk_diagnostico
GROUP BY t.year, t.month, d.descricao
ORDER BY t.year, t.month, total DESC;

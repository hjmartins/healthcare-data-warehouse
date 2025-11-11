CREATE OR REPLACE VIEW dwh.tempo_medio_internacoes_ano AS
SELECT
    t.year,
    ROUND(AVG(f.dias_internado), 2) AS media_dias
FROM dwh.fact_internacao f
JOIN dwh.dim_tempo t
    ON t.dim_tempo_key = f.dim_tempo_key_alta
GROUP BY t.year
ORDER BY t.year;

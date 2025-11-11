CREATE OR REPLACE VIEW dwh.weekend_X_weekday AS
SELECT
    t.is_weekend,
    COUNT(*) AS total_internacoes
FROM dwh.fact_internacao f
JOIN dwh.dim_tempo t
    ON t.dim_tempo_key = f.dim_tempo_key_admissao
GROUP BY t.is_weekend;

-- Cria a view no schema dwh
CREATE OR REPLACE VIEW dwh.vw_custos_mensais AS
SELECT
    t.year,
    t.month,
    SUM(f.custo_total) AS custo_total,
    ROUND(AVG(f.custo_total), 2) AS custo_medio
FROM dwh.fact_internacao f
JOIN dwh.dim_tempo t
    ON t.dim_tempo_key = f.dim_tempo_key_admissao
GROUP BY t.year, t.month
ORDER BY t.year, t.month;

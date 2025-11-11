CREATE OR REPLACE VIEW dwh.vw_kpis_gerais AS
SELECT
    COUNT(DISTINCT f.dim_paciente_key) AS total_pacientes,
    COUNT(f.fact_internacao_key) AS total_internacoes,
    ROUND(SUM(f.custo_total), 2) AS custo_total,
    ROUND(AVG(f.custo_total), 2) AS custo_medio,
    ROUND(AVG(f.dias_internado), 2) AS dias_medio,
    ROUND(100.0 * COUNT(*) FILTER (WHERE f.readmitido = TRUE) / COUNT(*), 2) AS taxa_readmissao
FROM dwh.fact_internacao f;

CREATE OR REPLACE VIEW dwh.vw_pacientes_por_genero AS
SELECT
    p.sexo,
    COUNT(DISTINCT f.dim_paciente_key) AS total_pacientes,
    ROUND(100.0 * COUNT(DISTINCT f.dim_paciente_key) / SUM(COUNT(DISTINCT f.dim_paciente_key)) OVER (), 2) AS percentual
FROM dwh.fact_internacao f
JOIN dwh.dim_paciente p ON f.dim_paciente_key = p.dim_paciente_key
GROUP BY p.sexo;

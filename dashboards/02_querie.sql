SELECT d.codigo_cid, d.descricao,
  COUNT(*) AS n, ROUND(AVG(f.custo_total)::numeric,2) AS custo_medio
FROM dwh.fact_internacao f
JOIN dwh.dim_diagnostico d ON f.dim_diagnostico_key = d.dim_diagnostico_key
GROUP BY d.codigo_cid, d.descricao
ORDER BY n DESC
LIMIT 10;

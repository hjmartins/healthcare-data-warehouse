SELECT
  t.year, t.month,
  h.nome AS hospital,
  COUNT(*) FILTER (WHERE f.readmitido = true) AS readmissoes,
  COUNT(*) AS total_internacoes,
  ROUND(100.0 * COUNT(*) FILTER (WHERE f.readmitido = true) / NULLIF(COUNT(*),0),2) AS taxa_readmissao_pct
FROM dwh.fact_internacao f
JOIN dwh.dim_tempo t ON f.dim_tempo_key_admissao = t.dim_tempo_key
JOIN dwh.dim_hospital h ON f.dim_hospital_key = h.dim_hospital_key AND h.is_current = true
GROUP BY t.year, t.month, h.nome
ORDER BY t.year DESC, t.month DESC, taxa_readmissao_pct DESC;

SELECT decile, COUNT(*) as n,
  ROUND(100.0 * SUM(CASE WHEN readmitido THEN 1 ELSE 0 END) / NULLIF(COUNT(*),0),2) as pct_readmit
FROM (
  SELECT *, NTILE(10) OVER (ORDER BY score_risco DESC) as decile
  FROM dwh.fact_internacao
) t
GROUP BY decile
ORDER BY decile;


WITH cohorts AS (
  SELECT
    f.*,
    date_trunc('month', f.data_entrada)::date AS cohort_month,
    lead(f.data_entrada) OVER (PARTITION BY f.dim_paciente_key ORDER BY f.data_entrada) AS next_admission
  FROM dwh.fact_internacao f
)
SELECT
  cohort_month,
  COUNT(*) AS cohort_size,
  COUNT(*) FILTER (WHERE next_admission IS NOT NULL AND next_admission <= f.data_entrada + INTERVAL '30 days') AS readmit_30d,
  ROUND(100.0 * COUNT(*) FILTER (WHERE next_admission IS NOT NULL AND next_admission <= f.data_entrada + INTERVAL '30 days') / NULLIF(COUNT(*),0),2) AS pct_readmit_30d
FROM cohorts f
GROUP BY cohort_month
ORDER BY cohort_month;

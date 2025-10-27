INSERT INTO dwh.dim_tempo (date, day, month, year, quarter, is_weekend)
SELECT DISTINCT
    d::date AS date,
    EXTRACT(DAY FROM d),
    EXTRACT(MONTH FROM d),
    EXTRACT(YEAR FROM d),
    EXTRACT(QUARTER FROM d),
    CASE WHEN EXTRACT(ISODOW FROM d) IN (6,7) THEN TRUE ELSE FALSE END
FROM (
    SELECT data_entrada AS d FROM stg.stg_internacao
    UNION
    SELECT data_alta AS d FROM stg.stg_internacao
) t
LEFT JOIN dwh.dim_tempo dt
ON t.d::date = dt.date
WHERE dt.dim_tempo_key IS NULL;

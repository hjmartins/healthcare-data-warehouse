INSERT INTO dwh.dim_tempo (dim_tempo_key, date, day, month, year, quarter, is_weekend)
SELECT s.dim_tempo_key, s.date, s.day, s.month, s.year, s.quarter, s.is_weekend
FROM stg.dim_tempo s
ON CONFLICT (dim_tempo_key) DO NOTHING;
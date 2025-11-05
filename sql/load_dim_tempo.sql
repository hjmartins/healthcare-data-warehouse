INSERT INTO dwh.dim_tempo
SELECT s.*
FROM stg.dim_tempo s
ON CONFLICT (dim_tempo_key) DO NOTHING;
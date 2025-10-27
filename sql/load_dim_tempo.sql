--dim_tempo_key,date,day,month,year,quarter,is_weekend
TRUNCATE TABLE dwh.dim_tempo;

INSERT INTO dwh.dim_tempo
SELECT dim_tempo_key, date, dia, mes, ano, quarter, is_weekend
FROM stg.stg_dim_tempo;

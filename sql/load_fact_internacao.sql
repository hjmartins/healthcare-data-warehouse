INSERT INTO dwh.fact_internacao (
    id_internacao,
    dim_paciente_key,
    dim_hospital_key,
    dim_diagnostico_key,
    dim_tempo_key_admissao,
    dim_tempo_key_alta,
    data_entrada,
    data_alta,
    dias_internado,
    readmitido,
    custo_total,
    score_risco
)
SELECT
    st.id_internacao,
    dp.dim_paciente_key,
    dh.dim_hospital_key,
    dd.dim_diagnostico_key,
    dta.dim_tempo_key,
    dtb.dim_tempo_key,
    st.data_entrada,
    st.data_alta,
    DATE_PART('day', st.data_alta - st.data_entrada),
    FALSE,
    st.custo_total,
    ROUND(random() * 90 + 10, 2)
FROM stg.stg_internacao st
JOIN dwh.dim_paciente dp ON st.paciente_id = dp.paciente_id AND dp.is_current = TRUE
JOIN dwh.dim_hospital dh ON st.hospital_id = dh.hospital_id AND dh.is_current = TRUE
JOIN dwh.dim_diagnostico dd ON st.codigo_cid = dd.codigo_cid
JOIN dwh.dim_tempo dta ON st.data_entrada::date = dta.date
JOIN dwh.dim_tempo dtb ON st.data_alta::date = dtb.date;

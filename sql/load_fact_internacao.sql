--fact_internacao_key,id_internacao,dim_paciente_key,dim_hospital_key,dim_diagnostico_key,
--dim_tempo_key_admissao,dim_tempo_key_alta,data_entrada,data_alta,dias_internado,readmitido,custo_total,score_risco
INSERT INTO dwh.fact_internacao(
    id_internacao, dim_paciente_key, dim_hospital_key, dim_diagnostico_key,
    dim_tempo_key_admissao, dim_tempo_key_alta, data_entrada, data_alta, dias_internado,
    readmitido, custo_total, score_risco
)
SELECT
    s.id_internacao,
    p.dim_paciente_key,
    h.dim_hospital_key,
    d.dim_diagnostico_key,
    s.dim_tempo_key_admissao,
    s.dim_tempo_key_alta,
    s.data_entrada,
    s.data_alta,
    s.dias_internado,
    s.readmitido,
    s.custo_total,
    s.score_risco
FROM stg.stg_fact_internacao s
JOIN dwh.dim_paciente p ON p.dim_paciente_key = s.dim_paciente_key AND p.is_current = true
JOIN dwh.dim_hospital h ON h.dim_hospital_key = s.dim_hospital_key AND h.is_current = true
JOIN dwh.dim_diagnostico d ON d.dim_diagnostico_key = s.dim_diagnostico_key;
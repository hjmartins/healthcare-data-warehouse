--fact_internacao_key,id_internacao,dim_paciente_key,dim_hospital_key,dim_diagnostico_key,
--dim_tempo_key_admissao,dim_tempo_key_alta,data_entrada,data_alta,dias_internado,readmitido,custo_total,score_risco
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
    score_risco,
    created_at
)
SELECT
    s.id_internacao,
    s.dim_paciente_key,
    s.dim_hospital_key,
    s.dim_diagnostico_key,
    s.dim_tempo_key_admissao,
    s.dim_tempo_key_alta,
    s.data_entrada,
    s.data_alta,
    s.dias_internado,
    s.readmitido,
    s.custo_total,
    s.score_risco,
    NOW()
FROM stg.fact_internacao s
ON CONFLICT (id_internacao) DO NOTHING;

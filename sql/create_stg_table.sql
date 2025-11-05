CREATE SCHEMA IF NOT EXISTS stg;

-- STG Dim Tempo
CREATE TABLE IF NOT EXISTS stg.dim_tempo (
    dim_tempo_key INT,
    date DATE,
    day INT,
    month INT,
    year INT,
    quarter INT,
    is_weekend BOOLEAN,
    source_load_ts TIMESTAMP DEFAULT NOW()
);

-- STG Dim Diagnóstico
CREATE TABLE IF NOT EXISTS stg.dim_diagnostico (
    dim_diagnostico_key INT,
    codigo_cid VARCHAR(10),
    descricao TEXT,
    source_load_ts TIMESTAMP DEFAULT NOW()
);

-- STG Dim Paciente
CREATE TABLE IF NOT EXISTS stg.dim_paciente (
    dim_paciente_key BIGINT,
    paciente_id VARCHAR(50),
    nome VARCHAR(255),
    data_nascimento DATE,
    sexo VARCHAR(10),
    comorbidades TEXT,
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    is_current BOOLEAN,
    source_load_ts TIMESTAMP DEFAULT NOW()
);

-- STG Dim Hospital
CREATE TABLE IF NOT EXISTS stg.dim_hospital (
    dim_hospital_key BIGINT,
    hospital_id VARCHAR(50),
    nome VARCHAR(255),
    regiao VARCHAR(100),
    tipo VARCHAR(100),
    capacidade INT,
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    is_current BOOLEAN,
    source_load_ts TIMESTAMP DEFAULT NOW()
);

-- STG Fact Internação
CREATE TABLE IF NOT EXISTS stg.fact_internacao (
    fact_internacao_key BIGINT,
    id_internacao VARCHAR(100),
    dim_paciente_key BIGINT,
    dim_hospital_key BIGINT,
    dim_diagnostico_key BIGINT,
    dim_tempo_key_admissao INT,
    dim_tempo_key_alta INT,
    data_entrada TIMESTAMP,
    data_alta TIMESTAMP,
    dias_internado INT,
    readmitido BOOLEAN,
    custo_total NUMERIC(12,2),
    score_risco NUMERIC(5,2),
    created_at TIMESTAMP,
    source_load_ts TIMESTAMP DEFAULT NOW()
);

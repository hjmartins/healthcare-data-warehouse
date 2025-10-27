-- Dim Tempo
CREATE TABLE IF NOT EXISTS dwh.dim_tempo (
    dim_tempo_key INT PRIMARY KEY,
    date DATE,
    day INT,
    month INT,
    year INT,
    quarter INT,
    is_weekend BOOLEAN
);

-- Dim Diagnóstico
CREATE TABLE IF NOT EXISTS dwh.dim_diagnostico (
    dim_diagnostico_key INT PRIMARY KEY,
    codigo_cid VARCHAR(10),
    descricao TEXT
);

-- Dim Paciente (SCD Type 2)
CREATE TABLE IF NOT EXISTS dwh.dim_paciente (
    dim_paciente_key BIGSERIAL PRIMARY KEY,
    paciente_id VARCHAR(50),
    nome VARCHAR(255),
    data_nascimento DATE,
    sexo VARCHAR(10),
    comorbidades TEXT,
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE
);

-- Dim Hospital (SCD Type 2)
CREATE TABLE IF NOT EXISTS dwh.dim_hospital (
    dim_hospital_key BIGSERIAL PRIMARY KEY,
    hospital_id VARCHAR(50),
    nome VARCHAR(255),
    regiao VARCHAR(100),
    tipo VARCHAR(100),
    capacidade INT,
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    is_current BOOLEAN DEFAULT TRUE
);

-- Fact Internação
CREATE TABLE IF NOT EXISTS dwh.fact_internacao (
    fact_internacao_key BIGSERIAL PRIMARY KEY,
    id_internacao VARCHAR(100) UNIQUE,
    dim_paciente_key BIGINT REFERENCES dwh.dim_paciente(dim_paciente_key),
    dim_hospital_key BIGINT REFERENCES dwh.dim_hospital(dim_hospital_key),
    dim_diagnostico_key BIGINT REFERENCES dwh.dim_diagnostico(dim_diagnostico_key),
    dim_tempo_key_admissao INT REFERENCES dwh.dim_tempo(dim_tempo_key),
    dim_tempo_key_alta INT REFERENCES dwh.dim_tempo(dim_tempo_key),
    data_entrada TIMESTAMP,
    data_alta TIMESTAMP,
    dias_internado INT,
    readmitido BOOLEAN,
    custo_total NUMERIC(12,2),
    score_risco NUMERIC(5,2),
    created_at TIMESTAMP DEFAULT now()
);

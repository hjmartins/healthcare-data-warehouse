-- 0. Schema
CREATE SCHEMA IF NOT EXISTS stg;
CREATE SCHEMA IF NOT EXISTS dwh;

-- 1. Dimensão Tempo (estática)
CREATE TABLE dwh.dim_tempo (
  dim_tempo_key SERIAL PRIMARY KEY,
  date DATE UNIQUE,
  day INT,
  month INT,
  year INT,
  quarter INT,
  is_weekend BOOLEAN
);

-- 2. Dimensão Diagnóstico (CID-10)
CREATE TABLE dwh.dim_diagnostico (
  dim_diagnostico_key SERIAL PRIMARY KEY,
  codigo_cid VARCHAR(10) UNIQUE,
  descricao TEXT
);

-- 3. Dimensão Hospital (SCD Type 2)
CREATE TABLE dwh.dim_hospital (
  dim_hospital_key BIGSERIAL PRIMARY KEY,
  hospital_id VARCHAR(50),           -- business key
  nome VARCHAR(255),
  regiao VARCHAR(100),
  tipo VARCHAR(100),
  capacidade INT,
  effective_from TIMESTAMP WITHOUT TIME ZONE,
  effective_to TIMESTAMP WITHOUT TIME ZONE,
  is_current BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_dim_hospital_bk ON dwh.dim_hospital(hospital_id);

-- 4. Dimensão Paciente (SCD Type 2)
CREATE TABLE dwh.dim_paciente (
  dim_paciente_key BIGSERIAL PRIMARY KEY,
  paciente_id VARCHAR(50),           -- business key (ex: patient registry)
  nome VARCHAR(255),
  data_nascimento DATE,
  sexo VARCHAR(10),
  comorbidades TEXT,                 -- JSON or CSV list
  effective_from TIMESTAMP WITHOUT TIME ZONE,
  effective_to TIMESTAMP WITHOUT TIME ZONE,
  is_current BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_dim_paciente_bk ON dwh.dim_paciente(paciente_id);

-- 5. Tabela fato de internação
CREATE TABLE dwh.fact_internacao (
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

-- 6. Staging tables (raw)
CREATE TABLE stg.stg_internacao (
  id_internacao VARCHAR(100),
  paciente_id VARCHAR(50),
  hospital_id VARCHAR(50),
  codigo_cid VARCHAR(10),
  data_entrada TIMESTAMP,
  data_alta TIMESTAMP,
  custo_total NUMERIC(12,2),
  comorbidades TEXT,
  paciente_nome VARCHAR(255),
  paciente_data_nascimento DATE,
  paciente_sexo VARCHAR(10),
  hospital_nome VARCHAR(255),
  hospital_regiao VARCHAR(100),
  hospital_tipo VARCHAR(100),
  hospital_capacidade INT,
  source_load_ts TIMESTAMP DEFAULT now()
);

import argparse
import random
from faker import Faker
import pandas as pd
from datetime import datetime, timedelta

fake = Faker()
Faker.seed(123)
random.seed(123)
''' Generate synthetic healthcare data and save to CSV 
    rows:
    dim_tempo_key SERIAL PRIMARY KEY,
  date DATE UNIQUE,
  day INT,
  month INT,
  year INT,
  quarter INT,
  is_weekend BOOLEAN
  
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
  '''
PERIOD_START = pd.to_datetime('2018-01-01')
PERIOD_END = pd.to_datetime('2024-12-31')

N_HOSPITALS = 20
N_CID = 80
N_PATIENTS = 1000
N_FATOS = 15000


#taBELA DIM TEMPO

dates = pd.date_range(PERIOD_START, PERIOD_END, freq='D')
df_dim_tempo = pd.DataFrame({
    'date': dates.date,
    'day': dates.day,
    'month': dates.month,
    'year': dates.year,
    'quarter': dates.quarter,
    'is_weekend': dates.weekday >= 5
})
df_dim_tempo.insert(0, 'dim_tempo_key', range(1, len(df_dim_tempo) + 1))
df_dim_tempo.to_csv('data/dim_tempo.csv', index=False)

# tabela dim diagnostico
cid_codes = [f'A{random.randint(0,99)}.{random.randint(0,9):02d}'for _ in range(N_CID)]
df_diagnostico = pd.DataFrame({
    'dim_diagnostico_key': range(1, N_CID + 1),
    'codigo_cid': cid_codes,
    'descricao': [fake.sentence(nb_words=6) for _ in range(N_CID)]
})
df_diagnostico.to_csv('data/dim_diagnostico.csv', index=False)

#DIM HOSPITAL
''' dim_hospital_key BIGSERIAL PRIMARY KEY,
  hospital_id VARCHAR(50),           -- business key
  nome VARCHAR(255),
  regiao VARCHAR(100),
  tipo VARCHAR(100),
  capacidade INT,
  effective_from TIMESTAMP WITHOUT TIME ZONE,
  effective_to TIMESTAMP WITHOUT TIME ZONE,
  is_current BOOLEAN DEFAULT TRUE'''

hosp_data = []
for key in range(1, N_HOSPITALS + 1):
    hosp_id = f'H{key:03d}'
    mid = PERIOD_START + timedelta(days=(PERIOD_END - PERIOD_START).days // 2)
    effective_to_first = mid - timedelta(days=1)

    # Versão antiga
    hosp_data.append({
        "dim_hospital_key": len(hosp_data) + 1,
        "hospital_id": hosp_id,
        "nome": fake.company(),
        "regiao": fake.state(),
        "tipo": random.choice(["Público", "Privado"]),
        "capacidade": random.randint(50, 500),
        "effective_from": PERIOD_START,
        "effective_to": effective_to_first,
        "is_current": False
    })
    hosp_data.append({
        'dim_hospital_key': key,
        'hospital_id': hosp_id,
        'nome': f'Hospital {fake.company()}',
        'regiao': random.choice(['Norte','Sul','Leste','Oeste']),
        'tipo': random.choice(['Public','Private']),
        'capacidade': random.randint(50,500),
        'effective_from': PERIOD_START,
        'effective_to': pd.NaT,
        'is_current': True
    })
    df_hosp = pd.DataFrame(hosp_data)
    df_hosp.to_csv('data/dim_hospital.csv', index=False)

    # DIM PACIENTE
    ''' 
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
);'''
doencas_internacao = [
    "Pneumonia",
    "Infarto Agudo do Miocárdio",
    "Acidente Vascular Cerebral (AVC)",
    "Insuficiência Cardíaca Congestiva",
    "Doença Pulmonar Obstrutiva Crônica (DPOC)",
    "Asma Grave",
    "Sepse/Infecção Generalizada",
    "Insuficiência Renal Aguda",
    "Cirrose Hepática e suas complicações",
    "Pancreatite Aguda",
    "Colecistite e Cálculos Biliares",
    "Apendicite Aguda",
    "Diverticulite",
    "Gastroenterite com desidratação grave",
    "Diabetes Mellitus com cetoacidose",
    "Fraturas e Traumas Ortopédicos",
    "Traumatismo Craniano",
    "Acidentes de Trânsito - Politrauma",
    "Queimaduras Graves",
    "Transtornos Mentais Agudos (crise psicótica, depressão grave)",
    "Câncer - Quimioterapia/Complicações",
    "COVID-19 e Síndromes Respiratórias Agudas Graves",
    "Meningite e Encefalite",
    "Osteomielite",
    "Arritmias Cardíacas",
    "Embolia Pulmonar",
    "Trombose Venosa Profunda",
    "Hemorragia Digestiva",
    "Doenças Autoimunes em crise",
    "Complicações no Parto e Pós-parto"
]
paciente_data = []
for key in range(1, N_PATIENTS + 1):
    paciente_id = f'P{key:05d}'
    dn = fake.date_of_birth(minimum_age=1, maximum_age=90)

    version_dates = [
        (PERIOD_START, PERIOD_START + timedelta(days=1000)),
        (PERIOD_START + timedelta(days=1001), None)
    ]
    sexo = random.choice(["M", "F"])
    for eff_from, eff_to in version_dates:
        paciente_data.append({
            "dim_paciente_key": len(paciente_data) + 1,
            "paciente_id": paciente_id,
            "nome": fake.name(),
            "data_nascimento": dn,
            "sexo": sexo,
            "comorbidades": random.choice(doencas_internacao),
            "effective_from": eff_from,
            "effective_to": eff_to,
            "is_current": eff_to is None
        })
df_paciente = pd.DataFrame(paciente_data)
df_paciente.to_csv('data/dim_paciente.csv', index=False)

# Tabela fato internacao
'''-- 5. Tabela fato de internação
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
);'''

fato_data = []
tempo_keys = df_dim_tempo['dim_tempo_key'].tolist()
paciente_key = df_paciente['dim_paciente_key'].tolist()
hospital_keys = df_hosp['dim_hospital_key'].tolist()
diagnostico_keys = df_diagnostico['dim_diagnostico_key'].tolist()

for _ in range(N_FATOS):
    adm_date = fake.date_time_between(start_date=PERIOD_START, end_date=PERIOD_END - timedelta(days=30))
    los = random.randint(1, 30)
    alta_date = adm_date + timedelta(days=los)
    adm_dim_key = df_dim_tempo.loc[df_dim_tempo['date'] == adm_date.date(), 'dim_tempo_key'].values[0]
    alta_dim_key = df_dim_tempo.loc[df_dim_tempo['date'] == alta_date.date(), 'dim_tempo_key'].values[0]

    fato_data.append({
        'id_internacao': f'IN{random.randint(100000,999999)}',
        'dim_paciente_key': random.choice(paciente_key),
        'dim_hospital_key': random.choice(hospital_keys),
        'dim_diagnostico_key': random.choice(diagnostico_keys),
        'dim_tempo_key_admissao': adm_dim_key,
        'dim_tempo_key_alta': alta_dim_key,
        'data_entrada': adm_date,
        'data_alta': alta_date,
        'dias_internado': los,
        'readmitido': random.choice([True, False]),
        'custo_total': round(random.uniform(1000, 20000), 2),
        'score_risco': round(random.uniform(0, 1), 2)
    })
df_fato = pd.DataFrame(fato_data)
df_fato.insert(0, 'fact_internacao_key', range(1, len(df_fato) + 1))
df_fato.to_csv('data/fact_internacao.csv', index=False)
print("Synthetic healthcare data generated and saved to CSV files.")

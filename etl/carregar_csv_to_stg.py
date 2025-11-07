import os
import psycopg2
import pandas as pd

conne = psycopg2.connect("dbname=healthcare_db user=admin password=admin host=localhost port=5432")
cursor = conne.cursor()
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "../data")

diagnostico = os.path.join(DATA_DIR, "dim_diagnostico.csv")
hospital = os.path.join(DATA_DIR, "dim_hospital.csv")
paciente = os.path.join(DATA_DIR,"dim_paciente.csv")
tempo = os.path.join(DATA_DIR,"dim_tempo.csv")
internacao = os.path.join(DATA_DIR,"fact_internacao.csv")

with open(diagnostico)as f:
    cursor.copy_expert("COPY stg.dim_diagnostico (dim_diagnostico_key, codigo_cid, descricao) FROM STDIN WITH CSV HEADER DELIMITER ','", f)


with open(hospital)as f:
    cursor.copy_expert("COPY stg.dim_hospital (dim_hospital_key,hospital_id,nome,regiao,tipo,capacidade,effective_from,effective_to,is_current) FROM STDIN WITH CSV HEADER DELIMITER ','", f)

with open(tempo)as f:
    cursor.copy_expert("COPY stg.dim_tempo (dim_tempo_key,date,day,month,year,quarter,is_weekend) FROM STDIN WITH CSV HEADER DELIMITER ','", f)

with open(paciente)as f:
    cursor.copy_expert("COPY stg.dim_paciente (dim_paciente_key,paciente_id,nome,data_nascimento,sexo,comorbidades,effective_from,effective_to,is_current) FROM STDIN WITH CSV HEADER DELIMITER ','", f)

with open(internacao)as f:
    cursor.copy_expert("COPY stg.fact_internacao (fact_internacao_key,id_internacao,dim_paciente_key,dim_hospital_key,dim_diagnostico_key,dim_tempo_key_admissao,dim_tempo_key_alta,data_entrada,data_alta,dias_internado,readmitido,custo_total,score_risco) FROM STDIN WITH CSV HEADER DELIMITER ','", f)

conne.commit()
cursor.close()
conne.close()

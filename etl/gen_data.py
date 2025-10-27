# gen_fake_data.py
import os
from faker import Faker
import random
import csv
from datetime import datetime, timedelta

fake = Faker()
n = 20000  # número de internações
codes_cid = ['I10','E11','J18','N39','K35','F32','I21']

file_path = '../data/hospital_internacoes.csv'

# Garantir que o diretório existe
directory = os.path.dirname(file_path)
if not os.path.exists(directory):
    os.makedirs(directory, exist_ok=True)
    print(f"Diretório criado: {directory}")
try:
    with open(file_path,'w',newline='',encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['id_internacao','paciente_id','paciente_nome','paciente_data_nascimento','paciente_sexo','comorbidades','hospital_id','hospital_nome','hospital_regiao','hospital_tipo','hospital_capacidade','codigo_cid','data_entrada','data_alta','custo_total'])
        for i in range(n):
            pid = f'P{random.randint(1000,999999)}'
            hospital_id = f'H{random.randint(1,200)}'
            adm = fake.date_time_between(start_date='-2y', end_date='now')
            los = random.randint(1,30)
            alta = adm + timedelta(days=los)
            cost = round(random.uniform(500,20000),2)
            comorbs = random.choice(['HTN;DM','DM;CKD','','COPD','HTN'])
            writer.writerow([f'IN{i+1}', pid, fake.name(), fake.date_of_birth(minimum_age=0, maximum_age=100).isoformat(), random.choice(['M','F']), comorbs, hospital_id, f'Hosp {hospital_id}', random.choice(['Norte','Sul','Leste','Oeste']), random.choice(['Public','Private']), random.randint(50,800), random.choice(codes_cid), adm.isoformat(), alta.isoformat(), cost])
    print(f"Arquivo de dados gerado em: {file_path}")
except Exception as e:
    print(f"Erro ao gerar o arquivo: {e}")
    print(f"Diretório atual: {os.getcwd()}")
    print(f"Diretório data existe: {os.path.exists(directory)}")
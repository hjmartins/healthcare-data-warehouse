import psycopg2
import pandas as pd
from psycopg2.extras import execute_values

conn = psycopg2.connect(
    "dbname=healthcare_db user=admin password=admin host=localhost port=5432"
)
cur = conn.cursor()

def load_csv_to_staging(csv_path, table_name, columns):
    df = pd.read_csv(csv_path)
    values = df[columns].values.tolist()
    
    insert_query = f"""
        INSERT INTO {table_name} ({", ".join(columns)})
        VALUES %s
    """
    
    execute_values(cur, insert_query, values)
    print(f"✅ Loaded {len(df)} rows into {table_name}")

# ---------------------------------------
# 1️⃣ Load staging tables
# ---------------------------------------
load_csv_to_staging(
    "data/stg_internacao.csv",
    "stg.stg_internacao",
    [
        "id_internacao", "paciente_id", "hospital_id", "codigo_cid",
        "data_entrada", "data_alta", "custo_total", "comorbidades",
        "paciente_nome", "paciente_data_nascimento", "paciente_sexo",
        "hospital_nome", "hospital_regiao", "hospital_tipo", "hospital_capacidade"
    ]
)

conn.commit()
print("✅ Staging loaded!")

# ---------------------------------------
# 2️⃣ Execute SQL transformations (SCD2 + facts)
# ---------------------------------------
sql_files = [
    "sql/merge_paciente.sql",
    "sql/merge_hospital.sql",
    "sql/load_dim_diagnostico.sql",
    "sql/load_dim_tempo.sql",
    "sql/load_fact_internacao.sql"
]

for sql_file in sql_files:
    with open(sql_file, "r") as f:
        cur.execute(f.read())
        print(f"✅ Executed: {sql_file}")

conn.commit()
cur.close()
conn.close()
print("\n🚀 ETL Finalizado com Sucesso!")

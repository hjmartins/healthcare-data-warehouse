# -------------------------------
# Configurações
# -------------------------------
$POSTGRES_CONTAINER = "dw_saude_postgres"
$POSTGRES_USER = "admin"
$POSTGRES_PASSWORD = "Strong_Password123!"
$POSTGRES_DB = "dw_saude"
$LOCAL_SQL_PATH = "C:\Users\hjmar\Documents\Vscode\healthcare-data-warehouse\sql"
$LOCAL_DATA_PATH = "C:\Users\hjmar\Documents\Vscode\healthcare-data-warehouse\data"

# -------------------------------
# 1️⃣ Subir Docker Postgres
# -------------------------------
Write-Host "Subindo container Docker do Postgres..."
docker-compose up -d

# Aguardar o container iniciar
Start-Sleep -Seconds 10

# -------------------------------
# 2️⃣ Gerar dados fictícios
# -------------------------------
Write-Host "Gerando dados fictícios..."
python etl/gen_data.py

# -------------------------------
# 3️⃣ Criar tabelas DW
# -------------------------------
Write-Host "Criando tabelas DW..."
docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -f "/sql/01_ddl_create_tables.sql"

# -------------------------------
# 4️⃣ Carregar CSVs para Staging
# -------------------------------
Write-Host "Carregando CSVs para Staging..."

$csv_files = @(
    @{table="stg_paciente"; file="pacientes.csv"},
    @{table="stg_hospital"; file="hospitais.csv"},
    @{table="stg_diagnostico"; file="diagnosticos.csv"},
    @{table="stg_internacao"; file="internacoes.csv"}
)

foreach ($item in $csv_files) {
    $table = $item.table
    $file = $item.file
    Write-Host "Carregando $file → $table"
    docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -c "\copy $table FROM '/data/$file' CSV HEADER;"
}

# -------------------------------
# 5️⃣ Executar ETL
# -------------------------------
Write-Host "Executando ETL..."
$etl_scripts = @(
    "merge_paciente.sql",
    "merge_hospital.sql",
    "load_dim_diagnostico.sql",
    "load_fact_internacao.sql"
)

foreach ($script in $etl_scripts) {
    Write-Host "Rodando $script"
    docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -f "/sql/$script"
}

Write-Host "🎉 Primeira execução completa! DW pronto para uso."

# =================
# DATABASE CONFIGURATION
# =================

$DB_NAME = "healthcare_db"
$DB_USER = "admin"
$DB_HOST = "localhost"
$DB_PORT = "5432"
$CONTAINER = "postgres_db"

# =================
# PATHS
# =================

$sql_create_stg = "../sql/create_stg_table.sql"
$project_root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$python_script = Join-Path $project_root "etl\carregar_csv_to_stg.py"

# Lista de scripts SQL a executar em ordem
$sql_scripts = @(
    "../sql/load_dim_diagnostico.sql",
    "../sql/load_dim_tempo.sql",
    "../sql/load_fact_internacao.sql",
    "../sql/load_merge_hospital.sql",
    "../sql/load_merge_paciente.sql"
)

# =================
# EXECUÇÃO sql e py
# =================

Write-Host "====================================" -ForegroundColor DarkYellow
Write-Host "Executando o script create_stg_table.sql"

#docker exec -i $CONTAINER psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f /$sql_create_stg

#if ($LASTEXITCODE -ne 0) {
#    Write-Host "Erro ao criar tabelas de staging!" -ForegroundColor Red
#    exit 1
#}

Write-Host "====================================" -ForegroundColor DarkYellow
Write-Host "Executando o script carregar_csv_to_stg.py"

python $python_script

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro ao carregar CSV para STG!" -ForegroundColor Red
    exit 1
}

# =================
#  rodar os SQLs parra dwh
# =================
foreach ($sql_file in $sql_scripts) {
    $filename = Split-Path $sql_file -Leaf
    Write-Host "====================================" -ForegroundColor DarkYellow
    Write-Host "Executando o script $filename"

    docker exec -i $CONTAINER psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f /$sql_file

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erro ao executar $filename!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "====================================" -ForegroundColor Green
Write-Host "ETL concluído com sucesso!"
Write-Host "====================================" -ForegroundColor Green

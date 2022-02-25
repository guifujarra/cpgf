!#/bin/bash

DIR=$(pwd)
YEAR=2021

echo 'Informe o banco de dados'
read DB

echo 'Informe o usuário do banco'
read USER

echo 'Informe a senha do usuário'
read -s PASSWORD

export PGPASSWORD=$PASSWORD

#Criar da tabela final
psql -U $USER -d $DB -c "drop table if exists public."final_cpgf";
CREATE TABLE public."final_cpgf" (
	"codigo_orgao_superior" integer NULL,
	"nome_orgao_superior" varchar(1024) NULL,
	"codigo_orgao" integer NULL,
	"nome_orgao" varchar(1024) NULL,
	"codigo_unidade_gestora" integer NULL,
	"nome_unidade_gestora" varchar(1024) NULL,
	"ano" integer NULL,
	"mes" integer NULL,
	"cpf_portador" varchar(1024) NULL,
	"nome_portador" varchar(1024) NULL,
	"documento_favorecido" varchar(1024) NULL,
	"nome_favorecido" varchar(1024) NULL,
	"transacao" varchar(1024) NULL,
	"data" date NULL,
	"valor" decimal(20,2) NULL
);" 




#Função reponsável por baixar, extrair, copiar e inserir
 loop_instruction () {
for MONTH in {01..12}
do

local FILE_NAME="${YEAR}${MONTH}_CPGF.csv"
local FILE="${DIR}/${FILE_NAME}"

local DATE="${YEAR}${MONTH}"
wget "https://www.portaltransparencia.gov.br/download-de-dados/cpgf/${DATE}"
unzip ${DATE}

#Importar dados do csv para o banco temp
psql -U $USER -d $DB -c "\COPY public."tmp_cpgf"
FROM $FILE
DELIMITER ';'
ENCODING 'latin1'
CSV HEADER;"
done

psql -U $USER -d $DB -c "insert into final_cpgf(codigo_orgao_superior, nome_orgao_superior, codigo_orgao, nome_orgao, codigo_unidade_gestora, 
	nome_unidade_gestora, ano, mes, cpf_portador, documento_favorecido, nome_favorecido, transacao, "data", valor)
	select
	codigo_orgao_superior,
	nome_orgao_superior,
	codigo_orgao,
	nome_orgao,
	codigo_unidade_gestora,
	nome_unidade_gestora,
	ano,
	mes,
	cpf_portador,
	documento_favorecido,
	nome_favorecido,
	transacao,
	TO_DATE("data", 'DD/MM/YYYY') as "data",
	cast(replace(valor, ',', '.' ) as decimal(20,2)) as valor
	from tmp_cpgf;"
}

 #Criar da tabela temporária
 create_tmp_table(){
psql -U $USER -d $DB -c "drop table if exists public."tmp_cpgf";
CREATE TABLE public."tmp_cpgf" (
	"codigo_orgao_superior" integer NULL,
	"nome_orgao_superior" varchar(1024) NULL,
	"codigo_orgao" integer NULL,
	"nome_orgao" varchar(1024) NULL,
	"codigo_unidade_gestora" integer NULL,
	"nome_unidade_gestora" varchar(1024) NULL,
	"ano" integer NULL,
	"mes" integer NULL,
	"cpf_portador" varchar(1024) NULL,
	"nome_portador" varchar(1024) NULL,
	"documento_favorecido" varchar(1024) NULL,
	"nome_favorecido" varchar(1024) NULL,
	"transacao" varchar(1024) NULL,
	"data" varchar(1024) NULL,
	"valor" varchar(1024) NULL
);"
}

#Execução das tarefas para os últimos 5 anos
for VAR in 1 2 3 4 5
 do
 create_tmp_table
 loop_instruction
 let "YEAR=YEAR-1"
 done
#Para limpar a tabela temporária
create_tmp_table

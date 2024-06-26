Refs DUMP e LOAD:

- https://www.netguru.com/blog/how-to-dump-and-restore-postgresql-database

# DUMP do banco PostgreSQL

```bash
 pg_dump database_name > database_name_20240405.sql
```
Ou também é possível fazer o [DUMP de todos databases](https://www.postgresql.org/docs/current/app-pg-dumpall.html) de uma unica vez:
```bash
pg_dumpall -U [seu_usuario] -h [seu_host] > backup_all_databases.sql
```

e restaurar todas :

```bash
psql -f backup_all_databases.sql postgres
```

Considerações:
- Para rodar mais rápido o processo, é possível utilizar multiplas threads (tomar cuidado para não sobrecarregar o servidor)
  - `pg_dump -j 8 nome_do_banco > dump_backup.sql`
  - A flag "-j" serve para especificar o numero de Threads a serem utilizadas paralelamente.
- É possível gerar o arquivo em outro formato, o formato personalizado do Postgres
  - `pg_dump -Fc nome_do_banco > dump_personalizado.backup`
  - Ao realizar o dump utilizando o formato personalizado (-Fc ou --format=custom), o PostgreSQL irá comprimir os dados e metadados, resultando em um arquivo menor e mais rápido para ser criado e restaurado.
- Existe uma flag que força o "clean" do banco antes de carregar, deve ser utilizada na hora de gerar o DUMP se quiser que isso aconteça
  - -c ou --clean
    - Emit SQL commands to DROP all the dumped databases, roles, and tablespaces before recreating them. This option is useful when the restore is to overwrite an existing cluster. If any of the objects do not exist in the destination cluster, ignorable error messages will be reported during restore, unless --if-exists is also specified.

Com o DUMP do banco feito, basta baixa-lo em outra máquina:

Para isso, é necessário ter a ferramenta SCP instalada e funcionando:

```bash
apt-get update && apt-get -y install openssh-client
```

Agora:

```bash
scp login@dumphost:path_to_dir_with/database_name_20240405.sql /home/database_name_20240405.sql
```

Também é possível compactar o arquivo para diminuir o tamanho do Download:

```bash
tar -czf dump.tar.gz /home/database_name_20240405.sql
ou
gzip -c dump_backup.sql > dump_backup.sql.gz
```

Se o backup for feito no GCP, é sugerível fazer o upload ao Cloud Storage e o Download via ferramenta GSUTIL para obter a maior taxa de transferência possível:
- Aumentar o número de threads: 
  - Número de threads utilizadas pelo GSUTIL durante o download.
  - Isso pode ser feito definindo a variável de ambiente GSUtil:parallel_thread_count.
  - `export GSUtil:parallel_thread_count=8`
- Utilizar o GSUTIL RSYNC ao invés do CP
  - O comando gsutil rsync é otimizado para sincronizar diretórios entre o GCS e o sistema local.
  - Embora seja mais comumente usado para sincronizar diretórios inteiros, ele também pode ser eficaz para download de um único arquivo, especialmente se você precisar realizar várias tentativas de download.
  - O uso da opção -m torna o rsync mais rápido, pois executa operações de forma paralela.
  - `gsutil -m rsync -r gs://seu_bucket/seu_arquivo /caminho/local`
- Fazer o download paralelo de menores partes do arquivo:
  - Utilize a opção -o ou --parallel-composite-download
  - Esta opção permite que o GSUTIL faça download de objetos de forma paralela, dividindo-os em partes menores e baixando várias partes simultaneamente.
  - Isso pode aumentar significativamente a velocidade de download, especialmente para objetos grandes.
  - Substitua 150M pelo tamanho do arquivo em que deseja habilitar o download paralelo.
  - `gsutil -o GSUtil:parallel_composite_upload_threshold=150M cp -r gs://seu_bucket/seu_arquivo /caminho/local`

Após a transferência, basta descompactar novamente:

```bash
tar -xzf dump.tar.gz
```

Como neste exemplo estamos utilizando do Docker, é necessário fazer da seguinte forma, através do terminal (fora dos dois containers):

```bash
docker cp pg-master:/home/dump.sql /home/tone/Downloads &&
docker cp /home/tone/Downloads/dump.sql pg-slave:/home/dump.sql
```

Neste caso estamos copiando para o localhost e dps para o outro container

# LOAD do banco PostgreSQL

Se for carregar um DUMP de uma base já existente, é necessário fazer o DROP dela primeiro:

**OBS: Ao realizar essa operação, todos dados serão perdidos.**

```bash
psql -U postgres -c 'DROP DATABASE database_name;'
```

1. Crie o banco de dados a ser carregado:

```bash
psql -U postgres -c 'CREATE DATABASE database_name WITH OWNER your_user_name;
```

"
2. Carregue os dados do banco:

```bash
psql -U postgres database_name < database_name_20240405.sql
```

# Replicação - Install PGLOGICAL

- REF: https://medium.com/@Navmed/setting-up-replication-in-postgresql-with-pglogical-8212e77ebc1b

Entre no container

- `docker exec -it id-container bash`

Atualize o cache do sistema:

- `apt update && apt upgrade -y`
- OBS:
  - Se no sistema do Postgres mais antigo der problema com os repos, tem que corrigir:
    - Verificar versão do sistema
      - `cat etc/os-release`
    - No meu caso é um Debian 9 com os pacotes inválidos (não são mais mantidos)
      - Tive que adicionar via ECHO por que não tem VI nem NANO nessa imagem
      - ```bash
        echo "deb http://deb.debian.org/debian buster main" > /etc/apt/sources.list
        echo "deb-src http://deb.debian.org/debian buster main" >> /etc/apt/sources.list
        echo "deb http://security.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list
        echo "deb-src http://security.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list
        echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" > /etc/apt/sources.list.d/pgdg.list
        ```

Instale o curl e o VIM para editar arquivos (será necessário)

- `apt install vim curl -y`

# Primeiro passo de todos:

Validar se um banco de dados te acesso ao outro.
Busque o IP de ambos e faça o seguinte processo:

- `psql -h 172.26.0.2 -U postgres test_db`

Como obter o IP da máquina docker:

- `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' pg_slave`

No caso, do servidor MASTER conecte no SLAVE
E do SLAVE conecte no MASTER, para garantir que a configuração de rede esteja correta.

Instale a versao do [pglogical conforme a documentação](https://github.com/2ndQuadrant/pglogical?tab=readme-ov-file#installation)

- No master
  - `curl https://techsupport.enterprisedb.com/api/repository/dl/default/release/deb | bash`
  - `apt install postgresql-10-pglogical`
- No slave
  - `apt install postgresql-15-pglogical`

# Configurar banco master para permitir replicação lógica

Encontre o arquivo de configuração do postgres utilizando

- `find / -name postgresql.conf`

No caso meu caminho é `/var/lib/postgresql/data/postgresql.conf`

Edite o arquivo com o VIM para inserir as configurações necessárias como definido na [documentação](https://github.com/2ndQuadrant/pglogical?tab=readme-ov-file#usage)

```bash
wal_level = 'logical' # Config para habilitar a replicação lógica - Assim o postgres registra informacoes adicionais no log de transações para suportar a replicação lógica. WAL - Write-Ahead Logging
max_worker_processes = 10   # one per database needed on provider node
                            # one per node needed on subscriber node
                            # Determina o número máximo de processos 'workers' que o PostgreSQL pode usar.
                            # No contexto da replicação lógica, é recomendável aumentar este valor para permitir que o PostgreSQL aloque trabalhadores suficientes para suportar a replicação.
max_replication_slots = 10  # one per node needed on provider node
							# Define o número máximo de "slots de replicação" que o servidor pode alocar.
							# Um slot de replicação é uma estrutura de dados que mantém o estado de uma conexão de replicação.
							# Para a replicação lógica, onde há um nó fornecedor e vários nós assinantes, cada nó assinante requer um slot de replicação no nó fornecedor.
							# Portanto, é necessário configurar este valor para um número que seja pelo menos igual ao número de nós assinantes mais qualquer outro uso de slots de replicação que possa estar ocorrendo.
max_wal_senders = 10        # one per node needed on provider node
							# Esta configuração determina o número máximo de conexões de envio WAL (Write-Ahead Logging) permitidas. Em uma configuração de replicação lógica, cada nó assinante e outros servidores que enviam registros de WAL (como servidores de backup ou servidores de extração de WAL) consomem uma conexão de envio WAL no nó fornecedor.
							# Portanto, o valor de `max_wal_senders` deve ser configurado para acomodar todas essas conexões.
shared_preload_libraries = 'pglogical' # Carrega bibliotecas dinâmicas compartilhadas durante a inicialização do servidor.
							# Para replicação lógica, a biblioteca `pglogical` é necessária para fornecer a funcionalidade de replicação lógica.
```

Código puro pronto para colar e salvar:

```bash
wal_level = 'logical'
max_worker_processes = 10
max_replication_slots = 10
max_wal_senders = 10
shared_preload_libraries = 'pglogical'
```

As configurações já existem no arquivo normalmente, portanto basta descomentar e ajustar os valores conforme o nocessário.

Utilize `/wal_level` para encontrar cada um dos parametros, aperte enter e I para inserir no VIM, edite os valores para o correto e por fim, ESC + :wq para salvar as alterações e sair do VIM

Agora configure o arquivo `pg_hba.conf` na mesma pasta em ambos servidores (master e escravo):

On instance Master:

```
host all all 2.2.2.2/32 md5 # slave machine’s IP
host all all 1.1.1.1/32 md5 # this machine’s IP
host all all 9.9.9.9/32 md5 # your dev machine’s IP
```

On instance Slave:

```
host all all 1.1.1.1/32 md5 # master machine’s IP
host all all 2.2.2.2/32 md5 # this machine’s IP
host all all 9.9.9.9/32 md5 # your dev machine’s IP
```

# Criar usuário com acesso em ambas instancias

```bash
psql -U postgres
```

```bash
CREATE USER replication_user REPLICATION LOGIN PASSWORD 'senha123';
```

<!-- CREATE USER replication WITH superuser;

ALTER USER replication WITH PASSWORD 'pass'; -->

## Dar permissão ao usuário em todas tabelas

```bash
GRANT SELECT ON ALL TABLES IN SCHEMA public TO replication_user;
```

```bash
GRANT USAGE ON SCHEMA pglogical TO replication_user;
GRANT SELECT ON ALL TABLES IN SCHEMA pglogical TO replication_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pglogical TO replication_user;
```
 -- Substitua 'replication_user' pelo nome do seu usuário de replicação

Substitua 'replication_user' pelo nome do seu usuário de replicação

# Instalar plugins em ambas instancias

dentro do psql console (psql -U postgres)

Conecte no banco a ser replicado - É necessários que os bancos existam. Se não existir, execute o LOAD do DUMP do outro banco.

- `\c test_db`

Instale as extensoes:

- `CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;`
- `CREATE EXTENSION pglogical;`

Será necessário reiniciar o serviço do Postgres para aplicar as alterações feitas:

## Agora é necessário reiniciar o processo do postgres

```bash
sudo -u postgres /etc/init.d/postgresql restart
```

ou

- `service postgresql restart`

- Para validar a criação, utilize o `\dx` que lista as extensões instaladas
- Deve aparecer algo semelhante a:
  - ```bash
      Name    | Version |   Schema   |          Description
    -----------+---------+------------+--------------------------------
    pglogical | 2.4.4   | pglogical  | PostgreSQL Logical Replication
    plpgsql   | 1.0     | pg_catalog | PL/pgSQL procedural language
    (2 rows)
    ```

# Configurar réplica

## 1. Crie o Nó PROVIDER - MASTER

```postgresql
SELECT pglogical.create_node(
    node_name := 'provider',
    dsn := 'host=providerhost port=5432 dbname=db'
);
```

Corrija os valores de host, port e dbname.
No meu caso, estou utilizando o Docker, meu providerhost vai ser o nome do Container (pg_master), a porta está correta e o banco que criamos no seeder se chama `test_db`

Deve retornar um "create_node".

## 2. Adicione as tabelas a lista de replicação - MASTER

Neste caso, iremos adicionar todas as tabelas dentro do schema "public" a lista de replicação chamada "default":

```postgresql
  SELECT pglogical.replication_set_add_all_tables('default', ARRAY['public']);
```

Para personalizar o SET (lista) de replicação [veja mais em Replication-Sets](https://github.com/2ndQuadrant/pglogical?tab=readme-ov-file#replication-sets)

É recomendável criar todos os sets de replicação antes de configurar o subscriber (db que var receber a réplica)

Agora já temos nosso banco MASTER configurado e pronto para receber um SUBSCRIBER.
Caso precise de mais de um banco SLAVE, verifique a documentação. É necessário implementar mais nodos de réplica.

## 3. Configure o Subscriber no banco SLAVE

### Criando NODE de subscriber

Para isso, é necessário que os servidores dos bancos de dados tenham a capacidade de se comunicar, ou seja, estejam em redes com acesso bidirecional.

```postgresql
SELECT pglogical.create_node(
    node_name := 'subscriber1',
    dsn := 'host=thishost port=5432 dbname=db'
);
```

Corrija os valores de host, port e dbname.
No meu caso, estou utilizando o Docker, meu providerhost vai ser o nome do Container do SLAVE (pg_slave), a porta do Slave (5431) e o banco que criamos (que deve ser o mesmo em ambos) "test_db"

### Iniciando sincronização - NO SLAVE

Por fim, vamos dar inicio ao processo de replicação, criando o subscriber de fato (ligando o banco Slave ao banco Master) e iniciando a sincronização:

#### Criando subscrição

```postgresql
SELECT pglogical.create_subscription(
    subscription_name := 'subscription1',
    provider_dsn := 'host=providerhost port=5432 dbname=db password=senha'
);
```

Aqui os dado a substituir devem ser os dados do HOST, ou seja:

- Host: pg_master
- port: 5432
- dbname: test_db
- password: senha do banco

#### Iniciando sincronização

SELECT pglogical.wait_for_subscription_sync_complete('subscription1');

![alt text](image.png)
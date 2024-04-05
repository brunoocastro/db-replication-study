Refs:

- DUMP e LOAD do banco - https://www.mongodb.com/docs/manual/tutorial/backup-and-restore-tools/

# DUMP do Banco MongoDB

No servidor que possui o mongo instalado, por padrão, existe também a ferramenta [mongodump](https://www.mongodb.com/docs/database-tools/mongodump/#mongodb-binary-bin.mongodump), responsável por realizar o DUMP de um banco MongoDB.

Para realizar o DUMP, é necessário ter um usuário com permissão para realização do DUMP.

Acesse a máquina via SSH e execute o comando:

```bash
mongodump --uri="mongodb://admin:adminpassword@172.18.0.2:27017/database" --out="/home/backup" --authenticationDatabase admin
```

Substituindo os valores de login e senha (admin:adminpassword), o IP e a Porta do servidor e o banco a ser realizado o DUMP.
Também é necessário informar qual o banco de autenticação e o local onde o dump vai ser salvo.

Agora basta fazer o download da pasta criada no servidor onde vai ser realizado o LOAD.
Ou, é possível fazer a recuperação remota do banco.

Compacte a pasta para facilitar a transferência de um servidor para o outro:

```bash
tar -czf dump.tar.gz /home/backup/database
```

# LOAD do Banco MongoDB

No servidor que possui o mongo instalado, por padrão, existe também a ferramenta [mongorestore](https://www.mongodb.com/docs/database-tools/mongorestore/#mongodb-binary-bin.mongorestore), responsável por realizar o LOAD de um banco MongoDB.

## Remoto:

É possível realizar o LOAD do Banco de forma remota, sendo feita a partir da própria máquina que fez o DUMP do banco. Porém, fica-se dependente da conexão de internet. Dessa forma, existe um risco de interromper o RESTORE durante o processo.

Portanto, sugiro fazer de forma local na máquina, transferindo o conteúdo do Backup.

Comando para execução remota:

```bash
mongorestore \
   --host=mongodb1.example.net \
   --port=3017 \
   --username=admin \
   --password=adminpassword \
   --authenticationDatabase=admin \
   /home/backup1
```

## Local:

Nesse caso, é necessário fazer o Download da pasta onde foi feito o DUMP do banco.

### Download do DUMP

Para isso, é necessário ter a ferramenta SCP instalada e funcionando:

```bash
apt-get update && apt-get -y install openssh-client
```

[Copiar backup de outro servidor para o servidor onde será feito o restore](https://www.linode.com/docs/guides/how-to-use-scp/#how-to-transfer-files-from-a-remote-system-to-a-local-system-using-scp):

```bash
 scp admin@172.18.0.2:/home/backup/dump.tar.gz /home/dump
```

Como neste exemplo estamos utilizando do Docker, é necessário fazer da seguinte forma, através do terminal (fora dos dois containers):

```bash
docker cp mongodb-master:/home/backup/dump.tar.gz /home/tone/Downloads &&
docker cp /home/tone/Downloads/dump.tar.gz mongodb-slave:/home/dump.tar.gz
```

Neste caso estamos copiando para o localhost e dps para o outro container

Agora basta descompactar o arquivo para termos a pasta DUMP com o conteúdo do restore (dentro do container Slave):

```bash
cd /home &&
tar -xzf dump.tar.gz
```

### Processo de Restore

O comando para execução local é o mesmo da remota, porém passando os dados da própria máquina e o local onde foi feito o Download do DUMP do banco:

```bash
mongorestore --uri <connection string> <path to the backup>
```

Caso precise passar mais detalhes, utilize o exemplo dado no Remoto porém com os dados dá maquina local.

Comando funcional:

```bash
mongorestore --host=localhost --port=27017 --username=admin --authenticationDatabase=admin /home/backups
```
A pasta indicada no final do comando não deve ser a pasta gerada pelo DUMP, e sim uma pasta anterior. Por exemplo, se o DUMP foi de um banco chamado "example", foi gerada uma pasta "example" que está dentro da /home/backups. Assim a ferramenta reconhece e realiza o LOAD.

Ainda existem duas flags opcionais que podem ser úteis:
- "--objcheck": Option to check the integrity of objects while inserting them into the database
- "--drop": Option to drop each collection from the database before restoring from backups.

# Réplica do MongoDB

## Preparando máquinas para replicação

Acesse ambas, atualize o cache e instale o VIM para poder editar as configurações:

```bash
apt update && apt install vim -y
```

Encontre o arquivo de configuração do Mongo: 
```bash
find / -name mongod.conf
```

Adicione as configurações: 

No master, você deve bindar o IP do slave, e no slave o do Master, para que eles aceitem conexões entre si

```bash
replication:
   replSetName: "rs0"
net:
   bindIp: localhost,<hostname(s)|ip address(es)>
```

## Configure a réplica

Acesse o mongosh do master:

```bash
	mongosh "mongodb://$(MONGO_MASTER_IP):27017" --username admin --authenticationDatabase admin --password adminpassword
```

Rode este comando **SOMENTE** no Master

```bash
rs.initiate( {
   _id : "rs0",
   members: [
      { _id: 0, host: "ip-master:27017" },
      { _id: 1, host: "ip-slave:27017" },
   ]
})
```

No meu caso:

```bash
rs.initiate( {
   _id : "rs0",
   members: [
      { _id: 0, host: "172.23.0.2:27017" },
      { _id: 1, host: "172.23.0.3:27017" },
   ]
})
```
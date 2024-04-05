# Mongo - NOSQL
mongo:
	docker compose --file docker-compose-mongo.yml up -d
mongo-down:
	docker compose --file docker-compose-mongo.yml down

MONGO_MASTER_IP := $(shell docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mongodb-master)
MONGO_SLAVE_IP := $(shell docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mongodb-slave)

mongo-master-ip:
	@echo "$(MONGO_MASTER_IP)"
mongo-slave-ip:
	@echo "$(MONGO_SLAVE_IP)"
	
db-mongo-master:
	mongosh "mongodb://$(MONGO_MASTER_IP):27017" --username admin --authenticationDatabase admin --password adminpassword
db-mongo-slave:
	mongosh "mongodb://$(MONGO_SLAVE_IP):27017" --username admin --authenticationDatabase admin --password adminpassword


enter-mongo-master:
	docker exec -it mongodb-master bash
enter-mongo-slave:
	docker exec -it mongodb-slave bash

# ---
# Postgres - SQL
# PostgreSQL
pg:
	docker compose --file docker-compose-postgres.yml up -d
pg-down:
	docker compose --file docker-compose-postgres.yml down

PG_MASTER_IP := $(shell docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' pg-master)
PG_SLAVE_IP := $(shell docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' pg-slave)

pg-master-ip:
	@echo "$(PG_MASTER_IP)"
pg-slave-ip:
	@echo "$(PG_SLAVE_IP)"

db-pg-master:
	psql -h $(PG_MASTER_IP) -U postgres
db-pg-slave:
	psql -h $(PG_SLAVE_IP) -U postgres

enter-pg-master:
	docker exec -it pg-master bash
enter-pg-slave:
	docker exec -it pg-slave bash

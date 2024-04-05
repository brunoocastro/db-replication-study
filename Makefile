mongo:
	docker compose --file docker-compose-mongo.yml up -d

access-mongo-master:
	mongosh "mongodb://172.18.0.2:27017" --username admin --authenticationDatabase admin --password adminpassword

access-mongo-slave:
	mongosh "mongodb://172.18.0.3:27017" --username admin --authenticationDatabase admin --password adminpassword

mongo-slave-ip:
	docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mongodb-slave
	
mongo-master-ip:
	docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mongodb-master

enter-mongo-master:
	docker exec -it mongodb-master bash
enter-mongo-slave:
	docker exec -it mongodb-slave bash

postgres:
	docker compose --file docker-compose.yml up -d

pg-slave-ip:
	docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' pg_slave
	
pg-master-ip:
	docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' pg_master


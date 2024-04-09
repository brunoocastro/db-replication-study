import sys
from pymongo import MongoClient
from faker import Faker
import random

# Conectar ao servidor MongoDB
username = "admin"
password = "adminpassword"
masterIP = "172.27.0.2"
slaveIP = "172.27.0.3"
mongoPort = "27017"

# Obter argumentos de linha de comando
if len(sys.argv) > 1 and sys.argv[1] == "slave":
    mongo_ip = slaveIP
else:
    mongo_ip = masterIP

client = MongoClient(mongo_ip, 27017, username=username, password=password)

db = client["test_db"]
collection = db["users"]

# Instanciar Faker
fake = Faker()

# Lista de gêneros
genders = ["Male", "Female"]

# Lista de profissões
professions = [
    "Engineer",
    "Doctor",
    "Lawyer",
    "Teacher",
    "Artist",
    "Nurse",
    "Pilot",
    "Chef",
    "Musician",
    "Writer",
]

# Lista de nacionalidades
nationalities = [
    "American",
    "British",
    "Canadian",
    "Australian",
    "French",
    "German",
    "Spanish",
    "Italian",
    "Japanese",
    "Chinese",
]

# Lista de cidades
cities = [
    "New York",
    "Los Angeles",
    "London",
    "Paris",
    "Tokyo",
    "Sydney",
    "Berlin",
    "Rome",
    "Toronto",
    "Madrid",
]

# Inserir usuários falsos
for _ in range(10):
    user = {
        "name": fake.name(),
        "age": random.randint(18, 70),
        "gender": random.choice(genders),
        "profession": random.choice(professions),
        "nationality": random.choice(nationalities),
        "city": random.choice(cities),
    }
    collection.insert_one(user)

print("Usuários inseridos com sucesso!")

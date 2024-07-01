import psycopg2

db_connection = psycopg2.connect(
    database="new_table",
    host="172.25.0.3",
    user="postgres",
    password="senha123",
    port="5432",
)

# Criando um cursor
cursor = db_connection.cursor()

# Criando uma tabela
cursor.execute(
    """
    CREATE TABLE IF NOT EXISTS person (
        id SERIAL PRIMARY KEY,
        nome VARCHAR(100),
        idade INTEGER
    )
"""
)

# Adicionando valores fictícios
person = [
    ("Alice", 25),
    ("Bob", 30),
    ("Carol", 35),
    ("David", 40),
    ("Eve", 45),
    ("Frank", 50),
]

for usuario in person:
    cursor.execute("INSERT INTO person (nome, idade) VALUES (%s, %s)", usuario)
print(f"[SEEDER] Inserindo {len(person)} no banco")

# Commit das mudanças
db_connection.commit()
print("[SEEDER] Dados inseridos com sucesso.")

# Fechando cursor e conexão
cursor.close()
db_connection.close()

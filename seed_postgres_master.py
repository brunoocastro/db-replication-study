import psycopg2

db_connection = psycopg2.connect(
    database="test_db",
    host="172.22.0.3",
    user="postgres",
    password="senha123",
    port="5432",
)

# Criando um cursor
cursor = db_connection.cursor()

# Criando uma tabela
cursor.execute(
    """
    CREATE TABLE IF NOT EXISTS usuarios (
        id SERIAL PRIMARY KEY,
        nome VARCHAR(100),
        idade INTEGER
    )
"""
)

# Adicionando valores fictícios
usuarios = [
    ("Alice", 25),
    ("Bob", 30),
    ("Carol", 35),
    ("David", 40),
    ("Eve", 45),
    ("Frank", 50),
]

for usuario in usuarios:
    cursor.execute("INSERT INTO usuarios (nome, idade) VALUES (%s, %s)", usuario)
print(f"[SEEDER] Inserindo {len(usuarios)} no banco")

# Commit das mudanças
db_connection.commit()
print("[SEEDER] Dados inseridos com sucesso.")

# Fechando cursor e conexão
cursor.close()
db_connection.close()

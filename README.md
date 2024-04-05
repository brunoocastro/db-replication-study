# Run containers from compose

```bash
docker compose up -d
```

# Seed the MASTER database with our python script

## Install requirements

```bash
python3 -m venv venv &&
source venv/bin/activate &&
pip install -r requirements.txt
```

## Run the seeder

```bash
python3 seed_master.py
```

# Configure replication 

Access our [step-by-step tutorial](replica-steps.md)
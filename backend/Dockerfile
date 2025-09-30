# Imagen base liviana de Python
FROM python:3.11-slim

WORKDIR /app

# Evita bytecode y buffers
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Dependencias del sistema (opcional pero ayuda con compilaciones y healthchecks)
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# Instalar dependencias Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar app
COPY app.py /app/app.py

# Puerto interno
EXPOSE 8000

# Comando de arranque: uvicorn en 0.0.0.0:8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]

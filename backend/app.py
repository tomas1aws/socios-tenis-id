from fastapi import FastAPI
from pydantic import BaseModel
import uuid
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI(title="Socios Tenis ID")

# Simulación de DB en memoria
db = {}

class Socio(BaseModel):
    name: str
    email: str
    phone: str

@app.post("/register")
def register_socio(socio: Socio):
    socio_id = str(uuid.uuid4())[:8]
    db[socio_id] = socio.dict()
    return {"message": "Socio registrado", "socio_id": socio_id}

@app.get("/socios")
def list_socios():
    return db

@app.get("/socios/{socio_id}")
def get_socio(socio_id: str):
    if socio_id in db:
        return db[socio_id]
    return {"error": "Socio no encontrado"}


# 👉 Montar métricas correctamente
instrumentator = Instrumentator()
instrumentator.instrument(app)
instrumentator.expose(app)

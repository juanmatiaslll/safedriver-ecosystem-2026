from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import jwt, JWTError
from pydantic import BaseModel

from . import models, schemas, database, auth

models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(title="SafeDriver API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security_scheme = HTTPBearer()
# ── Modelo de login (JSON, compatible con Flutter) ──────────────
class LoginRequest(BaseModel):
    username: str
    password: str

# ── Dependencia JWT ─────────────────────────────────────────────
def get_current_user(token: HTTPAuthorizationCredentials = Depends(security_scheme),
                     db: Session = Depends(database.get_db)):
    try:
        # 👇 Aquí agregamos .credentials para leer el texto del token
        payload  = jwt.decode(token.credentials, auth.SECRET_KEY, algorithms=[auth.ALGORITHM])
        username = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=401, detail="Token inválido")
    except JWTError:
        raise HTTPException(status_code=401, detail="Token inválido o expirado")
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=401, detail="Usuario no encontrado")
    return user

# ── 1. Registro ─────────────────────────────────────────────────
@app.post("/auth/register", tags=["Autenticación"])
def register(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    if db.query(models.User).filter(models.User.username == user.username).first():
        raise HTTPException(status_code=400, detail="Usuario ya registrado")
    nuevo = models.User(username=user.username,
                        hashed_password=auth.get_password_hash(user.password))
    db.add(nuevo); db.commit()
    return {"msg": "Usuario creado exitosamente"}

# ── 2. Login ────────────────────────────────────────────────────
@app.post("/auth/login", response_model=schemas.Token, tags=["Autenticación"])
def login(data: LoginRequest, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == data.username).first()
    if not user or not auth.verify_password(data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")
    token = auth.create_access_token({"sub": user.username})
    return {"access_token": token, "token_type": "bearer"}

# ── 3. Crear conductor ──────────────────────────────────────────
@app.post("/drivers", status_code=201, tags=["Conductores"])
def create_driver(driver: schemas.DriverCreate,
                  db: Session = Depends(database.get_db),
                  _: models.User = Depends(get_current_user)):
    if db.query(models.Driver).filter(models.Driver.dni == driver.dni).first():
        raise HTTPException(status_code=400, detail="DNI ya registrado")
    nuevo = models.Driver(name=driver.name, dni=driver.dni)
    db.add(nuevo); db.commit(); db.refresh(nuevo)
    return {"msg": "Conductor creado", "driver_id": nuevo.id}

# ── 4. Listar conductores ───────────────────────────────────────
@app.get("/drivers", response_model=list[schemas.DriverResponse], tags=["Conductores"])
def get_drivers(db: Session = Depends(database.get_db)):
    return db.query(models.Driver).all()

# ── 5. Crear alerta (requiere JWT) ──────────────────────────────
@app.post("/alerts", response_model=schemas.AlertResponse,
          status_code=201, tags=["Alertas"])
def create_alert(alert: schemas.AlertCreate,
                 db: Session = Depends(database.get_db),
                 _: models.User = Depends(get_current_user)):
    driver = db.query(models.Driver).filter(models.Driver.id == alert.driver_id).first()
    if not driver:
        raise HTTPException(status_code=404, detail="Conductor no existe")
    nueva = models.Alert(**alert.model_dump())
    db.add(nueva)
    driver.status = "EN_ALERTA"
    db.commit(); db.refresh(nueva)
    return nueva

# ── 6. Ver alertas activas (requiere JWT) ───────────────────────
@app.get("/alerts", response_model=list[schemas.AlertResponse], tags=["Alertas"])
def get_alerts(db: Session = Depends(database.get_db),
               _: models.User = Depends(get_current_user)):
    return db.query(models.Alert).filter(models.Alert.is_active == True).all()

# ── 7. Estado del conductor (para Godot) ────────────────────────
@app.get("/drivers/{id}/status", tags=["Conductores"])
def driver_status(id: int, db: Session = Depends(database.get_db)):
    driver = db.query(models.Driver).filter(models.Driver.id == id).first()
    if not driver:
        raise HTTPException(status_code=404, detail="Conductor no encontrado")
    return {"driver_id": driver.id, "name": driver.name, "status": driver.status}
from fastapi import FastAPI, Depends, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import jwt, JWTError
from pydantic import BaseModel
from datetime import datetime, timezone, timedelta

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
class LoginRequest(BaseModel):
    username: str
    password: str

def get_current_user(token: HTTPAuthorizationCredentials = Depends(security_scheme),
                     db: Session = Depends(database.get_db)):
    try:
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

def get_current_admin(current_user: models.User = Depends(get_current_user)):
    if current_user.role != "ADMIN":
        raise HTTPException(status_code=403, detail="Operation not permitted for this role")
    return current_user

# ── 1. Registro ─────────────────────────────────────────────────
@app.post("/auth/register", tags=["Autenticación"])
def register(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    if db.query(models.User).filter(models.User.username == user.username).first():
        raise HTTPException(status_code=400, detail="Usuario ya registrado")
    nuevo = models.User(username=user.username,
                        hashed_password=auth.get_password_hash(user.password),
                        role=user.role,
                        driver_id=user.driver_id)
    db.add(nuevo); db.commit()
    return {"msg": "Usuario creado exitosamente"}

# ── 2. Login ────────────────────────────────────────────────────
@app.post("/auth/login", response_model=schemas.Token, tags=["Autenticación"])
def login(data: LoginRequest, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.username == data.username).first()
    if not user or not auth.verify_password(data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")
    token = auth.create_access_token({
        "sub": user.username,
        "rol": user.role,
        "driver_id": user.driver_id,
    })
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

# ── 5. Resumen de flota (solo ADMIN) ────────────────────────────
@app.get("/drivers/summary", response_model=list[schemas.DriverSummaryResponse], tags=["Conductores"])
def get_drivers_summary(db: Session = Depends(database.get_db),
                        _: models.User = Depends(get_current_admin)):
    drivers = db.query(models.Driver).all()
    result = []
    for driver in drivers:
        active_count = db.query(models.Alert).filter(
            models.Alert.driver_id == driver.id,
            models.Alert.is_active == True
        ).count()
        last = db.query(models.TelemetryLog).filter(
            models.TelemetryLog.driver_id == driver.id
        ).order_by(models.TelemetryLog.timestamp.desc()).first()
        result.append({
            "id": driver.id,
            "name": driver.name,
            "status": driver.status,
            "active_alerts_count": active_count,
            "last_telemetry": {
                "fatigue_level": last.fatigue_level,
                "heart_rate": last.heart_rate,
                "speed": last.speed,
                "timestamp": last.timestamp.isoformat() if last.timestamp else None,
            } if last else None,
        })
    return result

# ── 6. Telemetría IoT ──────────────────────────────────────────
@app.post("/telemetry", response_model=schemas.TelemetryPostReturn, tags=["IoT"])
def post_telemetry(data: schemas.TelemetryCreate,
                   db: Session = Depends(database.get_db),
                   _: models.User = Depends(get_current_user)):
    driver = db.query(models.Driver).filter(models.Driver.id == data.driver_id).first()
    if not driver:
        raise HTTPException(status_code=404, detail="Conductor no existe")
    log = models.TelemetryLog(
        driver_id=data.driver_id,
        fatigue_level=data.fatigue_level,
        heart_rate=data.heart_rate,
        speed=data.speed,
    )
    db.add(log)
    alert_created = False
    alert_id = None
    alert_type = None
    severity = None
    triggered_type = None
    if data.fatigue_level > 80:
        triggered_type = "FATIGA"
        severity = "ALTA"
    elif data.fatigue_level > 60:
        triggered_type = "FATIGA"
        severity = "MEDIA"
    if data.speed > 120:
        triggered_type = "VELOCIDAD"
        severity = "ALTA"
    elif data.speed > 100 and triggered_type is None:
        triggered_type = "VELOCIDAD"
        severity = "MEDIA"
    if triggered_type:
        alert = models.Alert(
            driver_id=data.driver_id,
            alert_type=triggered_type,
            severity=severity,
            created_at=datetime.now(timezone.utc),
        )
        db.add(alert)
        driver.status = "EN_ALERTA"
        db.flush()
        alert_created = True
        alert_id = alert.id
        alert_type = alert.alert_type
        severity = alert.severity
    db.commit()
    return {
        "alert_created": alert_created,
        "alert_id": alert_id,
        "alert_type": alert_type,
        "severity": severity,
        "driver_status": driver.status,
    }

# ── 7. Crear alerta (requiere JWT) ──────────────────────────────
@app.post("/alerts", response_model=schemas.AlertResponse,
          status_code=201, tags=["Alertas"])
def create_alert(alert: schemas.AlertCreate,
                 db: Session = Depends(database.get_db),
                 _: models.User = Depends(get_current_user)):
    driver = db.query(models.Driver).filter(models.Driver.id == alert.driver_id).first()
    if not driver:
        raise HTTPException(status_code=404, detail="Conductor no existe")
    nueva = models.Alert(**alert.model_dump(), created_at=datetime.now(timezone.utc))
    db.add(nueva)
    driver.status = "EN_ALERTA"
    db.commit(); db.refresh(nueva)
    return {
        "id": nueva.id,
        "driver_id": nueva.driver_id,
        "alert_type": nueva.alert_type,
        "severity": nueva.severity,
        "is_active": nueva.is_active,
        "created_at": nueva.created_at.isoformat() if nueva.created_at else None,
        "driver_name": driver.name,
    }

# ── 8. Ver alertas activas (requiere JWT) ───────────────────────
@app.get("/alerts", response_model=list[schemas.AlertResponse], tags=["Alertas"])
def get_alerts(date: str | None = Query(None),
               db: Session = Depends(database.get_db),
               _: models.User = Depends(get_current_user)):
    query = db.query(models.Alert).filter(models.Alert.is_active == True)
    if date == "today":
        now = datetime.now(timezone.utc)
        start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=1)
        query = query.filter(models.Alert.created_at >= start,
                             models.Alert.created_at < end)
    alerts = query.all()
    result = []
    for alert in alerts:
        driver = db.query(models.Driver).filter(models.Driver.id == alert.driver_id).first()
        result.append({
            "id": alert.id,
            "driver_id": alert.driver_id,
            "alert_type": alert.alert_type,
            "severity": alert.severity,
            "is_active": alert.is_active,
            "created_at": alert.created_at.isoformat() if alert.created_at else None,
            "driver_name": driver.name if driver else None,
        })
    return result

# ── 9. Última telemetría por conductor ──────────────────────────
@app.get("/telemetry/latest/{driver_id}", tags=["IoT"])
def get_latest_telemetry(driver_id: int,
                         db: Session = Depends(database.get_db),
                         _: models.User = Depends(get_current_user)):
    last = db.query(models.TelemetryLog).filter(
        models.TelemetryLog.driver_id == driver_id
    ).order_by(models.TelemetryLog.timestamp.desc()).first()
    if not last:
        raise HTTPException(status_code=404, detail="No hay datos de telemetría")
    return {
        "id": last.id,
        "driver_id": last.driver_id,
        "fatigue_level": last.fatigue_level,
        "heart_rate": last.heart_rate,
        "speed": last.speed,
        "timestamp": last.timestamp.isoformat() if last.timestamp else None,
    }

# ── 10. Resolver alerta (requiere JWT) ──────────────────────────
@app.put("/alerts/{id}/resolve", tags=["Alertas"])
def resolve_alert(id: int,
                  db: Session = Depends(database.get_db),
                  _: models.User = Depends(get_current_user)):
    alert = db.query(models.Alert).filter(models.Alert.id == id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Alerta no encontrada")
    if not alert.is_active:
        raise HTTPException(status_code=400, detail="La alerta ya está resuelta")
    alert.is_active = False
    driver = db.query(models.Driver).filter(models.Driver.id == alert.driver_id).first()
    if driver:
        # Verificar si el conductor tiene otras alertas activas
        otras_activas = db.query(models.Alert).filter(
            models.Alert.driver_id == driver.id,
            models.Alert.is_active == True,
            models.Alert.id != id
        ).count()
        if otras_activas == 0:
            driver.status = "OK"
    db.commit()
    return {"msg": "Alerta resuelta", "alert_id": id}

# ── 11. Estado del conductor (para Godot) ───────────────────────
@app.get("/drivers/{id}/status", tags=["Conductores"])
def driver_status(id: int, db: Session = Depends(database.get_db)):
    driver = db.query(models.Driver).filter(models.Driver.id == id).first()
    if not driver:
        raise HTTPException(status_code=404, detail="Conductor no encontrado")
    return {"driver_id": driver.id, "name": driver.name, "status": driver.status}
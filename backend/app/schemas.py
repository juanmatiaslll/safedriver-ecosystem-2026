from pydantic import BaseModel
from enum import Enum
from datetime import datetime

class Role(str, Enum):
    ADMIN = "ADMIN"
    CONDUCTOR = "CONDUCTOR"

class AlertType(str, Enum):
    FATIGA = "FATIGA"
    DISTRACCION = "DISTRACCION"
    VELOCIDAD = "VELOCIDAD"

class Severity(str, Enum):
    BAJA = "BAJA"
    MEDIA = "MEDIA"
    ALTA = "ALTA"
    CRITICA = "CRITICA"

class UserCreate(BaseModel):
    username: str
    password: str
    role: Role = Role.CONDUCTOR
    driver_id: int | None = None

class UserResponse(BaseModel):
    id: int
    username: str
    role: str
    driver_id: int | None = None
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class DriverResponse(BaseModel):
    id: int
    name: str
    dni: str
    status: str
    class Config:
        from_attributes = True

class DriverSummaryResponse(BaseModel):
    id: int
    name: str
    status: str
    active_alerts_count: int
    class Config:
        from_attributes = True

class AlertCreate(BaseModel):
    driver_id: int
    alert_type: AlertType
    severity: Severity

class AlertResponse(BaseModel):
    id: int
    driver_id: int
    alert_type: str
    severity: str
    is_active: bool
    created_at: str | None = None
    driver_name: str | None = None
    class Config:
        from_attributes = True

class DriverCreate(BaseModel):
    name: str
    dni: str
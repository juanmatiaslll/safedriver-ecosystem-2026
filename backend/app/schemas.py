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
    MEDIA = "MEDIA"
    ALTA = "ALTA"

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

class DriverRegisterRequest(BaseModel):
    name: str
    dni: str
    password: str

class RouteToggleResponse(BaseModel):
    msg: str
    is_on_route: bool

class DriverResponse(BaseModel):
    id: int
    name: str
    dni: str
    status: str
    is_on_route: bool
    class Config:
        from_attributes = True

class DriverSummaryResponse(BaseModel):
    id: int
    name: str
    dni: str
    status: str
    is_on_route: bool
    active_alerts_count: int
    last_telemetry: dict | None = None
    class Config:
        from_attributes = True

class TelemetryCreate(BaseModel):
    driver_id: int
    fatigue_level: float
    heart_rate: float
    speed: float

class TelemetryResponse(BaseModel):
    id: int
    driver_id: int
    fatigue_level: float
    heart_rate: float
    speed: float
    timestamp: str | None = None
    class Config:
        from_attributes = True

class TelemetryPostReturn(BaseModel):
    alert_created: bool
    alert_id: int | None = None
    alert_type: str | None = None
    severity: str | None = None
    driver_status: str

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
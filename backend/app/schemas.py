from pydantic import BaseModel

class UserCreate(BaseModel):
    username: str
    password: str

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

class AlertCreate(BaseModel):
    driver_id: int
    alert_type: str
    severity: str

class AlertResponse(BaseModel):
    id: int
    driver_id: int
    alert_type: str
    severity: str
    is_active: bool
    class Config:
        from_attributes = True

class DriverCreate(BaseModel):
    name: str
    dni: str
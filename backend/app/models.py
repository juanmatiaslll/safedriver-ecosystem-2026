from sqlalchemy import Column, Integer, String, Float, ForeignKey, Boolean, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from .database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    role = Column(String, default="CONDUCTOR")
    driver_id = Column(Integer, ForeignKey("drivers.id"), nullable=True)

class Driver(Base):
    __tablename__ = "drivers"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    dni = Column(String, unique=True)
    status = Column(String, default="OK")
    is_on_route = Column(Boolean, default=False)
    alerts = relationship("Alert", back_populates="driver")
    telemetry_logs = relationship("TelemetryLog", back_populates="driver")

class Alert(Base):
    __tablename__ = "alerts"
    id = Column(Integer, primary_key=True, index=True)
    driver_id = Column(Integer, ForeignKey("drivers.id"))
    alert_type = Column(String)
    severity = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    driver = relationship("Driver", back_populates="alerts")

class TelemetryLog(Base):
    __tablename__ = "telemetry_log"
    id = Column(Integer, primary_key=True, index=True)
    driver_id = Column(Integer, ForeignKey("drivers.id"))
    fatigue_level = Column(Float)
    heart_rate = Column(Float)
    speed = Column(Float)
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    driver = relationship("Driver", back_populates="telemetry_logs")
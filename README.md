# 🚗 SafeDriver Ecosystem-2026

Sistema inteligente de monitoreo y alertas tempranas para conductores, desarrollado como ecosistema distribuido utilizando FastAPI, SQLite, JWT, Flutter y simulación IoT/Godot.

---

# 📌 Descripción

SafeDriver es una plataforma orientada a la prevención de accidentes mediante monitoreo de conductores y generación de alertas en tiempo real.

El sistema permite:

- Registro y autenticación de usuarios
- Gestión de conductores
- Generación de alertas críticas
- Consulta del estado de conductores
- Integración con aplicaciones móviles e IoT
- API REST documentada automáticamente con Swagger

---

# 🛠️ Tecnologías utilizadas

## Backend
- Python 3.12
- FastAPI
- SQLAlchemy
- SQLite
- JWT Authentication
- Passlib + Bcrypt
- Uvicorn

## Frontend / Mobile
- Flutter

## Simulación / IoT
- Godot
- Python IoT Simulator

---

# 📁 Estructura del proyecto

```text
SafeDriver-Ecosystem-2026/
│
├── backend/
│   ├── app/
│   │   ├── auth.py
│   │   ├── database.py
│   │   ├── main.py
│   │   ├── models.py
│   │   └── schemas.py
│   │
│   ├── requirements.txt
│   ├── safedriver.db
│   └── venv/
│
├── iot_industrial/
│   └── driver_sim.py
│
├── mobile/
│   └── README.md
│
├── simulation_godot/
│   └── project.godot
│
└── README.md
```

---

# ⚙️ Instalación del Backend

## 1. Clonar repositorio

```bash
git clone https://github.com/juanmatiaslll/safedriver-ecosystem-2026.git
cd safedriver-ecosystem-2026
```

---

## 2. Crear entorno virtual

### Linux / Ubuntu

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
```

### Windows

```powershell
cd backend
python -m venv venv
venv\Scripts\activate
```

---

## 3. Instalar dependencias

```bash
pip install -r requirements.txt
```

---

# 🔧 Dependencias importantes

En `requirements.txt` se recomienda:

```txt
fastapi
uvicorn
sqlalchemy
python-jose
passlib
bcrypt==4.0.1
python-multipart
```

---

# ▶️ Ejecutar servidor

Desde la carpeta `backend`:

```bash
uvicorn app.main:app --reload
```

Servidor disponible en:

```text
http://127.0.0.1:8000
```

---

# 📚 Swagger UI

Documentación automática:

```text
http://127.0.0.1:8000/docs
```

OpenAPI:

```text
http://127.0.0.1:8000/openapi.json
```

---

# 🔐 Autenticación JWT

La API utiliza JWT Bearer Authentication.

## Flujo

1. Registrar usuario
2. Iniciar sesión
3. Obtener token JWT
4. Autorizar en Swagger
5. Consumir endpoints protegidos

---

# 👤 Registro de usuario

## Endpoint

```http
POST /auth/register
```

## Body

```json
{
  "username": "jose",
  "password": "1234"
}
```

---

# 🔑 Login

## Endpoint

```http
POST /auth/login
```

## Body

```json
{
  "username": "jose",
  "password": "1234"
}
```

## Respuesta

```json
{
  "access_token": "TOKEN_JWT",
  "token_type": "bearer"
}
```

---

# 🛡️ Uso del token JWT

En Swagger:

1. Presionar botón `Authorize`
2. Pegar SOLO el token JWT
3. Authorize
4. Close

---

# 🚘 Conductores

## Crear conductor

### Endpoint

```http
POST /drivers
```

### Requiere JWT

### Body

```json
{
  "name": "JoseDriver",
  "dni": "12345678"
}
```

---

## Obtener conductores

### Endpoint

```http
GET /drivers
```

---

## Estado del conductor

### Endpoint

```http
GET /drivers/{id}/status
```

---

# 🚨 Alertas

## Crear alerta

### Endpoint

```http
POST /alerts
```

### Requiere JWT

### Body

```json
{
  "driver_id": 1,
  "alert_type": "FATIGA",
  "severity": "HIGH"
}
```

---

## Obtener alertas activas

### Endpoint

```http
GET /alerts
```

### Requiere JWT

---

# 🧠 Arquitectura del sistema

```text
Flutter App
     │
     ▼
FastAPI Backend ─── SQLite
     │
     ├── JWT Auth
     ├── Drivers
     ├── Alerts
     │
     ▼
IoT Simulator / Godot
```

---

# 🧪 Pruebas realizadas

## Backend validado

- Registro de usuarios
- Login JWT
- Protección de rutas
- Creación de conductores
- Creación de alertas
- Validación de conductor inexistente
- Persistencia SQLite

---

# 👨‍💻 Equipo

- Juan Matías Lomas— Backend Core
- Jose Miguel Pacara Ponciano— QA, README y Testing
- Mateo Loaiza Gonzales— Mobile / Flutter
- Jordy Bujaico Bustillos— Simulación / IoT

---

# 📄 Licencia

Proyecto académico — 2026  
Universidad Nacional Mayor de San Marcos / Curso de Desarrollo Basado en Plataformas
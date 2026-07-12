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

**Backend:** Python 3.12, FastAPI, SQLAlchemy, SQLite, JWT, Passlib + Bcrypt, Uvicorn
**Mobile:** Flutter
**IoT / Simulación:** Python IoT Simulator (`requests`) — envía telemetrías reales al backend · Godot — simulación visual 2D (estilo mapa) que muestra los puntos donde se generan las alertas

---

# 📁 Estructura del proyecto

```text
SafeDriver-Ecosystem-2026/
│
├── backend/
│   ├── app/            # auth.py, database.py, main.py, models.py, schemas.py
│   ├── test/
│   ├── check_alerts.py
│   ├── pytest.ini
│   └── safedriver.db
│
├── iot_industrial/
│   └── driver_sim.py
│
├── mobile/              # proyecto Flutter estándar (lib/, android/, ios/, etc.)
│
├── simulation_godot/
│   └── project.godot
│
├── venv/
├── requirements.txt
└── README.md
```

---

# ⚙️ Instalación y ejecución del Backend

## 1. Clonar repositorio

```bash
git clone https://github.com/juanmatiaslll/safedriver-ecosystem-2026.git
cd safedriver-ecosystem-2026
```

## 2. Crear y activar entorno virtual (raíz del proyecto)

**Linux / Ubuntu**
```bash
python3 -m venv venv
source venv/bin/activate
```

**Windows (PowerShell)**
```powershell
py -m venv venv
.\venv\Scripts\Activate.ps1
```
Si la ejecución de scripts está bloqueada:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
.\venv\Scripts\Activate.ps1
```

## 3. Instalar dependencias

```bash
pip install -r requirements.txt
```

## 4. Ejecutar el servidor

Desde la carpeta `backend`:

```bash
uvicorn app.main:app --reload
```

Servidor: `http://127.0.0.1:8000` · Swagger: `http://127.0.0.1:8000/docs`

## 5. Pruebas automatizadas (opcional)

```bash
cd backend
pytest
```

---

# 📡 Ejecutar simulador IoT

Con el backend corriendo, en una **nueva terminal** (con el venv activado):

```bash
cd iot_industrial
python driver_sim.py
```

Pide por consola, en orden: **DNI del conductor**, **contraseña del conductor** y **ID del conductor**. Al validar contra el backend, empieza a enviar telemetrías (`POST /telemetry`) solo para ese conductor, generando alertas automáticamente.

> ⚠️ El conductor debe existir previamente (creado vía app Flutter, `/auth/register-driver`, o por un ADMIN en `/drivers`).

---

# 🗺️ Simulación visual (Godot) — opcional

Simulación 2D estilo mapa que muestra en tiempo real los puntos donde se generan las alertas. No es necesaria para que el resto del sistema funcione.

1. Abrir [Godot Engine](https://godotengine.org/download)
2. Importar `simulation_godot/project.godot`
3. Ejecutar la escena principal

---

# 📱 Instalación y ejecución de Flutter (Mobile)

**Linux / Ubuntu**
```bash
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"   # agregar a ~/.bashrc para que persista
flutter doctor
```

**Windows**
Descargar el SDK desde [docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows), descomprimir y agregar `flutter\bin` al PATH del sistema. Luego:
```powershell
flutter doctor
```

Instalar lo que `flutter doctor` indique como faltante. Luego, en ambos sistemas:

```bash
cd mobile
flutter pub get
flutter run
```

> ⚠️ **Importante:** la app móvil solo permite registrar **conductores**, no administradores. Para crear un ADMIN, ver la siguiente sección.

---

# 🛡️ Registro de usuario ADMIN (desde el backend)

Con el servidor corriendo, ir a `http://127.0.0.1:8000/docs`, abrir el endpoint **`POST /auth/register`**, usar `Try it out` y completar:

```json
{
  "username": "string",
  "password": "string",
  "role": "ADMIN",
  "driver_id": 0
}
```

`username` y `password` pueden ser cualquier valor, `role` se cambia a `"ADMIN"` y `driver_id` se deja en `0`. Ejecutar (`Execute`) y luego iniciar sesión normalmente con esas credenciales.

---

# 🔐 Autenticación JWT

Flujo: registrar usuario → login → obtener token → `Authorize` en Swagger (pegar solo el token) → consumir endpoints protegidos.

## Endpoints de autenticación

| Método | Endpoint | Body | Notas |
|---|---|---|---|
| POST | `/auth/register` | `{"username","password","role","driver_id"}` | `role`: `CONDUCTOR` o `ADMIN` |
| POST | `/auth/login` | `{"username","password"}` | Devuelve `{"access_token","token_type"}` |
| POST | `/auth/register-driver` | `{"name","dni","password"}` | Registra conductor + usuario en un paso (usado por la app Flutter) |

---

# 🚘 Conductores

| Método | Endpoint | Requiere JWT | Descripción |
|---|---|---|---|
| GET | `/drivers` | No | Listar conductores |
| POST | `/drivers` | Sí | Crear conductor — body: `{"name","dni"}` |
| GET | `/drivers/summary` | Sí | Conductores + alertas activas + última telemetría |
| GET | `/drivers/{id}/status` | No | Estado de un conductor |
| PUT | `/drivers/me/route` | Sí | Activa/desactiva la ruta del conductor autenticado |
| GET | `/conductores/{driver_id}/alertas` | Sí | Alertas del conductor (query: `page`, `limit`) |

---

# 📡 IoT / Telemetría

| Método | Endpoint | Requiere JWT | Descripción |
|---|---|---|---|
| POST | `/telemetry` | No | Recibe telemetría — body: `{"driver_id","fatigue_level","heart_rate","speed"}`. Puede generar una alerta automáticamente. |
| GET | `/telemetry/latest/{driver_id}` | Sí | Última telemetría registrada de un conductor |

---

# 🚨 Alertas

| Método | Endpoint | Requiere JWT | Descripción |
|---|---|---|---|
| POST | `/alerts` | Sí | Crear alerta — body: `{"driver_id","alert_type","severity"}` |
| GET | `/alerts` | Sí | Listar alertas (query: `page`, `limit`, `date`) |
| PUT | `/alerts/{id}/resolve` | Sí | Marca la alerta como resuelta |
| DELETE | `/alerts` | Sí (ADMIN) | Elimina **todo** el historial de alertas (activas e inactivas) y resetea a `OK` el estado de los conductores que estaban `EN_ALERTA` |

> 🗑️ En la app móvil, el usuario ADMIN tiene un botón (ícono de basurero) en la pantalla de Alertas que llama a este endpoint, con confirmación previa. Útil para limpiar el historial acumulado y evitar que el front y la simulación de Godot se saturen de alertas viejas.

---

# 📊 Dashboard

| Método | Endpoint | Requiere JWT | Descripción |
|---|---|---|---|
| GET | `/dashboard/stats` | Sí | Métricas generales del sistema (conductores, alertas activas, etc.) |

---

# 🧠 Arquitectura del sistema

```text
Flutter App
     │
     ▼
FastAPI Backend ─── SQLite
     │
     ├── JWT Auth (register / login / register-driver)
     ├── Drivers (CRUD, summary, status, route toggle)
     ├── Telemetry (IoT)
     ├── Alerts
     ├── Dashboard
     │
     ▼
IoT Simulator / Godot
```

---

# 👨‍💻 Equipo

- Juan Matías Lomas — Backend Core
- Jose Miguel Pacara Ponciano — Godot, QA, README y Testing
- Mateo Loaiza Gonzales — Mobile / Flutter
- Jordy Bujaico Bustillos — Simulación / IoT

---

# 📄 Licencia

Proyecto académico — 2026
Universidad Nacional Mayor de San Marcos / Curso de Desarrollo Basado en Plataformas

import requests
import random
import time

BASE_URL = "http://127.0.0.1:8000"

USERNAME = "driver1"
PASSWORD = "123456"

DRIVER_ID = 1


def fatigue_level():
    return random.randint(10, 100)


def heart_rate():
    return random.randint(60, 120)


def speed():
    return random.randint(0, 140)


def login():
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={
            "username": "ADMINJOSE",
            "password": "1234"
        }
    )

    response.raise_for_status()

    return response.json()["access_token"]


def send_telemetry(jwt_token):
    fatigue = fatigue_level()

    payload = {
        "driver_id": DRIVER_ID,
        "fatigue_level": fatigue,
        "heart_rate": heart_rate(),
        "speed": speed()
    }

    response = requests.post(
        f"{BASE_URL}/telemetry",
        headers={
            "Authorization": f"Bearer {jwt_token}"
        },
        json=payload
    )

    print("Datos enviados:", payload)
    print("Respuesta:", response.status_code)

    return fatigue


def main():
    token = login()

    print("JWT obtenido correctamente")

    while True:
        fatigue = send_telemetry(token)

        if fatigue >= 80:
            print("[ALERTA CRÍTICA] Umbral superado")
            time.sleep(2)
        else:
            time.sleep(5)


if __name__ == "__main__":
    main()
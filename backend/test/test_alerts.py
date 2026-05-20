from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def get_token():
    client.post(
        "/auth/register",
        json={
            "username": "alert_user",
            "password": "1234"
        }
    )

    response = client.post(
        "/auth/login",
        json={
            "username": "alert_user",
            "password": "1234"
        }
    )

    return response.json()["access_token"]


def test_alert_without_token():
    response = client.post(
        "/alerts",
        json={
            "driver_id": 1,
            "alert_type": "FATIGA",
            "severity": "ALTA"
        }
    )

    # HTTPBearer devuelve 403 cuando no hay token
    assert response.status_code == 401


def test_create_driver():
    token = get_token()

    response = client.post(
        "/drivers",
        headers={
            "Authorization": f"Bearer {token}"
        },
        json={
            "name": "Jose Driver",
            "dni": "77777777"
        }
    )

    assert response.status_code in [201, 400]


def test_create_alert():
    token = get_token()

    driver_response = client.post(
        "/drivers",
        headers={
            "Authorization": f"Bearer {token}"
        },
        json={
            "name": "Carlos",
            "dni": "88888888"
        }
    )

    if driver_response.status_code == 201:
        driver_id = driver_response.json()["driver_id"]
    else:
        driver_id = 1

    response = client.post(
        "/alerts",
        headers={
            "Authorization": f"Bearer {token}"
        },
        json={
            "driver_id": driver_id,
            "alert_type": "FATIGA",
            "severity": "ALTA"
        }
    )

    assert response.status_code == 201
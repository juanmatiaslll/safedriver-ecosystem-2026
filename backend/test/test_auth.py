from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_register():
    response = client.post(
        "/auth/register",
        json={
            "username": "jose_test",
            "password": "1234"
        }
    )

    # Puede ser 200 si crea
    # o 400 si ya existe
    assert response.status_code in [200, 400]


def test_login():
    response = client.post(
        "/auth/login",
        json={
            "username": "jose_test",
            "password": "1234"
        }
    )

    assert response.status_code == 200

    data = response.json()

    assert "access_token" in data
    assert data["token_type"] == "bearer"
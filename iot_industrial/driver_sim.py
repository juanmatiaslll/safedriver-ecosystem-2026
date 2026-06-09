import requests
import random
import time
import getpass

BASE_URL = "http://127.0.0.1:8000"

def login():
    # JS.5: Pedir DNI y password
    username = input("Ingrese su DNI (usuario): ")
    password = getpass.getpass("Ingrese su contraseña: ")
    
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={"username": username, "password": password} # <-- CAMBIADO: 'data=' por 'json='
    )
    
    if response.status_code != 200:
        print("Error de login: credenciales inválidas")
        exit()

    return response.json()["access_token"]

def send_telemetry(jwt_token, driver_id):
    payload = {
        "driver_id": driver_id,
        "fatigue_level": random.randint(10, 100),
        "heart_rate": random.randint(60, 120),
        "speed": random.randint(0, 140)
    }

    try:
        response = requests.post(
            f"{BASE_URL}/telemetry",
            headers={"Authorization": f"Bearer {jwt_token}"},
            json=payload
        )
        
        # JS.1 & JS.5: Manejo del error 400 "Driver no en ruta"
        if response.status_code == 400:
            print(f"[-] No se enviaron datos: {response.json().get('detail')}")
            return False
        
        response.raise_for_status()
        print(f"[+] Datos enviados: {payload}")
        return True
        
    except requests.exceptions.RequestException as e:
        print(f"Error de conexión: {e}")
        return False

def main():
    token = login()
    # Pedir el ID del conductor al iniciar (o podrías obtenerlo del token si tu API lo permite)
    driver_id = int(input("Ingrese su ID de conductor: "))
    
    print("Simulación iniciada. Presione Ctrl+C para salir.")
    
    while True:
        success = send_telemetry(token, driver_id)
        # Espera entre envíos
        time.sleep(5 if success else 10) 

if __name__ == "__main__":
    main()
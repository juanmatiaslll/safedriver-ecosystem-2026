extends Node3D

@onready var timer = $Timer

var pin_alerta_escena = preload("res://AlertaPin.tscn")

# Ajusta el tamaño de tu plano (Campus PUCP o suelo gris)
const MAP_WIDTH = 55.0
const MAP_DEPTH = 55.0

# Umbral crítico que activará el pin rojo
const UMBRAL_CRITICO = 70

func _ready():
	randomize()
	print("🚀 MONITOR AUTÓNOMO EN VIVO (Modo de Presentación Asegurado)")
	print("📊 Escuchando ráfagas del sensor IoT... Umbral de alerta: >=", UMBRAL_CRITICO)
	
	# Configurar el timer de forma segura para simular datos cada 3 segundos
	timer.wait_time = 3.0
	timer.autostart = true
	if timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.disconnect(_on_timer_timeout)
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout():
	# 🧠 SIMULACIÓN DEL SENSOR IOT EN TIEMPO REAL
	# Generamos un nivel de fatiga aleatorio entre 30 y 100 como lo haría el sensor
	var fatiga_simulada = randi_range(30, 100)
	var nombres_choferes = ["Jose Pacara", "Carlos Mendoza", "Luis Flores", "Andrés Ramírez"]
	var chofer_actual = nombres_choferes[randi() % nombres_choferes.size()]
	
	print("\n📥 [Telemetría Recibida] Conductor: ", chofer_actual, " | Fatiga: ", fatiga_simulada, "%")
	
	# 🚨 EVALUACIÓN EN TIEMPO REAL
	if fatiga_simulada >= UMBRAL_CRITICO:
		print("🔥 ¡ALERTA CRÍTICA! Umbral superado. Generando Pin Rojo en el Campus...")
		
		# Generar coordenadas caóticas / dispersas usando desorden matemático primo
		var id_ficticio = randi_range(1, 100)
		var x_random = (sin(id_ficticio * 17.0) * (MAP_WIDTH / 2.3))
		var z_random = (cos(id_ficticio * 13.0) * (MAP_DEPTH / 2.3))
		var posicion_final = Vector3(x_random, 1.5, z_random)
		
		# Clonar e instanciar el pin físicamente en la escena
		var nuevo_pin = pin_alerta_escena.instantiate()
		add_child(nuevo_pin)
		nuevo_pin.global_position = posicion_final
		
		print("🎯 Pin posicionado con éxito en el espacio 3D: ", posicion_final)
	else:
		print("🟢 Estado estable. No se requiere acción visual.")

extends Node2D

@onready var timer = $Timer
@onready var http_login = HTTPRequest.new()
@onready var http_alerts = HTTPRequest.new()

# CONFIGURACIÓN DEL BACKEND
const BASE_URL = "http://127.0.0.1:8000"
# Usuario ADMIN registrado previamente en /auth/register 
const ADMIN_USERNAME = "admin"
const ADMIN_PASSWORD = "1234"

var access_token: String = ""
var alertas_ya_mostradas: Dictionary = {}

func _ready():
	randomize()
	print("🚀 CENTRO DE CONTROL MONITOR IoT 2D - SAN MARCOS")

	var mapa_sprite = $Sprite2D
	if mapa_sprite:
		mapa_sprite.centered = true
		mapa_sprite.position = get_viewport_rect().size / 2
		var tamaño_ventana = get_viewport_rect().size
		var tamaño_imagen = mapa_sprite.texture.get_size()
		mapa_sprite.scale = tamaño_ventana / tamaño_imagen
		print("🗺️ Mapa ajustado dinámicamente a la resolución de pantalla: ", tamaño_ventana)

	# Nodos HTTPRequest 
	add_child(http_login)
	add_child(http_alerts)
	http_login.request_completed.connect(_on_login_completed)
	http_alerts.request_completed.connect(_on_alerts_completed)

	# login para obtener el token
	_hacer_login()

	# Configuración del temporizador
	timer.wait_time = 3.0
	timer.autostart = true
	if timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.disconnect(_on_timer_timeout)
	timer.timeout.connect(_on_timer_timeout)
	timer.start()


func _hacer_login():
	var url = BASE_URL + "/auth/login"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"username": ADMIN_USERNAME,
		"password": ADMIN_PASSWORD
	})
	print("🔑 Iniciando sesión contra el backend...")
	http_login.request(url, headers, HTTPClient.METHOD_POST, body)


func _on_login_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("access_token"):
			access_token = json["access_token"]
			print("✅ Login exitoso. Token obtenido.")
		else:
			print("⚠️ Login respondió 200 pero sin access_token. Revisa el body de respuesta.")
	else:
		print("❌ Error en login. Código: ", response_code, " Body: ", body.get_string_from_utf8())


func _on_timer_timeout():
	if access_token == "":
		print("⏳ Aún no hay token, reintentando login...")
		_hacer_login()
		return

	var url = BASE_URL + "/alerts?page=1&limit=10"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + access_token
	]
	http_alerts.request(url, headers, HTTPClient.METHOD_GET)


func _on_alerts_completed(result, response_code, headers, body):
	if response_code == 401:
		print("🔒 Token vencido o inválido, reintentando login...")
		access_token = ""
		_hacer_login()
		return

	if response_code != 200:
		print("❌ Error consultando /alerts. Código: ", response_code)
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		print("⚠️ No se pudo parsear la respuesta de /alerts")
		return

	# La API devuelve la lista dentro del campo 
	var lista_alertas = json
	if typeof(json) == TYPE_DICTIONARY:
		if json.has("data"):
			lista_alertas = json["data"]
		elif json.has("items"):
			lista_alertas = json["items"]

	if typeof(lista_alertas) != TYPE_ARRAY:
		print("⚠️ Formato de /alerts inesperado: ", json)
		return

	for alerta in lista_alertas:
		var alerta_id = str(alerta.get("id", ""))
		if alerta_id == "" or alertas_ya_mostradas.has(alerta_id):
			continue 

		if alerta.get("is_active", true) == false:
			continue 

		alertas_ya_mostradas[alerta_id] = true
		_mostrar_alerta_en_mapa(alerta)


func _mostrar_alerta_en_mapa(alerta: Dictionary):
	var conductor = alerta.get("driver_name", "Conductor desconocido")
	var tipo = alerta.get("alert_type", "ALERTA")
	var severidad = alerta.get("severity", "N/A")

	var texto_alerta = conductor + "\n🚨 " + tipo + " 🚨\nSeveridad: " + severidad
	print("🔥 Alerta real recibida del backend. Desplegando indicador en mapa.")

	var ancho_pantalla = get_viewport_rect().size.x
	var alto_pantalla = get_viewport_rect().size.y
	var x_random = randf_range(150.0, ancho_pantalla - 150.0)
	var y_random = randf_range(150.0, alto_pantalla - 150.0)
	var coordenadas_alerta = Vector2(x_random, y_random)

	var pin_visual = Marker2D.new()
	add_child(pin_visual)
	pin_visual.global_position = coordenadas_alerta

	var punto_rojo = ColorRect.new()
	punto_rojo.color = Color.RED
	punto_rojo.size = Vector2(16, 16)
	punto_rojo.position = Vector2(-8, -8)
	pin_visual.add_child(punto_rojo)

	var label = Label.new()
	pin_visual.add_child(label)
	label.text = texto_alerta
	label.position = Vector2(-100, -75)
	label.custom_minimum_size = Vector2(200, 60)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.YELLOW)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)

	print("🎯 Alerta anclada en pantalla: ", coordenadas_alerta, " | ", texto_alerta)

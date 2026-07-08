extends Node2D

@onready var timer = $Timer

# Umbrales críticos del sistema IoT (SafeDriver 2026)
const UMBRAL_FATIGA_CRITICA = 70
const UMBRAL_VELOCIDAD_CRITICA = 90

func _ready():
	randomize()
	print("🚀 CENTRO DE CONTROL MONITOR IoT 2D - SAN MARCOS")
	print("📊 Escuchando telemetría... Umbral Fatiga: ", UMBRAL_FATIGA_CRITICA, "% | Velocidad: ", UMBRAL_VELOCIDAD_CRITICA, " km/h")
	
	# 🛠️ AJUSTE AUTOMÁTICO DEL MAPA A LA PANTALLA
	var mapa_sprite = $Sprite2D # Busca tu nodo de mapa. Asegúrate de que se llame exactamente 'Sprite2D'
	if mapa_sprite:
		mapa_sprite.centered = true
		mapa_sprite.position = get_viewport_rect().size / 2
		
		# Forzar a que la imagen escale exactamente al tamaño de tu ventana actual
		var tamaño_ventana = get_viewport_rect().size
		var tamaño_imagen = mapa_sprite.texture.get_size()
		mapa_sprite.scale = tamaño_ventana / tamaño_imagen
		print("🗺️ Mapa ajustado dinámicamente a la resolución de pantalla: ", tamaño_ventana)
	
	# Configuración limpia del temporizador para activarse cada 3 segundos
	timer.wait_time = 3.0
	timer.autostart = true
	if timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.disconnect(_on_timer_timeout)
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout():
	# 🧠 SIMULACIÓN DE TRANSMISIÓN DE SENSORES
	var fatiga_simulada = randi_range(30, 100)
	var velocidad_simulada = randi_range(40, 120)
	
	var nombres_choferes = ["Jose Pacara", "Juan carlos", "Luis Flores"]
	var chofer_actual = nombres_choferes[randi() % nombres_choferes.size()]
	
	print("\n📥 [Paquete IoT Recibido] Conductor: ", chofer_actual, " | Fatiga: ", fatiga_simulada, "% | Velocidad: ", velocidad_simulada, " km/h")
	
	# 🚨 EVALUACIÓN DE INFRACCIONES
	if fatiga_simulada >= UMBRAL_FATIGA_CRITICA or velocidad_simulada >= UMBRAL_VELOCIDAD_CRITICA:
		var texto_alerta = ""
		
		# Clasificación de la alerta para el reporte visual
		if fatiga_simulada >= UMBRAL_FATIGA_CRITICA and velocidad_simulada >= UMBRAL_VELOCIDAD_CRITICA:
			texto_alerta = chofer_actual + "\n🚨 RIESGO EXTREMO 🚨\nFatiga: " + str(fatiga_simulada) + "% | Vel: " + str(velocidad_simulada) + " km/h"
		elif fatiga_simulada >= UMBRAL_FATIGA_CRITICA:
			texto_alerta = chofer_actual + "\n🥱 Alerta: Fatiga Crítica\nNivel: " + str(fatiga_simulada) + "%"
		else:
			texto_alerta = chofer_actual + "\n⚡ Alerta: Exceso Velocidad\nVelocidad: " + str(velocidad_simulada) + " km/h"
			
		print("🔥 Infracción detectada. Desplegando indicador en mapa de Google Maps.")
		
		# 📐 DETECTAR EL TAMAÑO REAL DE LA VENTANA EN TIEMPO REAL
		var ancho_pantalla = get_viewport_rect().size.x
		var alto_pantalla = get_viewport_rect().size.y
		
		# Generar coordenadas esparcidas por TODA la pantalla actual (con margen de 150px para evitar bordes)
		var x_random = randf_range(150.0, ancho_pantalla - 150.0)
		var y_random = randf_range(150.0, alto_pantalla - 150.0)
		var coordenadas_alerta = Vector2(x_random, y_random)
		
		# 🛠️ CREACIÓN INSTANTÁNEA DEL PIN (Círculo de Alerta)
		var pin_visual = Marker2D.new()
		add_child(pin_visual)
		pin_visual.global_position = coordenadas_alerta
		
		# Dibujamos un punto rojo usando un nodo básico texturizado por código
		var punto_rojo = ColorRect.new()
		punto_rojo.color = Color.RED
		punto_rojo.size = Vector2(16, 16)
		punto_rojo.position = Vector2(-8, -8) # Centrar el cuadrado en el punto exacto
		pin_visual.add_child(punto_rojo)
		
		# 📝 CREACIÓN DEL TEXTO DETALLADO (Label 2D Nativo)
		var label = Label.new()
		pin_visual.add_child(label)
		label.text = texto_alerta
		
		# Posicionamiento perfecto flotando arriba del punto
		label.position = Vector2(-100, -75)
		label.custom_minimum_size = Vector2(200, 60)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# Ajustes de diseño para que sea perfectamente legible sobre las calles de San Marcos
		label.add_theme_color_override("font_color", Color.YELLOW)        # Letras amarillas brillantes
		label.add_theme_color_override("font_outline_color", Color.BLACK) # Contorno negro grueso
		label.add_theme_constant_override("outline_size", 8)             # Nivel de contraste
		
		print("🎯 Alerta anclada en pantalla: ", coordenadas_alerta)
	else:
		print("🟢 Monitoreo de rutina: Estado estable para la flota.")

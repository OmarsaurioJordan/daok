extends Node2D

const radioExplo = 130.0 # circulo donde la explosion mata moviles

var colisiones = 0 # cuenta la cantidad de objetos en colision
var mundo = null # nodo maestro para asceso rapido
var prohibido = false # true si no se puede poner ahi
var cambiaValor = false # false:no, true:ver
var miNeto = null # para mantener en GUI el valor actual de dinero
var miExplo = null # para instanciar rapido las particulas

func _ready():
	mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.get_node("GUI").visible = false
	mundo.get_node("GUI").NoSeguir()
	mundo.get_node("GUI")._on_BEyeOn_button_down()
	miNeto = get_node("Neto")
	remove_child(miNeto)
	mundo.get_node("Esquina").add_child(miNeto)
	miNeto.position = Vector2(0, 0)
	miNeto.scale = Vector2(1, 1)
	miExplo = load("res://scenes/otros/Explosion.tscn")

func _process(_delta):
	position = get_global_mouse_position()
	miNeto.get_node("Valor").text = "$" + str(mundo.Costos("todo"))
	get_node("Value/Valor").text = "$" + str(mundo.Costos("dinamita"))
	get_node("Value").scale = mundo.get_node("Esquina").rect_scale
	# verificar si se puede poner
	var ok = colisiones == 0
	if ok != prohibido:
		prohibido = ok
		if ok:
			get_node("Imagen/Bomba").modulate = Color(1, 1, 1, 1)
		else:
			get_node("Imagen/Bomba").modulate = Color(1, 1, 1, 0.25)
	# pintar el valor
	if ok != cambiaValor:
		cambiaValor = ok
		get_node("Value").visible = ok

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_LEFT:
				Extallido()
			elif event.button_index == BUTTON_MIDDLE:
				Cerrar()
	elif event.is_action_pressed("ui_cancel"):
		Cerrar()

func Extallido():
	if colisiones == 0 and get_node("Espera").is_stopped():
		if mundo.Comprando("dinamita"):
			var pExplo = get_node("Fin").get_children()
			pExplo.shuffle()
			var aux
			for e in pExplo:
				aux = miExplo.instance()
				mundo.get_node("Objetos").add_child(aux)
				aux.position = e.global_position
				if mundo.EnTierra(e.global_position):
					aux = mundo.manchis[0].instance()
					mundo.get_node("Manchas").add_child(aux)
					aux.position = e.global_position
			mundo.Explosion(position, radioExplo)
			get_node("Espera").start()

func Cerrar():
	get_tree().get_nodes_in_group("gui")[0].visible = true
	miNeto.queue_free()
	queue_free()

func _on_Construccion_area_entered(area):
	if not area.get_parent().is_in_group("arbol"):
		colisiones += 1

func _on_Construccion_area_exited(area):
	if not area.get_parent().is_in_group("arbol"):
		colisiones -= 1

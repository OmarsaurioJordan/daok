extends Node2D

var colision = [[], []] # 0:solido, 1:cadaver
var sombrita = null # sombra del personaje
var body = null # contiene al cuerpo de los dos, izquierdo o derecho
var ticks = 10 # retraso para desconectar process delta

func _ready():
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	sombrita = load("res://scenes/otros/Sombra.tscn").instance()
	mundo.get_node("Sombras").add_child(sombrita)
	if randf() < 0.5:
		get_node("Imagen/Cuerpo2").visible = true
		get_node("Imagen/Cuerpo1").queue_free()
		body = get_node("Imagen/Cuerpo2")
	else:
		get_node("Imagen/Cuerpo1").visible = true
		get_node("Imagen/Cuerpo2").queue_free()
		body = get_node("Imagen/Cuerpo1")
	mundo.SonidoLen([get_node("Sjasperdev"), get_node("Sguinxu"), get_node("Ssdev"),
	get_node("SEnfermo"), get_node("SHerido"), get_node("SHambre")])

func _process(delta):
	if not Rebote(0, delta):
		if not Rebote(1, delta):
			ticks -= 1
			if ticks <= 0:
				get_node("Cadaver").monitoring = false
				set_process(false)
				_on_Sombri_timeout()
	sombrita.position = position

func Rebote(ind, delta):
	var rebote = Vector2(0, 0)
	for c in colision[ind]:
		rebote += c.position.direction_to(position)
	if rebote.x != 0 or rebote.y != 0:
		position += rebote.normalized() * 100 * delta
		return true
	return false

func _on_Pudrir_timeout():
	sombrita.queue_free()
	queue_free()

func _on_Movil_area_entered(area):
	var nn = area.name
	if nn == "Cadaver":
		colision[1].append(area.get_parent())
	elif nn == "Solido":
		colision[0].append(area.get_parent())

func _on_Movil_area_exited(area):
	var nn = area.name
	if nn == "Cadaver":
		colision[1].erase(area.get_parent())
	elif nn == "Solido":
		colision[0].erase(area.get_parent())

func Quejido():
	match body.frame:
		4:
			get_node("Sjasperdev").play()
		8:
			get_node("Sguinxu").play()
		5:
			get_node("Ssdev").play()

func _on_Tumba_timeout():
	var c = Color(1, 1, 1, get_node("Pudrir").time_left / get_node("Pudrir").wait_time)
	body.modulate = c
	sombrita.modulate = c

func _on_Sombri_timeout():
	sombrita.position = position
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	if not mundo.EnTierra(position):
		body.visible = false
		get_node("Imagen/Chapuzon").emitting = true
		get_node("Tumba").start(0.5)
		get_node("Pudrir").start(12)

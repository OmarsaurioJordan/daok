extends Node2D

var nombre = "" # para saber que edificio se construye
var demora = 0 # tiempo de construir cada edificio

func _ready():
	get_node("Progreso").start(rand_range(2, 4))
	get_node("Imagen/Demoler/Anima").play("idle")
	var gui = get_tree().get_nodes_in_group("gui")[0]
	get_node("Imagen/Actividad").visible = gui.get_node("Opciones/BEyeOn").visible
	Nombrar()
	match nombre:
		"Centro":
			demora = 220
		"Cultivo":
			demora = 50
		"Edificio":
			demora = 60
		"Hospital":
			demora = 300 # 150 * 2
		"Estudio":
			demora = 140
		"Juego":
			demora = 90
		"Ocio":
			demora = 200 # 100 * 2
		"Trabajo":
			demora = 480 # 120 * 4
		"Torre":
			demora = 40
		"Puerto":
			demora = 70
		"Parque":
			demora = 30
	demora /= float(Andamios().size())
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	for a in Andamios():
		mundo.SonidoLen([a.get_node("Sonido")])

func Nombrar():
	if name.count("@") == 0:
		nombre = name
	else:
		nombre = name.split("@", false)[0]
	nombre = nombre.substr(1)

func Andamios():
	var andamios = get_node("Imagen").get_children()
	for a in range(andamios.size() - 1, -1, -1):
		if not andamios[a].is_in_group("andamio"):
			andamios.remove(a)
	return andamios

func Avance():
	var andamios = Andamios()
	var tot = 0
	for a in andamios:
		tot += a.get_node("Progreso").value
	return tot

func Vacantes(esDemoler):
	if get_node("Imagen/Actividad").pressed:
		if get_node("Imagen/Demoler").visible == esDemoler:
			var andamios = Andamios()
			var progre
			var tot = 0
			for a in andamios:
				if a.get_node("Trabajo").get_child_count() == 0:
					progre = a.get_node("Progreso").value
					if progre != 0 and progre != 100:
						tot += 1
			return tot
	return 0

func WorkOk(esDemoler, cualquiera=false):
	if get_node("Imagen/Actividad").pressed:
		if get_node("Imagen/Demoler").visible == esDemoler or cualquiera:
			var andamios = Andamios()
			andamios.shuffle()
			var progre
			for a in andamios:
				if a.get_node("Trabajo").get_child_count() == 0:
					progre = a.get_node("Progreso").value
					if progre != 0 and progre != 100:
						return a.get_node("Trabajo")
	return null

func _on_Progreso_timeout():
	get_node("Progreso").start(rand_range(7, 9))
	var andamios = Andamios()
	var add = -1 if get_node("Imagen/Demoler").visible else 1
	var progre
	var intel
	for a in andamios:
		if a.get_node("Trabajo").get_child_count() != 0:
			intel = lerp(1, 0.5, a.get_node("Trabajo").get_child(0).GetIntelecto())
			a.get_node("Progreso").value += (add * 100.0 * intel * 8.0) / demora
			progre = a.get_node("Progreso").value
			if progre == 0 or progre == 100:
				a.get_node("Trabajo").get_child(0).LiberaEstado()
				a.get_node("Polvo").emitting = false
				a.get_node("Sonido").stop()
			else:
				if andamios.size() == 1:
					a.get_node("Sonido").play(2.5)
				else:
					a.get_node("Sonido").play(randf() * 2.5)
				if not a.get_node("Polvo").emitting:
					a.get_node("Polvo").emitting = true
		else:
			a.get_node("Polvo").emitting = false
	Avanzar()

func Trabajable():
	return Vacantes(false) != 0

func _on_Actividad_toggled(button_pressed):
	if not button_pressed:
		Sacarlos()

func Sacarlos():
	var andamios = Andamios()
	var u
	for a in andamios:
		a.get_node("Sonido").stop()
		if a.get_node("Trabajo").get_child_count() != 0:
			u = a.get_node("Trabajo").get_child(0)
			u.busEmple = false
			u.LiberaEstado()

func PostSave(buffer):
	buffer.put_u8(0) # es construible, andamios
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	var ind = 255 # extremo inutil
	for i in range(mundo.edifiNames.size()):
		if mundo.edifiNames[i] == nombre:
			ind = i
			break
	buffer.put_u8(ind) # para saber que edificio es

func Save(buffer):
	PostSave(buffer)
	buffer.put_float(position.x)
	buffer.put_float(position.y)
	for d in Andamios():
		buffer.put_float(d.get_node("Progreso").value)
	var a = 1 if get_node("Imagen/Actividad").pressed else 0
	buffer.put_u8(a)
	a = 1 if get_node("Imagen/Demoler").visible else 0
	buffer.put_u8(a)

func Open(buffer):
	position.x = buffer.get_float()
	position.y = buffer.get_float()
	for d in Andamios():
		d.get_node("Progreso").value = buffer.get_float()
	get_node("Imagen/Actividad").pressed = buffer.get_u8() != 0
	get_node("Imagen/Demoler").visible = buffer.get_u8() != 0

func Avanzar():
	var andamios = Andamios()
	var tot = 0
	for a in andamios:
		tot += a.get_node("Progreso").value
	if tot == 0:
		var mundo = get_tree().get_nodes_in_group("mundo")[0]
		mundo.Log("demuele un " + nombre)
		Destruir()
	elif float(tot) / andamios.size() == 100:
		Construct()

func Construct():
	var aux = load("res://scenes/solidos/" + nombre + ".tscn").instance()
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.get_node("Objetos").add_child(aux)
	aux.position = position
	mundo.Log("construye un " + nombre)
	if nombre == "Centro":
		mundo.get_node("GUI/SCentro").play()
	Sacarlos()
	queue_free()

func CambiaDemoler():
	get_node("Imagen/Demoler").visible = not get_node("Imagen/Demoler").visible
	var andamios = Andamios()
	for a in andamios:
		a.get_node("Progreso").value = clamp(a.get_node("Progreso").value, 1, 99)

func ModoDemoler():
	get_node("Imagen/Demoler").visible = true
	var andamios = Andamios()
	for a in andamios:
		a.get_node("Progreso").value = 99

func TieneAlgo():
	# evita error desde diamante
	return false

func Destruir(conhumo=true):
	if conhumo:
		var mundo = get_tree().get_nodes_in_group("mundo")[0]
		mundo.HumoDemolision(self)
	Sacarlos()
	queue_free()

func Deconstruir():
	# en modo demoler, se llama a este nombre de funcion, evita fallos
	CambiaDemoler()

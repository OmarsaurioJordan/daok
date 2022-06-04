extends Node2D

const alimentoTortuga = 8 # numero minimo de arboles para crear tortuga
const visionTortuga = 400.0 # criatura tortuga, distancia vision

var maxArboles = 0 # densidad probabilistica tomada del mundo, rapido acceso
var arboles = 0 # cantidad de arboles en radio
var miArea = 0 # talla en cuadros del area de reserva
var nombre = "" # para demoler

func _ready():
	get_node("Plantador").start(rand_range(50, 70))
	get_node("Florista").start(rand_range(25, 35))
	get_node("Huevo").start(rand_range(180, 240))
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	maxArboles = mundo.maxArboles * 2.0
	Nombrar()
	mundo.SonidoLen([get_node("Sonido")])
	get_node("Reserva/Coli").shape.radius = mundo.radioReserva

func Nombrar():
	if name.count("@") == 0:
		nombre = name
	else:
		nombre = name.split("@", false)[0]

func _process(delta):
	if get_node("Imagen/Actividad").pressed:
		get_node("Imagen/Rosa").rotate(-0.666 * delta)

func ElArea():
	miArea = 0
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	var radio = get_node("Reserva/Coli").shape.radius
	var pos
	for x in range(mundo.tallMatrix):
		for y in range(mundo.tallMatrix):
			if mundo.matrix.get_bit(Vector2(x, y)):
				pos = Vector2(x + 0.5, y + 0.5) * mundo.celda
				if pos.distance_to(position) < radio:
					miArea += 1

func CuentaArboles():
	arboles = 0
	var arbis = get_tree().get_nodes_in_group("arbol")
	var radio = get_node("Reserva/Coli").shape.radius
	for a in arbis:
		if a.position.distance_to(position) < radio:
			arboles += 1

func _on_Plantador_timeout():
	get_node("Plantador").start(rand_range(50, 70))
	get_node("Conteo").start()
	Plantar()
	get_node("Sonido").play()

func Forestado():
	if get_node("Imagen/Actividad").pressed:
		return arboles > ceil(miArea * maxArboles)
	return false

func Plantar():
	if get_node("Imagen/Actividad").pressed:
		var radio = randf() * get_node("Reserva/Coli").shape.radius
		var angulo = randf() * 2 * PI
		var pos = position + Vector2(radio, 0).rotated(angulo)
		if position.distance_to(pos) > 75:
			var mundo = get_tree().get_nodes_in_group("mundo")[0]
			if mundo.EnTierra(pos):
				var arbis = get_tree().get_nodes_in_group("arbol")
				var ok = true
				for a in arbis:
					if a.position.distance_to(pos) < 55:
						ok = false
						break
				if ok:
					var aux = load("res://scenes/solidos/Arbol.tscn").instance()
					mundo.get_node("Objetos").add_child(aux)
					aux.position = pos
					QuitaFlor([aux])
					mundo.QuitaNaturales()

func QuitaFlor(arbis=[]):
	var flores = get_tree().get_nodes_in_group("flor")
	if arbis.empty():
		arbis = get_tree().get_nodes_in_group("arbol")
	var ok
	for f in flores:
		ok = false
		for a in arbis:
			if a.position.distance_to(f.position) < 36:
				ok = true
				break
		if ok:
			f.queue_free()

func Flores():
	if get_node("Imagen/Actividad").pressed:
		var radio = randf() * get_node("Reserva/Coli").shape.radius
		var angulo = randf() * 2 * PI
		var pos = position + Vector2(radio, 0).rotated(angulo)
		var mundo = get_tree().get_nodes_in_group("mundo")[0]
		if mundo.EnTierra(pos):
			var vegeta = get_tree().get_nodes_in_group("vegetal")
			var ok = true
			for v in vegeta:
				if v.position.distance_to(pos) < 36:
					ok = false
					break
			if ok:
				var aux = load("res://scenes/otros/Flor.tscn").instance()
				mundo.get_node("Objetos").add_child(aux)
				aux.position = pos
				mundo.QuitaNaturales()

func Incubador():
	if get_node("Imagen/Actividad").pressed and arboles >= alimentoTortuga:
		var mundo = get_tree().get_nodes_in_group("mundo")[0]
		var radio = randf() * get_node("Reserva/Coli").shape.radius + visionTortuga
		var tortis = get_tree().get_nodes_in_group("tortuga")
		var dis
		for t in tortis:
			dis = position.distance_to(t.position)
			if dis < radio:
				if mundo.LineaTierra(position, dis, position.direction_to(t.position)):
					return 0
		# crear tortuga nueva
		var aux = load("res://scenes/moviles/Tortuga.tscn").instance()
		mundo.get_node("Objetos").add_child(aux)
		aux.position = position + Vector2(randf(), randf())

func _on_Actividad_button_down():
	get_node("Imagen/Actividad/Sonido").play()

func _on_Huevo_timeout():
	get_node("Huevo").start(rand_range(180, 240))
	Incubador()

func _on_Florista_timeout():
	get_node("Florista").start(rand_range(25, 35))
	Flores()

func _on_TimeArea_timeout():
	ElArea()

func _on_Conteo_timeout():
	CuentaArboles()

func TieneAlgo():
	# evita error desde diamante
	return false

func PostSave(buffer):
	buffer.put_u8(1) # es una edificacion terminada
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
	var a = 1 if get_node("Imagen/Actividad").pressed else 0
	buffer.put_u8(a)

func Open(buffer):
	position.x = buffer.get_float()
	position.y = buffer.get_float()
	get_node("Imagen/Actividad").pressed = buffer.get_u8() != 0

func Destruir(humo=true):
	if humo:
		var mundo = get_tree().get_nodes_in_group("mundo")[0]
		mundo.HumoDemolision(self)
	queue_free()

func Deconstruir():
	var aux = load("res://scenes/andamios/C" + nombre + ".tscn").instance()
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.get_node("Objetos").add_child(aux)
	aux.position = position
	aux.ModoDemoler()
	Destruir(false)

extends Node2D

const asientos = 4 # maximos jugadores
const goles = 5 # puntos para ganar
const velocidad = 150.0 # maxima rapidez de la bola
const friccion = 0.99 # reduccion de rapidez de la bola
var bola = null # balon dinamico para acceso rapido
var canchas = [] # las posiciones de ambas canchas para acceso rapido
var play = true # si esta o no en partido
var limits = [] # las posiciones de los limites internos
var rapidez = 0 # velocidad actual de la bola
var direccion = Vector2(0, 0) # hacia donde va la bola
var sombra = null # huella de fondo
var nombre = "" # para demoler

func _ready():
	bola = get_node("Imagen/Salon/Sala/Balon")
	canchas.append(get_node("Imagen/Salon/Sala/Cancha1").position)
	canchas.append(get_node("Imagen/Salon/Sala/Cancha2").position)
	limits.append(get_node("Imagen/Salon/Sala1").position)
	limits.append(get_node("Imagen/Salon/Sala2").position)
	get_node("Logistica").start(rand_range(4, 8))
	Nombrar()
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.SonidoLen([get_node("Sonido")])

func Nombrar():
	if name.count("@") == 0:
		nombre = name
	else:
		nombre = name.split("@", false)[0]

func _process(delta):
	if play:
		Rebote(delta)
		Golazo(0)
		Golazo(1)
		Limite()

func Rebote(delta):
	rapidez *= friccion
	if rapidez < 10:
		direccion = Vector2(0, 0)
	var dir = Vector2(0, 0)
	var palos = Palitos()
	for p in palos:
		if p.distance_to(bola.position) < 10:
			dir += p.direction_to(bola.position)
	if dir.x != 0 or dir.y != 0:
		rapidez = velocidad
		direccion = (direccion + dir.normalized()).normalized()
	bola.position += direccion * rapidez * delta

func Limite():
	if bola.position.x < limits[0].x:
		bola.position.x = limits[0].x
		direccion.x *= -1
	elif bola.position.x > limits[1].x:
		bola.position.x = limits[1].x
		direccion.x *= -1
	if bola.position.y < limits[0].y:
		bola.position.y = limits[0].y
		direccion.y *= -1
	elif bola.position.y > limits[1].y:
		bola.position.y = limits[1].y
		direccion.y *= -1

func Golazo(v):
	if bola.position.distance_to(canchas[v]) < 10:
		play = false
		bola.position = Vector2(0, 0)
		rapidez = 0
		direccion = Vector2(0, 0)
		get_node("Imagen/Salon/Sala/Cancha" + str(v + 1) + "/Fiesta").emitting = true
		get_node("Sonido").play()
		var n = int(get_node("Imagen/Marcador" + str(v + 1)).text) + 1
		if n >= goles:
			get_node("Imagen/Marcador1").text = "0"
			get_node("Imagen/Marcador2").text = "0"
			get_node("Arbitro").start(9)
		else:
			get_node("Imagen/Marcador" + str(v + 1)).text = str(n)
			get_node("Arbitro").start(3)

func Jugadores():
	var tot = 0
	var cosas = get_node("Imagen/Salon/Sala").get_children()
	for c in cosas:
		if c.is_in_group("diamante"):
			tot += 1
	return tot

func Compannia():
	return Jugadores()

func Palitos():
	var tot = []
	var cosas = get_node("Imagen/Salon/Sala").get_children()
	for c in cosas:
		if c.is_in_group("diamante"):
			tot.append(c.position)
	return tot

func LosManes():
	var tot = []
	var cosas = get_node("Imagen/Salon/Sala").get_children()
	for c in cosas:
		if c.is_in_group("diamante"):
			tot.append(c)
	return tot

func WorkOk():
	if get_node("Imagen/Actividad").pressed:
		if Jugadores() < asientos:
			return get_node("Imagen/Salon/Sala")
	return null

func _on_Actividad_toggled(button_pressed):
	get_node("Imagen/Actividad/Sonido").play()
	if not button_pressed:
		Sacarlos()

func _on_PoneSombra_timeout():
	sombra = get_node("Imagen/Suelo")
	sombra.get_parent().remove_child(sombra)
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.get_node("Romboys").add_child(sombra)
	sombra.position = position

func Sacarlos():
	var cosas = get_node("Imagen/Salon/Sala").get_children()
	for c in cosas:
		if c.is_in_group("diamante"):
			c.LiberaEstado()

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
	if sombra != null:
		sombra.queue_free()
	Sacarlos()
	queue_free()

func _on_Arbitro_timeout():
	play = true

func Deconstruir():
	var aux = load("res://scenes/andamios/C" + nombre + ".tscn").instance()
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.get_node("Objetos").add_child(aux)
	aux.position = position
	aux.ModoDemoler()
	Destruir(false)

func _on_Logistica_timeout():
	get_node("Logistica").start(rand_range(4, 8))
	if Jugadores() != 0:
		get_node("Anima").play("Go", -1, 0.9)
	else:
		get_node("Anima").play("RESET")

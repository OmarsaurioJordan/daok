extends Node2D

const debug = false
const minimaPoblacion = 66 # poblacion para empezar a invadir
const radioLlegadas = 400.0 # radio a calles alrededor del punto para aterrizar
const propoDesfase = 1.1 # proporcion maxima de veces que se superan las viviendas
const minimaInva = 3 # cantidad minima de entes invasores
const limitInva = 0.7 # exponente para reducir cantidad invasores a mas poblacion
const maxCaos = 10 # total de guinxu que llegan al invocarlos el usuario

var guinxus = [] # los soldadillos que llevara a invadir
var poblaIni = 0 # la catidad de diamantes antes de la invasion
var muertes = 0 # cantidad de diamantes abatidos
var totalGuinxu = 0 # cantidad de guinxu enviados
var mundo = null # para acceso rapido al mundo
var esMortal = false # si debe ir hasta las ultimas consecuencias

func _ready():
	mundo = get_tree().get_nodes_in_group("mundo")[0]
	get_node("Comienza").start(randf() * mundo.dia_wait_time)
	get_node("Termina").start(mundo.dia_wait_time)
	get_node("Termina").stop()

func Invasion():
	get_node("Comienza").stop()
	esMortal = true
	# calcular la cantidad de guinxu que invadiran
	poblaIni = get_tree().get_nodes_in_group("diamante").size()
	totalGuinxu = maxCaos
	# hallar una posicion al azar
	PosAzar()
	var punto = PuntoLlegada()
	if punto.x == 0 and punto.y == 0:
		queue_free()
		return 0
	PuntosAterrizaje(punto)
	# finalizar la creacion
	get_node("Termina").start()
	get_node("Chekeo").start()
	mundo.Log("invoke invaden " + str(totalGuinxu) + " Guinxu")
	mundo.Comprando("caos")
	get_node("SguinxuInvasion").play()

func _on_Comienza_timeout():
	esMortal = mundo.Apocalipsis()
	# ver si cumple con momento
	if not mundo.EsApocalipsis(0):
		queue_free()
		return 0
	# calcular la cantidad de guinxu que invadiran
	poblaIni = get_tree().get_nodes_in_group("diamante").size()
	if poblaIni >= minimaPoblacion or (esMortal and poblaIni > 0):
		var ppmns = float(poblaIni) / mundo.GetPoblacion()
		if ppmns >= propoDesfase or esMortal:
			var g = max(0, (ppmns - 1) * mundo.GetPoblacion())
			var z = rand_range(-minimaInva, minimaInva)
			totalGuinxu = clamp(round(pow(g, limitInva) + z), minimaInva, maxCaos)
	if totalGuinxu == 0:
		queue_free()
		return 0
	# hallar una posicion al azar
	PosAzar()
	var punto = PuntoLlegada()
	if punto.x == 0 and punto.y == 0:
		queue_free()
		return 0
	PuntosAterrizaje(punto)
	# finalizar la creacion
	get_node("Termina").start()
	get_node("Chekeo").start()
	mundo.Log("invaden " + str(totalGuinxu) + " Guinxu")
	mundo.LaMedalla(0)
	get_node("SguinxuInvasion").play()
	if debug:
		print("guinxus: " + str(totalGuinxu))

func PosAzar():
	var limits = mundo.get_node("Agua").rect_size
	if randf() < 0.5:
		position.x = 0 if randf() < 0.5 else limits.x
		position.y = randf() * limits.y
	else:
		position.y = 0 if randf() < 0.5 else limits.y
		position.x = randf() * limits.x

func PuntoLlegada():
	var punto = Vector2(0, 0)
	var edis = get_tree().get_nodes_in_group("ediffice")
	var tabla = []
	for e in edis:
		tabla.append(0)
		for r in edis:
			tabla[-1] += e.position.distance_to(r.position)
	var minValu = -1
	var i
	for _s in range(ceil(edis.size() * 0.25)):
		i = randi() % edis.size()
		if tabla[i] < minValu or minValu == -1:
			minValu = tabla[i]
			punto = edis[i].position
	return punto

func PuntosAterrizaje(punto):
	var llegadas = []
	var cll = get_tree().get_nodes_in_group("calle")
	for c in cll:
		if punto.distance_to(c.position) < radioLlegadas:
			llegadas.append(c)
	if llegadas .empty():
		queue_free()
		return 0
	# crear a los guinxus
	var ente = load("res://scenes/moviles/Guinxu.tscn")
	for _g in range(totalGuinxu):
		guinxus.append(ente.instance())
		mundo.get_node("Objetos").add_child(guinxus[-1])
		guinxus[-1].position = position + Vector2(randf(), randf())
		guinxus[-1].Volando(llegadas[randi() % llegadas.size()].global_position, position)
		guinxus[-1].madre = self

func Save(buffer):
	buffer.put_float(position.x)
	buffer.put_float(position.y)
	buffer.put_u16(poblaIni)
	buffer.put_u16(muertes)
	buffer.put_u8(totalGuinxu)
	var m = 1 if esMortal else 0
	buffer.put_u8(m)
	buffer.put_float(get_node("Comienza").time_left)
	buffer.put_float(get_node("Termina").time_left)

func Open(buffer):
	position.x = buffer.get_float()
	position.y = buffer.get_float()
	poblaIni = buffer.get_u16()
	muertes = buffer.get_u16()
	totalGuinxu = buffer.get_u8()
	esMortal = buffer.get_u8() != 0
	var lefT = buffer.get_float()
	var lefF = buffer.get_float()
	if lefT != 0:
		get_node("Comienza").start(lefT)
	elif lefF != 0:
		get_node("Termina").start(lefF)

func _on_Termina_timeout():
	var ok = false
	for g in guinxus:
		if is_instance_valid(g):
			g.Volarse()
			ok = true
	if ok:
		get_node("SguinxuRetirada").play()

func _on_Chekeo_timeout():
	var pp = get_tree().get_nodes_in_group("diamante").size()
	if pp == 0:
		_on_Termina_timeout()
	elif pp < poblaIni * 0.5 and not esMortal:
		_on_Termina_timeout()
	if guinxus.empty():
		queue_free()
	else:
		for g in range(guinxus.size() - 1, -1, -1):
			if not is_instance_valid(guinxus[g]):
				guinxus.remove(g)

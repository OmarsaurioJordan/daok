extends Node2D

const velociVuelo = 150.0 # rapidez al andar por el aire en globo
const upDownVuelo = [50.0, 75.0] # velocidad ascenso y descenso
const borracho = 0.17 # unos 10 grados en radianes, para dar tumbos al andar
const disPnt = 24.0 # distancia para considerar que llego a un punto
const disEnte = 40.0 # distancia para considerar cercania a personaje o cosa
const radioExplo = 130.0 # circulo donde la explosion mata moviles
const paramErrar = [0.333, 0.666, 90] # al errar: probabi inv moverse, detenerse, giro max
const sEsquive = [2, 4] # reloj ciclo para esquive social
const sErrar = [1, 5] # reloj ciclo para andar al azar
const sAtasco = [10, 15] # reloj ciclo evitar atascos al andar
const sArmarse = [20, 40] # tiempo para ponerse la bomba
const sExplo = [10, 20] # tiempo para explotar

enum {tipSuelo, tipAire}

var vision = 300.0 # distancia de vision del ente
var velocidad = 100.0 # rapidez al andar por suelo y su bonus de mejora
var tipo = tipSuelo # modo de desplazamiento o anclaje a punto
var colision = [[], [], []] # 0:solido, 1:movil, 2:aire
var mundo = null # nodo maestro para asceso rapido
var limirec = Vector2(0, 0) # limites del marco del mundo
var anterior = Vector2(0, 0) # posicion previa para mantenerse en tierra
var mover = false # true si esta en movimiento al errar
var direccion = Vector2(0, 0) # direccion al errar
var esqSocio = true # para evitar embotellamiento, colision intermitente
var aterrizaje = Vector2(0, 0) # coordenadas de llegada en globo
var altura = 0 # 0:subiendo, 1:volando, 2:bajando
var aniPaso = false # hacer cambio de animacion
var meta = [null, null] # nodo puerta a donde ir: calle y build
var next = [null, null] # nodo proximo para llegar a meta: calle y build
var sombrita = null # sombra del personaje
var antiAtascoPos = Vector2(0, 0) # para evitar estancamiento
var buscaActiva = true # para hacer intermitente la labor de busqueda, optimizar

func _ready():
	mundo = get_tree().get_nodes_in_group("mundo")[0]
	sombrita = mundo.lasombrita.instance()
	mundo.get_node("Sombras").add_child(sombrita)
	limirec = mundo.get_node("Agua").rect_size
	get_node("EsquiveSocial").start(rand_range(sEsquive[0], sEsquive[1]))
	get_node("Errar").start(rand_range(sErrar[0], sErrar[1]))
	get_node("AntiAtasco").start(rand_range(sAtasco[0], sAtasco[1]))
	get_node("Boom").start(rand_range(sArmarse[0], sArmarse[1]))
	get_node("Anima").play("idle")
	CambiaTipo(tipSuelo)
	mundo.SonidoLen([get_node("SPoneBomba"), get_node("SHola"), get_node("SBomba")])

func _process(delta):
	match tipo:
		tipSuelo:
			anterior = position
			var ok = not Rebote(0, delta)
			if ok and esqSocio:
				ok = not Rebote(1, delta)
			if ok:
				if NavErrar(delta, "ediffice"):
					meta[1] = null
			Limites(delta)
		tipAire:
			if altura == 1:
				if not Rebote(2, delta):
					Volar(delta)
				Limites(delta)
			else:
				Volar(delta)

func Rebote(ind, delta):
	var rebote = Vector2(0, 0)
	for c in colision[ind]:
		rebote += c.position.direction_to(position)
	if rebote.x != 0 or rebote.y != 0:
		direccion = Vector2(1, 0).rotated(randf() * 2 * PI)
		position += rebote.normalized() * velocidad * delta
		return true
	return false

func Limites(delta):
	var ant = position
	position.x = clamp(position.x, 0, limirec.x)
	position.y = clamp(position.y, 0, limirec.y)
	if tipo == tipSuelo:
		if not mundo.EnTierra(position):
			position = anterior + Vector2(0, velocidad * delta).rotated(randf() * 2 * PI)
			if not mundo.EnTierra(position):
				position = anterior
	if ant.x != position.x or ant.y != position.y:
		direccion = Vector2(1, 0).rotated(randf() * 2 * PI)
	#animaciones
	if aniPaso:
		if anterior.x == position.x or anterior.y == position.y:
			get_node("Anima").play("idle", -1, 1)
			aniPaso = false
	else:
		if anterior.x != position.x or anterior.y != position.y:
			get_node("Anima").play("walk", -1, 3)
			aniPaso = true
	# muevesombra
	sombrita.position = position

func Volar(delta):
	if altura == 0:
		get_node("Imagen/Aire").position.y -= upDownVuelo[0] * delta
		if get_node("Imagen/Aire").position.y <= get_node("Imagen/Altura").position.y:
			get_node("Imagen/Aire").position.y = get_node("Imagen/Altura").position.y
			altura = 1
	elif altura == 2:
		get_node("Imagen/Aire").position.y += upDownVuelo[1] * delta
		if get_node("Imagen/Aire").position.y >= 0:
			get_node("Imagen/Aire").position.y = 0
			anterior = aterrizaje
			CambiaTipo(tipSuelo)
			next[0] = null
	else:
		var dis = position.distance_to(aterrizaje)
		var dir = position.direction_to(aterrizaje)
		if direccion.x > 0:
			position += (dir.rotated(randf() * borracho * 2) * velociVuelo * delta).clamped(dis)
		else:
			position += (dir.rotated(randf() * -borracho * 2) * velociVuelo * delta).clamped(dis)
		if dis < disPnt:
			altura = 2

func BuscaBuildOk(destino, ind):
	# devuelve 0:nada, 1:fallo
	if buscaActiva:
		buscaActiva = false
		return 0
	var candidatos = get_tree().get_nodes_in_group(destino)
	# retorna fallo buscando candidatos
	if candidatos.empty():
		return 1
	else:
		# elegir candidato al azar
		meta[ind] = candidatos[randi() % candidatos.size()].get_node("Puerta")
		next[ind] = null
	return 0

func Navegar(delta, destino):
	# devuelve 0:nada, 1:fallo, 2:llego, 3:andar
	var t = 0 if destino == "calle" else 1
	if meta[t] == null:
		# buscar lugar a donde ir
		return BuscaBuildOk(destino, t)
	elif is_instance_valid(meta[t]):
		if next[t] == null:
			var cll = get_tree().get_nodes_in_group("calle")
			var minDis = vision * 2.0
			var ray
			var dis
			var nxt
			for c in cll:
				dis = position.distance_to(c.position)
				if dis < minDis:
					nxt = c.get_node("Puerta").Proximo(meta[t])
					if nxt[0] != null:
						if mundo.LineaTierra(position, dis, position.direction_to(c.position)):
							ray = c.get_node("Puerta/Ray")
							ray.cast_to = c.position - position
							ray.force_raycast_update()
							if not ray.is_colliding():
								minDis = dis
								next[t] = c.get_node("Puerta")
			if next[t] == null:
				meta[t] = null
				return 1
		elif is_instance_valid(next[t]):
			var dir
			if direccion.x > 0:
				dir = position.direction_to(next[t].global_position).rotated(randf() * borracho)
			else:
				dir = position.direction_to(next[t].global_position).rotated(randf() * -borracho)
			position += dir * velocidad * delta
			if position.distance_to(next[t].global_position) < disPnt:
				if next[t] == meta[t]:
					next[t] = null
					return 2
				else:
					var nxt = next[t].Proximo(meta[t])
					next[t] = nxt[0]
					if nxt[1] == 2:
						aterrizaje = next[t].global_position
						CambiaTipo(tipAire)
			return 3
		else:
			next[t] = null
	else:
		meta[t] = null
	return 0

func NavErrar(delta, destino):
	var r = Navegar(delta, destino)
	if r == 2:
		return true
	elif r != 3:
		if destino != "calle":
			if Navegar(delta, "calle") == 2:
				meta[0] = null
		else:
			Errar(delta)
	return false

func Errar(delta):
	if mover:
		position += direccion * velocidad * delta

func _on_Movil_area_entered(area):
	var nn = area.name
	if nn == "Movil":
		colision[1].append(area.get_parent())
	elif nn == "Solido":
		colision[0].append(area.get_parent())

func _on_Movil_area_exited(area):
	var nn = area.name
	if nn == "Movil":
		colision[1].erase(area.get_parent())
	elif nn == "Solido":
		colision[0].erase(area.get_parent())

func _on_Aereo_area_entered(area):
	colision[2].append(area.get_parent())

func _on_Aereo_area_exited(area):
	colision[2].erase(area.get_parent())

func _on_EsquiveSocial_timeout():
	get_node("EsquiveSocial").start(rand_range(sEsquive[0], sEsquive[1]))
	esqSocio = not esqSocio
	buscaActiva = true

func _on_AntiAtasco_timeout():
	get_node("AntiAtasco").start(rand_range(sAtasco[0], sAtasco[1]))
	if position.distance_to(antiAtascoPos) < disEnte and tipo == tipSuelo:
		meta = [null, null]
		next = [null, null]
	antiAtascoPos = position

func _on_Errar_timeout():
	get_node("Errar").start(rand_range(sErrar[0], sErrar[1]))
	if mover:
		mover = randf() > paramErrar[0]
		direccion = direccion.rotated(rand_range(-paramErrar[2], paramErrar[2]))
	else:
		mover = randf() > paramErrar[1]
		direccion = Vector2(1, 0).rotated(randf() * 2 * PI)

func CambiaTipo(ind):
	tipo = ind
	if ind == tipAire:
		get_node("Imagen/Suelo").visible = false
		get_node("Imagen/Aire").visible = true
		get_node("Movil").monitorable = false
		get_node("Movil").monitoring = false
		get_node("Aereo").monitorable = true
		get_node("Aereo").monitoring = true
		colision[0] = []
		colision[1] = []
		altura = 0
	else:
		get_node("Imagen/Suelo").visible = true
		get_node("Imagen/Aire").visible = false
		get_node("Aereo").monitorable = false
		get_node("Aereo").monitoring = false
		get_node("Movil").monitorable = true
		get_node("Movil").monitoring = true
		colision[2] = []

func Destructor(cadaver=true):
	if cadaver:
		var aux = load("res://scenes/otros/DieDiamante.tscn").instance()
		mundo.get_node("Objetos").add_child(aux)
		aux.position = position
		aux.body.frame = 4
		aux.Quejido()
	sombrita.queue_free()
	queue_free()

func Golpeado():
	Destructor()

func Save(buffer):
	buffer.put_float(position.x)
	buffer.put_float(position.y)
	buffer.put_u16(vision)
	buffer.put_u16(velocidad)
	var b = 1 if get_node("Imagen/Suelo/Cuerpo/Objeto").visible else 0
	buffer.put_u8(b)
	buffer.put_u8(tipo)
	if tipo == tipAire:
		buffer.put_float(aterrizaje.x)
		buffer.put_float(aterrizaje.y)

func Open(buffer):
	position.x = buffer.get_float()
	position.y = buffer.get_float()
	vision = float(buffer.get_u16())
	velocidad = float(buffer.get_u16())
	get_node("Imagen/Suelo/Cuerpo/Objeto").visible = buffer.get_u8() != 0
	tipo = buffer.get_u8()
	if tipo == tipAire:
		CambiaTipo(tipAire)
		aterrizaje.x = buffer.get_float()
		aterrizaje.y = buffer.get_float()
		get_node("Imagen/Aire").position.y = get_node("Imagen/Altura").position.y
		altura = 1

func _on_Boom_timeout():
	if not get_node("Imagen/Suelo/Cuerpo/Objeto").visible:
		get_node("Imagen/Suelo/Cuerpo/Objeto").visible = true
		get_node("Imagen/Aire/Cuerpo/Objeto").visible = true
		get_node("SBomba").play()
		get_node("Boom").start(rand_range(sExplo[0], sExplo[1]))
	elif tipo == tipAire:
		get_node("Boom").start(rand_range(sExplo[0], sExplo[1]) * 0.25)
	else:
		get_node("SPoneBomba").play()

func _on_SPoneBomba_finished():
	var explo = load("res://scenes/otros/Explosion.tscn")
	var pExplo = get_node("Fin").get_children()
	pExplo.shuffle()
	var aux
	for e in pExplo:
		aux = explo.instance()
		mundo.get_node("Objetos").add_child(aux)
		aux.position = e.global_position
		if mundo.EnTierra(e.global_position):
			aux = mundo.manchis[0].instance()
			mundo.get_node("Manchas").add_child(aux)
			aux.position = e.global_position
	mundo.Explosion(position, radioExplo, true)
	mundo.LaMedalla(2)
	mundo.Log("explota un JasperDev")

extends Node2D

const vision = 300.0 # distancia de vision del ente
const velocidad = 100.0 # rapidez al andar por suelo
const velociVuelo = 150.0 # rapidez al andar por el aire en globo
const upDownVuelo = [50.0, 75.0] # velocidad ascenso y descenso
const rangoPelea = [0.5, 0.75] # porcentaje de radio de vision donde mantenerse en pelea
const borracho = 0.17 # unos 10 grados en radianes, para dar tumbos al andar
const bisco = 0.17 # radianes de desfase aleatorio al disparar
const disPnt = 24.0 # distancia para considerar que llego a un punto
const disEnte = 40.0 # distancia para considerar cercania a personaje o cosa
const microRevision = 0.1 # probabilidad baja para calculos lentos
const paramErrar = [0.333, 0.666, 90.0] # al errar: probabi inv moverse, detenerse, giro max
const escudo = 0.4 # resistencia a impacto de proyectiles
const sEsquive = [2, 4] # reloj ciclo para esquive social
const sErrar = [1, 5] # reloj ciclo para andar al azar
const sDispara = [3, 4] # tiempo ciclo rafaga de disparos, cadencia
const sCorrec = [10, 20] # reloj ciclico para re dirigirse hacia calle o edificio

enum {tipSuelo, tipAire}

var tipo = tipSuelo # modo de desplazamiento o anclaje a punto
var colision = [[], [], [], []] # 0:solido, 1:movil, 2:aire, 3:diamante
var mundo = null # nodo maestro para asceso rapido
var limirec = Vector2(0, 0) # limites del marco del mundo
var anterior = Vector2(0, 0) # posicion previa para mantenerse en tierra
var mover = false # true si esta en movimiento al errar
var direccion = Vector2(0, 0) # direccion al errar
var esqSocio = true # para evitar embotellamiento, colision intermitente
var aterrizaje = Vector2(0, 0) # coordenadas de llegada en globo
var altura = 0 # 0:subiendo, 1:volando, 2:bajando
var aniPaso = false # hacer cambio de animacion
var sombrita = null # sombra del personaje
var antiAtascoPos = Vector2(0, 0) # para evitar estancamiento
var laPartida = Vector2(0, 0) # punto donde se inicia y finaliza
var largarse = false # true cuando sea hora de ir a la partida
var madre = null # la nave nodriza de donde salio

func _ready():
	mundo = get_tree().get_nodes_in_group("mundo")[0]
	sombrita = mundo.lasombrita.instance()
	mundo.get_node("Sombras").add_child(sombrita)
	limirec = mundo.get_node("Agua").rect_size
	get_node("EsquiveSocial").start(rand_range(sEsquive[0], sEsquive[1]))
	get_node("Errar").start(rand_range(sErrar[0], sErrar[1]))
	get_node("Disparador").start(rand_range(sDispara[0], sDispara[1]))
	get_node("Correccion").start(rand_range(sCorrec[0], sCorrec[1]))
	get_node("Anima").play("idle")
	CambiaTipo(tipSuelo)
	get_node("Vigia/Coli").shape.radius = vision
	mundo.SonidoLen([get_node("SCorona"), get_node("SHola")])

func _process(delta):
	match tipo:
		tipSuelo:
			anterior = position
			var ok = not Rebote(0, delta)
			if ok and esqSocio:
				ok = not Rebote(1, delta)
			if ok and not colision[3].empty():
				ok = not Perseguir(delta)
			if ok:
				Errar(delta)
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

func Perseguir(delta):
	var ray = get_node("Ray")
	var minDis = [vision, vision]
	var minMan = [null, null]
	var dis
	var i
	for c in colision[3]:
		if c.tipo != 0:
			continue
		i = 0 if c.Armado() else 1
		dis = position.distance_to(c.position)
		if dis < minDis[i]:
			ray.cast_to = c.position - position
			ray.force_raycast_update()
			if not ray.is_colliding():
				minDis[i] = dis
				minMan[i] = c
	for m in minMan:
		if m != null:
			dis = minDis[0]
			if dis > vision * rangoPelea[1]:
				var dir = position.direction_to(m.position)
				position += dir * velocidad * delta
				direccion = Vector2(1, 0).rotated(randf() * 2 * PI)
			elif dis < vision * rangoPelea[0]:
				var dir = position.direction_to(m.position)
				position -= dir.rotated(PI * 0.5 * direccion.x) * velocidad * delta
			else:
				position += direccion * velocidad * delta
			return true
		minDis.remove(0)
	return false

func SetCorona(esVisible):
	get_node("Imagen/Suelo/Cuerpo/Corona").visible = esVisible
	get_node("Imagen/Aire/Cuerpo/Globo/Corona").visible = esVisible
	# contar muertes en nodriza
	if esVisible:
		var ndz = get_tree().get_nodes_in_group("nodriza")
		for n in ndz:
			if n.guinxus.has(self):
				n.muertes += 1
				break

func GetCorona():
	return get_node("Imagen/Suelo/Cuerpo/Corona").visible

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
	# 0:subiendo, 1:volando, 2:bajando
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
			get_node("SHola").play()
	else:
		var dis = position.distance_to(aterrizaje)
		var dir = position.direction_to(aterrizaje)
		if direccion.x > 0:
			position += (dir.rotated(randf() * borracho * 2) * velociVuelo * delta).clamped(dis)
		else:
			position += (dir.rotated(randf() * -borracho * 2) * velociVuelo * delta).clamped(dis)
		if dis < disPnt:
			if largarse:
				Destructor(false)
			else:
				altura = 2

func Volando(llegada, partida):
	CambiaTipo(tipAire)
	aterrizaje = llegada
	laPartida = partida
	get_node("Imagen/Aire").position.y = get_node("Imagen/Altura").position.y
	altura = 1

func Volarse():
	if not largarse:
		largarse = true
		CambiaTipo(tipAire)
		aterrizaje = laPartida

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

func _on_Errar_timeout():
	get_node("Errar").start(rand_range(sErrar[0], sErrar[1]))
	if mover:
		mover = randf() > paramErrar[0]
		direccion = direccion.rotated(rand_range(-paramErrar[2], paramErrar[2]))
	else:
		mover = randf() > paramErrar[1]
		direccion = Vector2(1, 0).rotated(randf() * 2 * PI)

func CambiaTipo(ind):
	var ant = tipo
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
	# limpiar enemigos vistos
	if ant == tipSuelo and tipo != ant:
		get_node("Vigia").monitoring = false
		colision[3] = []
	elif ant != tipSuelo and tipo == tipSuelo:
		get_node("Vigia").monitoring = true

func Destructor(cadaver=true):
	if cadaver:
		var aux = load("res://scenes/otros/DieDiamante.tscn").instance()
		mundo.get_node("Objetos").add_child(aux)
		aux.position = position
		aux.body.frame = 8
		aux.body.get_node("Corona").visible = GetCorona()
		aux.Quejido()
	sombrita.queue_free()
	queue_free()

func Golpeado():
	if randf() > escudo:
		Destructor()
	else:
		mover = true

func _on_Disparador_timeout():
	get_node("Disparador").start(rand_range(sDispara[0], sDispara[1]))
	if tipo != tipSuelo:
		return 0
	var ray = get_node("Ray")
	# guinxu, titan, jasperdev, sdev
	var minDis = [vision, vision]
	var minMan = [null, null]
	var dis
	var i
	for c in colision[3]:
		if c.tipo != 0:
			continue
		i = 0 if c.Armado() else 1
		dis = position.distance_to(c.position)
		if dis < minDis[i]:
			ray.cast_to = c.position - position
			ray.force_raycast_update()
			if not ray.is_colliding():
				minDis[i] = dis
				minMan[i] = c
	for m in minMan:
		if m != null:
			var aux = mundo.UnProyectil()
			aux.direccion = position.direction_to(m.position)
			aux.direccion = aux.direccion.rotated(rand_range(-bisco, bisco))
			aux.position = position + aux.direccion * 8.0
			aux.Maligno(self)
			break

func Save(buffer):
	buffer.put_float(position.x)
	buffer.put_float(position.y)
	buffer.put_float(laPartida.x)
	buffer.put_float(laPartida.y)
	var g = 1 if largarse else 0
	buffer.put_u8(g)
	buffer.put_u8(tipo)
	if tipo == tipAire:
		buffer.put_float(aterrizaje.x)
		buffer.put_float(aterrizaje.y)
	if madre != null and is_instance_valid(madre):
		buffer.put_u8(1)
		buffer.put_float(madre.position.x)
		buffer.put_float(madre.position.y)
	else:
		buffer.put_u8(0)

func Open(buffer):
	position.x = buffer.get_float()
	position.y = buffer.get_float()
	laPartida.x = buffer.get_float()
	laPartida.y = buffer.get_float()
	largarse = buffer.get_u8() != 0
	tipo = buffer.get_u8()
	if tipo == tipAire:
		CambiaTipo(tipAire)
		aterrizaje.x = buffer.get_float()
		aterrizaje.y = buffer.get_float()
		get_node("Imagen/Aire").position.y = get_node("Imagen/Altura").position.y
		altura = 1
	if buffer.get_u8() != 0:
		var madrx = get_tree().get_nodes_in_group("nodriza")
		var posMa = Vector2(0, 0)
		posMa.x = buffer.get_float()
		posMa.y = buffer.get_float()
		for m in madrx:
			if m.position.x == posMa.x and m.position.y == posMa.y:
				madre = m
				madre.guinxus.append(self)
				break

func _on_Vigia_area_entered(area):
	colision[3].append(area.get_parent())

func _on_Vigia_area_exited(area):
	colision[3].erase(area.get_parent())

func _on_Correccion_timeout():
	get_node("Correccion").start(rand_range(sCorrec[0], sCorrec[1]))
	if tipo != tipSuelo:
		return 0
	var quebusca = "ediffice" if randf() < 0.5 else "calle"
	var cosas = get_tree().get_nodes_in_group(quebusca)
	var ray = get_node("Ray")
	var minCosa = null
	var minDis = vision * 2.0
	var dis
	var dir
	var cc
	var noEdi = quebusca != "ediffice"
	for c in cosas:
		cc = c if noEdi else c.get_node("Puerta")
		dis = position.distance_to(cc.global_position)
		if dis < minDis:
			dir = position.direction_to(cc.global_position)
			if mundo.LineaTierra(position, dis, dir):
				ray.cast_to = cc.global_position - position
				ray.force_raycast_update()
				if not ray.is_colliding():
					minDis = dis
					minCosa = cc
	if minCosa != null:
		mover = true
		get_node("Errar").start(sErrar[1])
		direccion = position.direction_to(cc.global_position)

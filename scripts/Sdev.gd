extends Node2D

const vision = 300.0 # distancia de vision del ente
const velocidad = 100.0 # rapidez al andar por suelo y su bonus de mejora
const disPnt = 24.0 # distancia para considerar que llego a un punto
const disEnte = 40.0 # distancia para considerar cercania a personaje o cosa
const paramErrar = [0.333, 0.666, 90.0] # al errar: probabi inv moverse, detenerse, giro max
const borracho = 0.17 # unos 10 grados en radianes, para dar tumbos al andar
const disMele = 100.0 # distancia ataque cuerpo a cuerpo
const bisco = 0.17 # radianes de desfase aleatorio al disparar
const dialogando = 0.5 # probabilidad de dialogo
const sEsquive = [2, 4] # reloj ciclo para esquive social
const sErrar = [1, 5] # reloj ciclo para andar al azar
const sAtasco = [10, 15] # reloj ciclo evitar atascos al andar
const sBuscador = [3, 5] # reloj ciclo buscar cosas o entes con la vista
const sDispara = [3, 4] # tiempo ciclo rafaga de disparos, cadencia
const tipo = 0 # modo de desplazamiento por el suelo

enum {objNull, objCopa, objVacuna, objBolsa, objCaja, objBomba, objCartel, objMina,
objLibro, objEscudoPro, objEscudo, objRojo, objGuaro}

var colision = [[], [], []] # 0:solido, 1:movil, 2:enemigo
var mundo = null # nodo maestro para asceso rapido
var limirec = Vector2(0, 0) # limites del marco del mundo
var anterior = Vector2(0, 0) # posicion previa para mantenerse en tierra
var mover = false # true si esta en movimiento al errar
var direccion = Vector2(0, 0) # direccion al errar
var esqSocio = true # para evitar embotellamiento, colision intermitente
var aniPaso = false # hacer cambio de animacion
var meta = null # nodo puerta a donde ir
var next = null # nodo proximo para llegar a meta
var sombrita = null # sombra del personaje
var antiAtascoPos = Vector2(0, 0) # para evitar estancamiento
var buscaActiva = true # para hacer intermitente la labor de busqueda, optimizar
var retirada = false # para saber si vuelve a la cueva y desaparece
var cueva = null # lugar a donde meterse o llevar cosas, puede cambiar
var miCueva = null # el lugar de donde salio, para conteos

func _ready():
	mundo = get_tree().get_nodes_in_group("mundo")[0]
	sombrita = mundo.lasombrita.instance()
	mundo.get_node("Sombras").add_child(sombrita)
	limirec = mundo.get_node("Agua").rect_size
	get_node("EsquiveSocial").start(rand_range(sEsquive[0], sEsquive[1]))
	get_node("Errar").start(rand_range(sErrar[0], sErrar[1]))
	get_node("AntiAtasco").start(rand_range(sAtasco[0], sAtasco[1]))
	get_node("Buscador").start(rand_range(sBuscador[0], sBuscador[1]))
	get_node("Disparador").start(rand_range(sDispara[0], sDispara[1]))
	get_node("Anima").play("idle")
	get_node("Vigia/Coli").shape.radius = disMele * 2.0
	mundo.SonidoLen([get_node("SHola"), get_node("SEncaleta"),
	get_node("SRobo"), get_node("SCharla")])

func _process(delta):
	anterior = position
	var ok = not Rebote(0, delta)
	if ok and esqSocio:
		ok = not Rebote(1, delta)
	if ok:
		if retirada or GetObj() != objNull:
			if cueva == null:
				if NavErrar(delta, "calle"):
					meta = null
			elif not is_instance_valid(cueva):
				cueva = null
			else:
				position += position.direction_to(cueva.position) * velocidad * delta
				var dis = position.distance_to(cueva.position)
				if dis < disEnte:
					if retirada:
						Destructor(false)
					else:
						miCueva.robos += 1
						SetObj(objNull)
						get_node("SEncaleta").play()
		else:
			if NavErrar(delta, "robable"):
				var robo = meta.get_parent().Robar()
				var okay = true
				match robo:
					"copa":
						SetObj(objCopa)
					"bolsa":
						SetObj(objBolsa)
					"guaro":
						SetObj(objGuaro)
					"libro":
						SetObj(objLibro)
					"caja":
						SetObj(objCaja)
					"vacuna":
						SetObj(objVacuna)
					"balas":
						SetObj(objRojo)
					"mina":
						SetObj(objMina)
					_:
						okay = false
				if okay:
					get_node("SRobo").play()
				meta = null
	Limites(delta)

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

func GetObj():
	return get_node("Imagen/Suelo/Cuerpo/Objeto").frame

func SetObj(ind):
	get_node("Imagen/Suelo/Cuerpo/Objeto").frame = ind

func BuscaBuildOk(destino):
	# devuelve 0:nada, 1:fallo
	if buscaActiva:
		buscaActiva = false
		return 0
	var candidatos = get_tree().get_nodes_in_group(destino)
	# retorna fallo buscando candidatos
	if candidatos.empty():
		return 1
	else:
		# aumentar las probabilidades de saquear puntos clave
		for i in range(candidatos.size() - 1, -1, -1):
			if not candidatos[i].get_node("Imagen/Actividad").pressed:
				candidatos.remove(i)
			elif candidatos[i].is_in_group("ediOcio"):
				candidatos.append(candidatos[i])
				candidatos.append(candidatos[i])
				candidatos.append(candidatos[i])
				candidatos.append(candidatos[i])
			elif candidatos[i].is_in_group("ediTrabajo"):
				candidatos.append(candidatos[i])
				candidatos.append(candidatos[i])
			elif candidatos[i].is_in_group("ediCultivo"):
				candidatos.append(candidatos[i])
		# elegir candidato al azar
		meta = candidatos[randi() % candidatos.size()].get_node("Puerta")
		next = null
	return 0

func Navegar(delta, destino):
	# devuelve 0:nada, 1:fallo, 2:llego, 3:andar
	if meta == null:
		# buscar lugar a donde ir
		return BuscaBuildOk(destino)
	elif is_instance_valid(meta):
		if next == null:
			var cll = get_tree().get_nodes_in_group("calle")
			var minDis = vision * 3
			var ray
			var dis
			var nxt
			for c in cll:
				dis = position.distance_to(c.position)
				if dis < minDis:
					nxt = c.get_node("Puerta").Proximo(meta)
					if nxt[0] != null:
						if mundo.LineaTierra(position, dis, position.direction_to(c.position)):
							ray = c.get_node("Puerta/Ray")
							ray.cast_to = c.position - position
							ray.force_raycast_update()
							if not ray.is_colliding():
								minDis = dis
								next = c.get_node("Puerta")
			if next == null:
				meta = null
				return 1
		elif is_instance_valid(next):
			var dir
			if direccion.x > 0:
				dir = position.direction_to(next.global_position).rotated(randf() * borracho)
			else:
				dir = position.direction_to(next.global_position).rotated(randf() * -borracho)
			position += dir * velocidad * delta
			if position.distance_to(next.global_position) < disPnt:
				if next == meta:
					next = null
					return 2
				else:
					var nxt = next.Proximo(meta)
					if nxt[1] == 2:
						meta = null
						next = null
						return 1
					else:
						next = nxt[0]
			return 3
		else:
			next = null
	else:
		meta = null
	return 0

func NavErrar(delta, destino):
	var r = Navegar(delta, destino)
	if r == 2:
		return true
	elif r != 3:
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

func _on_EsquiveSocial_timeout():
	get_node("EsquiveSocial").start(rand_range(sEsquive[0], sEsquive[1]))
	esqSocio = not esqSocio
	buscaActiva = true

func _on_AntiAtasco_timeout():
	get_node("AntiAtasco").start(rand_range(sAtasco[0], sAtasco[1]))
	if position.distance_to(antiAtascoPos) < disEnte:
		meta = null
		next = null
	antiAtascoPos = position

func _on_Errar_timeout():
	get_node("Errar").start(rand_range(sErrar[0], sErrar[1]))
	if mover:
		mover = randf() > paramErrar[0]
		direccion = direccion.rotated(rand_range(-paramErrar[2], paramErrar[2]))
	else:
		mover = randf() > paramErrar[1]
		direccion = Vector2(1, 0).rotated(randf() * 2 * PI)
	# mostrar dialogo
	var antH = get_node("Imagen/Suelo/Cuerpo/Dialogo").visible
	var h = false
	if randf() < dialogando:
		for c in colision[2]:
			if c.tipo != 0:
				continue
			if c.EsLoro():
				h = true
				break
	get_node("Imagen/Suelo/Cuerpo/Dialogo").visible = h
	if not antH and h:
		get_node("SCharla").play()

func EsLoro():
	# para evitar error
	return true

func Destructor(cadaver=true):
	if cadaver:
		var aux = load("res://scenes/otros/DieDiamante.tscn").instance()
		mundo.get_node("Objetos").add_child(aux)
		aux.position = position
		aux.body.frame = 5
		aux.body.get_node("Corona").visible = false
		aux.Quejido()
	miCueva.fuerzas -= 1
	sombrita.queue_free()
	queue_free()

func Golpeado():
	Destructor()

func Volarse():
	retirada = true

func _on_Buscador_timeout():
	get_node("Buscador").start(rand_range(sBuscador[0], sBuscador[1]))
	if retirada or GetObj() != null:
		if cueva != null:
			if is_instance_valid(cueva):
				var d = position.distance_to(cueva.position)
				if not mundo.LineaTierra(position, d, position.direction_to(cueva.position)):
					cueva = null
			else:
				cueva = null
		if cueva != null:
			return 0
		var cuevis = get_tree().get_nodes_in_group("cueva")
		var minDis = vision * 3
		var dis
		for c in cuevis:
			dis = position.distance_to(c.position)
			if dis < minDis:
				if mundo.LineaTierra(position, dis, position.direction_to(c.position)):
					minDis = dis
					cueva = c

func _on_Vigia_area_entered(area):
	colision[2].append(area.get_parent())

func _on_Vigia_area_exited(area):
	colision[2].erase(area.get_parent())

func Armado():
	# para evitar error
	return false

func Save(buffer):
	buffer.put_float(position.x)
	buffer.put_float(position.y)
	var r = 1 if retirada else 0
	buffer.put_u8(r)
	if miCueva != null and is_instance_valid(miCueva):
		buffer.put_u8(1)
		buffer.put_float(miCueva.position.x)
		buffer.put_float(miCueva.position.y)
	else:
		buffer.put_u8(0)

func Open(buffer):
	position.x = buffer.get_float()
	position.y = buffer.get_float()
	retirada = buffer.get_u8() != 0
	if buffer.get_u8() == 1:
		var cucus = get_tree().get_nodes_in_group("cueva")
		var posC = Vector2(0, 0)
		posC.x = buffer.get_float()
		posC.y = buffer.get_float()
		for c in cucus:
			if c.position.x == posC.x and c.position.y == posC.y:
				miCueva = c
				miCueva.sdevs.append(self)
				break

func _on_Disparador_timeout():
	get_node("Disparador").start(rand_range(sDispara[0], sDispara[1]))
	var ray = get_node("Ray")
	# guinxu, titan, jasperdev, sdev
	var minDis = disMele
	var minMan = null
	var dis
	for c in colision[2]:
		if c.tipo != 0:
			continue
		if not c.Armado():
			continue
		dis = position.distance_to(c.position)
		if dis < minDis:
			ray.cast_to = c.position - position
			ray.force_raycast_update()
			if not ray.is_colliding():
				minDis = dis
				minMan = c
	if minMan != null:
		var aux = mundo.UnProyectil()
		aux.direccion = position.direction_to(minMan.position)
		aux.direccion = aux.direccion.rotated(rand_range(-bisco, bisco))
		aux.position = position + aux.direccion * 8
		aux.Maligno(null)
		aux.Mele(disMele)

extends Node2D

const alimentacion = 6 # cantidad de arboles necesarios por tortuga
const velociSuelo = 80.0 # rapidez de desplazamiento
const visionFull = 400.0 # distancia vision para detectar cosas
const sErrar = [2, 6] # reloj ciclo para andar al azar
const sObservar = [9, 12] # reloj ciclo observacion del espacio
const paramErrar = [0.333, 0.666, 90] # al errar: probabi inv moverse, detenerse, giro max
const tipo = 0 # tipo tipSuelo, para evitar error al explotar

var colision = [[], [], []] # 0:solido, 1:movil, 2:huida
var mundo = null # nodo maestro para asceso rapido
var limirec = Vector2(0, 0) # limites del marco del mundo
var anterior = Vector2(0, 0) # posicion previa para mantenerse en tierra
var mover = false # true si esta en movimiento al errar
var direccion = Vector2(0, 0) # direccion al errar
var aniPaso = false # hacer cambio de animacion
var sombrita = null # sombra del personaje

func _ready():
	mundo = get_tree().get_nodes_in_group("mundo")[0]
	sombrita = mundo.lasombrita.instance()
	mundo.get_node("Sombras").add_child(sombrita)
	limirec = mundo.get_node("Agua").rect_size
	get_node("Errar").start(rand_range(sErrar[0], sErrar[1]))
	get_node("Observador").start(rand_range(sObservar[0], sObservar[1]))
	get_node("Anima").play("idle")

func _process(delta):
	anterior = position
	var ok = not Rebote(0, delta)
	if ok:
		ok = not Rebote(1, delta)
	if ok:
		ok = not Rebote(2, delta, true)
	if ok:
		Errar(delta)
	Limites(delta)

func Rebote(ind, delta, esHuir=false):
	var rebote = Vector2(0, 0)
	if esHuir:
		for c in colision[ind]:
			if c.is_in_group("diamante"):
				if not c.EsHippie():
					rebote += c.position.direction_to(position)
			else:
				rebote += c.position.direction_to(position)
	else:
		for c in colision[ind]:
			rebote += c.position.direction_to(position)
	if rebote.x != 0 or rebote.y != 0:
		if esHuir:
			rebote = rebote.rotated(PI * 0.5 * direccion.x)
		else:
			direccion = Vector2(1, 0).rotated(randf() * 2 * PI)
		position += rebote.normalized() * velociSuelo * delta
		return true
	return false

func Limites(delta):
	var ant = position
	position.x = clamp(position.x, 0, limirec.x)
	position.y = clamp(position.y, 0, limirec.y)
	if not mundo.EnTierra(position):
		position = anterior + Vector2(0, velociSuelo * delta).rotated(randf() * 2 * PI)
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

func Errar(delta):
	if mover:
		position += direccion * velociSuelo * delta

func Destructor(cadaver=true):
	if cadaver:
		var aux = load("res://scenes/otros/DieDiamante.tscn").instance()
		mundo.get_node("Objetos").add_child(aux)
		aux.position = position
		aux.body.frame = 11
		aux.body.get_child(0).queue_free()
	sombrita.queue_free()
	queue_free()

func _on_Errar_timeout():
	get_node("Errar").start(rand_range(sErrar[0], sErrar[1]))
	if mover:
		mover = randf() > paramErrar[0]
		direccion = direccion.rotated(rand_range(-paramErrar[2], paramErrar[2]))
	else:
		mover = randf() > paramErrar[1]
		direccion = Vector2(1, 0).rotated(randf() * 2 * PI)

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

func _on_Observador_timeout():
	get_node("Observador").start(rand_range(sObservar[0], sObservar[1]))
	# hallar arboles cercanos
	var arbis = get_tree().get_nodes_in_group("arbol")
	var ray = get_node("Ray")
	var totarbols = 0
	var miarbols = []
	var dis
	for a in arbis:
		dis = position.distance_to(a.position)
		if dis < visionFull:
			if mundo.LineaTierra(position, dis, position.direction_to(a.position)):
				totarbols += 1
				ray.cast_to = a.position - position
				ray.force_raycast_update()
				if not ray.is_colliding():
					miarbols.append(a)
	# hallar tortugas cercanas
	var tortis = get_tree().get_nodes_in_group("tortuga")
	var miturtles = []
	for t in tortis:
		dis = position.distance_to(t.position)
		if t != self and dis < visionFull:
			if mundo.LineaTierra(position, dis, position.direction_to(t.position)):
				miturtles.append(t)
	var proportion = totarbols / float(1 + miturtles.size())
	# morira si hay sobrepoblacion de tortugas o si no hay arboles
	if proportion < 1 or (totarbols == 0 and miturtles.size() != 0):
		if randf() < 0.2:
			Destructor()
	else:
		# moverse hacia arbol
		if not miarbols.empty() and randf() < 0.8:
			direccion = position.direction_to(miarbols[randi() % miarbols.size()].position)
			mover = true
			get_node("Errar").start(sErrar[1])
		# reproducirse
		if proportion >= alimentacion * 2 and randf() < 0.4:
			var aux = load("res://scenes/moviles/Tortuga.tscn").instance()
			mundo.get_node("Objetos").add_child(aux)
			aux.position = position + Vector2(randf(), randf())

func _on_Hulle_area_entered(area):
	if not area.get_parent().is_in_group("tortuga"):
		colision[2].append(area.get_parent())

func _on_Hulle_area_exited(area):
	if not area.get_parent().is_in_group("tortuga"):
		colision[2].erase(area.get_parent())

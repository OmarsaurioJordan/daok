extends Node2D

const poblaTitan = 88 # poblacion a partir de la cual aparecera
const edifiTitan = 40 # numero de edificios a partir del cual aparecera
const velociSuelo = 80.0 # rapidez de desplazamiento
const visionFull = 400.0 # distancia vision para detectar cosas
const sErrar = [3, 6] # reloj ciclo para andar al azar
const paramErrar = [0.333, 0.666, 90] # al errar: probabi inv moverse, detenerse, giro max
const tipo = 0 # tipo tipSuelo, para evitar error al explotar
const sEmbiste = [15, 60] # tiempo para deshabilitar el derribe de edificios, 0:normal, 1:retirada
const probTumbar = 0.333 # probabilidad tumbar edificacion al tocarla
const probCorreccion = 0.333 # probabilidad corregir trayectoria
const probTorres = 0.666 # probabilidad elegir torres a atacar antes que edificios
const caida = 50 # puntos necesarios para matarlo luego de rendicion en 0
const maxCaos = 3 # numero de edificos a derribar cuando es invocado por usuario
const superGolpe = 25 # cantidad de puntos quitados por explosion

var colision = [[], [], [], []] # 0:solido, 1:movil, 2:edificios, 3:torres
var mundo = null # nodo maestro para asceso rapido
var limirec = Vector2(0, 0) # limites del marco del mundo
var anterior = Vector2(0, 0) # posicion previa para mantenerse en tierra
var mover = false # true si esta en movimiento al errar
var direccion = Vector2(0, 0) # direccion al errar
var aniPaso = false # hacer cambio de animacion
var sombrita = null # sombra del personaje
var enAgua = false # dice si esta en agua o tierra
var edificiTumbar = 0 # numero de edificios que debe tumbar, sino se ira
var poblaInicial = 0 # numero de diamantes recien aparece
var rendicion = 50 # puntos de resistencia del ente
var esMortal = false # si se deben llegar hasta las ultimas consecuencias

func _ready():
	mundo = get_tree().get_nodes_in_group("mundo")[0]
	sombrita = mundo.lasombrita.instance()
	mundo.get_node("Sombras").add_child(sombrita)
	sombrita.scale = Vector2(4, 4)
	limirec = mundo.get_node("Agua").rect_size
	esMortal = mundo.Apocalipsis()
	get_node("Errar").start(rand_range(sErrar[0], sErrar[1]))
	get_node("Anima").play("idle")
	get_node("Vigia/Coli").shape.radius = visionFull
	mundo.SonidoLen([get_node("StitanDemolision"), get_node("StitanRetirada"),
	get_node("StitanFin")])

func Invasion():
	esMortal = true
	Configura(true)

func Configura(esInvoke=false):
	poblaInicial = get_tree().get_nodes_in_group("diamante").size()
	if esInvoke:
		edificiTumbar = maxCaos
		mundo.Log("invoke invade un AlvaMajo")
		mundo.Comprando("caos")
		get_node("StitanInvasion").play()
	else:
		if poblaInicial >= poblaTitan or (esMortal and poblaInicial > 0):
			var tot = get_tree().get_nodes_in_group("ediffice")
			for i in range(tot.size() - 1, -1, -1):
				if tot[i].is_in_group("ediParque"):
					tot.remove(i)
			tot = tot.size()
			if tot > edifiTitan or (esMortal and tot > 0):
				var tow = get_tree().get_nodes_in_group("ediTorre").size()
				edificiTumbar = ceil(randf() * min(max(1, tot - edifiTitan), 1 + tow))
		if edificiTumbar > 0:
			mundo.Log("invade un AlvaMajo")
			mundo.LaMedalla(1)
			get_node("StitanInvasion").play()

func ReUbicar():
	if randf() < 0.5:
		position.x = 0 if randf() < 0.5 else limirec.x
		position.y = randf() * limirec.y
	else:
		position.y = 0 if randf() < 0.5 else limirec.y
		position.x = randf() * limirec.x

func _process(delta):
	anterior = position
	var ok = not Rebote(0, delta)
	if ok:
		ok = not Rebote(1, delta)
	if ok:
		Errar(delta)
	Limites()

func Rebote(ind, delta):
	var rebote = Vector2(0, 0)
	if ind == 0:
		# edificaciones o solidos
		var tumbar = get_node("Embestida").is_stopped()
		for c in colision[ind]:
			if c.is_in_group("arbol"):
				c.Destruir()
				continue
			elif tumbar:
				if c.is_in_group("ediffice") and not c.is_in_group("ediParque"):
					if randf() < probTumbar:
						tumbar = false
						if c.is_in_group("ediAndamios"):
							mundo.Log("derribe de andamios por AlvaMajo")
						else:
							mundo.Log("derribe de " + c.nombre + " por AlvaMajo")
						get_node("StitanDemolision").play()
						c.Destruir()
						mover = false
						var alvas = get_tree().get_nodes_in_group("titan")
						for a in alvas:
							a.edificiTumbar = max(0, a.edificiTumbar - 1)
						var tot = get_tree().get_nodes_in_group("ediffice").size()
						var condicion = tot <= edifiTitan and not mundo.Apocalipsis()
						if edificiTumbar == 0 or condicion or tot == 0:
							edificiTumbar = 0
							get_node("Embestida").start(sEmbiste[1])
						else:
							get_node("Embestida").start(sEmbiste[0])
						continue
			rebote += c.position.direction_to(position)
	else:
		# moviles
		for c in colision[ind]:
			if c.is_in_group("titan"):
				rebote += c.position.direction_to(position)
			elif c.is_in_group("diamante"):
				if not c.Armado():
					c.Destructor()
			else:
				c.Destructor()
	if rebote.x != 0 or rebote.y != 0:
		direccion = Vector2(1, 0).rotated(randf() * 2 * PI)
		position += rebote.normalized() * velociSuelo * delta
		return true
	return false

func Limites():
	var ant = position
	position.x = clamp(position.x, 0, limirec.x)
	position.y = clamp(position.y, 0, limirec.y)
	var enTie = mundo.EnTierra(position)
	if enTie and enAgua:
		enAgua = false
		get_node("Imagen/PieL1").visible = true
		get_node("Imagen/PieR1").visible = true
		get_node("Imagen/PieL2").visible = true
		get_node("Imagen/PieR2").visible = true
		get_node("Imagen").position.y = 0
	elif not enTie and not enAgua:
		enAgua = true
		get_node("Imagen/PieL1").visible = false
		get_node("Imagen/PieR1").visible = false
		get_node("Imagen/PieL2").visible = false
		get_node("Imagen/PieR2").visible = false
		get_node("Imagen").position.y = 32
	if ant.x != position.x or ant.y != position.y:
		direccion = Vector2(1, 0).rotated(randf() * 2 * PI)
		if edificiTumbar == 0:
			Destructor(false)
			return 0
	#animaciones
	if aniPaso:
		if anterior.x == position.x or anterior.y == position.y:
			get_node("Anima").play("idle", -1, 0.8)
			aniPaso = false
	else:
		if anterior.x != position.x or anterior.y != position.y:
			get_node("Anima").play("walk", -1, 2)
			aniPaso = true
	# muevesombra
	sombrita.position = position

func Errar(delta):
	if mover:
		position += direccion * velociSuelo * delta

func Destructor(cadaver=true):
	if cadaver:
		mundo.HumoDemolision(self)
		# salpicar agua si muere sobre el agua
		var ch = load("res://scenes/otros/DieDiamante.tscn")
		var chap = get_node("Fin").get_children()
		var aux
		for c in chap:
			if not mundo.EnTierra(position + c.position):
				aux = ch.instance()
				mundo.get_node("Objetos").add_child(aux)
				aux.position = position + c.position
				aux.body.visible = false
		# poner sonido
		aux = load("res://scenes/otros/TitanSonido.tscn").instance()
		mundo.add_child(aux)
		aux.position = position
	sombrita.queue_free()
	queue_free()

func Golpeado(super=false):
	if super:
		rendicion -= superGolpe
	else:
		rendicion -= 1
	mover = true
	if rendicion <= -caida:
		Destructor()
	elif rendicion <= 0:
		if edificiTumbar > 0:
			get_node("StitanFin").play()
		edificiTumbar = 0

func _on_Errar_timeout():
	get_node("Errar").start(rand_range(sErrar[0], sErrar[1]))
	if mover:
		mover = randf() > paramErrar[0]
		direccion = direccion.rotated(rand_range(-paramErrar[2], paramErrar[2]))
	else:
		mover = randf() > paramErrar[1]
		direccion = Vector2(1, 0).rotated(randf() * 2 * PI)
	if randf() < probCorreccion:
		var diams = get_tree().get_nodes_in_group("diamante").size()
		var antEdi = edificiTumbar > 0
		if diams == 0:
			edificiTumbar = 0
		elif diams < poblaInicial * 0.5 and not esMortal:
			edificiTumbar = 0
		var edis = get_tree().get_nodes_in_group("ediffice")
		edificiTumbar = min(edificiTumbar, edis.size())
		var az = rand_range(-PI * 0.2, PI * 0.2)
		if edificiTumbar == 0:
			# retirada
			direccion = (limirec * 0.5).direction_to(position).rotated(az)
			if antEdi and edificiTumbar == 0:
				get_node("StitanRetirada").play()
		else:
			# busca edificio
			var i = -1
			if colision[2].empty():
				if not colision[3].empty():
					i = 3
			elif colision[3].empty():
				i = 2
			else:
				i = 3 if randf() < probTorres else 2
			if i != -1:
				var aux = colision[i][randi() % colision[i].size()]
				direccion = position.direction_to(aux.position).rotated(az)
			elif not edis.empty():
				direccion = position.direction_to(edis[randi() % edis.size()].position).rotated(az)

func Save(buffer):
	buffer.put_float(position.x)
	buffer.put_float(position.y)
	buffer.put_u8(edificiTumbar)
	buffer.put_u16(poblaInicial)
	buffer.put_16(rendicion)
	var m = 1 if esMortal else 0
	buffer.put_u8(m)

func Open(buffer):
	position.x = buffer.get_float()
	position.y = buffer.get_float()
	edificiTumbar = buffer.get_u8()
	poblaInicial = buffer.get_u16()
	rendicion = buffer.get_16()
	esMortal = buffer.get_u8() != 0

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

func _on_Vigia_area_entered(area):
	if area.get_parent().is_in_group("ediTorre"):
		colision[3].append(area.get_parent())
	elif not area.get_parent().is_in_group("ediParque"):
		colision[2].append(area.get_parent())

func _on_Vigia_area_exited(area):
	if area.get_parent().is_in_group("ediTorre"):
		colision[3].erase(area.get_parent())
	elif not area.get_parent().is_in_group("ediParque"):
		colision[2].erase(area.get_parent())

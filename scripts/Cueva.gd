extends Node2D

const debug = false
const velCueva = 0.5 # velocidad de aparecer y desaparecer, animacion
const minimaPoblacion = 44 # poblacion para empezar a invadir
const propoDesfase = 0.9 # proporcion maxima de veces que se superan las viviendas
const propoRiqueza = 0.333 # porcentaje de riqueza respecto a poblacion
const minimaInva = 3 # cantidad minima de entes invasores
const limitInva = 0.7 # exponente para reducir cantidad invasores a mas poblacion
const radioV = [300.0, 600.0] # limites minimo y maximo para aparecer cerca a edificio, vision sdev
const maxCaos = [10, 20, 40] # cantidad sdev al invocarlos el usuario

var asignados = 0 # maximos sdevs activos a la vez
var sdevs = [] # id de los sdevs creados
var robos = 0 # cantidad de cosas obtenidas
var avaricia = 0 # cantidad deseada de robos para irse
var fuerzas = 0 # cantidad de sdevs asociados con vida
var poblaIni = 0 # la catidad de diamantes antes de la invasion
var emerger = true # true si aparece, false si desaparece
var buscando = true # busca lugar para establecerse por siempre
var colisiones = 0 # cantidad de detecciones de colision
var intentos = 255 # cantidad de veces para intentar acomodarse
var esMortal = false # si se deben llegar hasta las ultimas consecuencias
var esInvoke = false # si es invoado por el usuario
var mundo = null # para acceso rapido

func _ready():
	mundo = get_tree().get_nodes_in_group("mundo")[0]
	get_node("Comienza").start(randf() * mundo.dia_wait_time)
	get_node("Termina").start(mundo.dia_wait_time)
	get_node("Termina").stop()
	set_process(false)
	get_node("Imagen/Frente").visible = false
	get_node("Imagen/Frente").scale = Vector2(1, 0.1)
	position = Vector2(0, 0)

func Invasion():
	get_node("Comienza").stop()
	esMortal = true
	# calcular la cantidad de sdevs que invadiran en un momento puntual
	poblaIni = get_tree().get_nodes_in_group("diamante").size()
	asignados = maxCaos[0]
	fuerzas = maxCaos[1]
	avaricia = min(maxCaos[2], mundo.GetRiqueza())
	# activar todo
	esInvoke = true
	set_process(true)

func _process(delta):
	if buscando:
		if colisiones > 0 or (position.x == 0 and position.y == 0):
			intentos -= 1
			if intentos <= 0:
				queue_free()
				return 0
			# buscar lugar para establecerce
			var edis = get_tree().get_nodes_in_group("robable")
			for i in range(edis.size() - 1, -1, -1):
				if edis[i].is_in_group("ediTorre"):
					edis.remove(i)
				elif not edis[i].get_node("Imagen/Actividad").pressed:
					edis.remove(i)
			if edis.empty():
				queue_free()
				return 0
			var punto = edis[randi() % edis.size()].position
			var cimi = get_node("Cimientos").get_children()
			var newpos
			var r
			var ok
			for _t in range(16):
				r = rand_range(radioV[0], radioV[1])
				newpos = punto + Vector2(r, 0).rotated(randf() * 2 * PI)
				ok = true
				for c in cimi:
					if not mundo.EnTierra(newpos + c.position):
						ok = false
						break
				if ok:
					for e in edis:
						if newpos.distance_to(e.position) < radioV[0]:
							ok = false
							break
				if ok:
					position = newpos
					break
		else:
			buscando = false
			get_node("Construccion").monitoring = false
			mundo.QuitaNaturales()
			get_node("Imagen/Frente").visible = true
			if esInvoke:
				mundo.Comprando("caos")
				mundo.Log("invoke invaden " + str(fuerzas) + " S-Dev")
			else:
				mundo.LaMedalla(3)
				mundo.Log("invaden " + str(fuerzas) + " S-Dev")
			get_node("SsdevInvasion").play()
			if debug:
				print("sdev: " + str(asignados) + "/" + str(fuerzas) + " $$$:" + str(avaricia))
	else:
		var img = get_node("Imagen/Frente")
		if emerger:
			img.scale.y += velCueva * delta
			if img.scale.y >= 1:
				img.scale.y = 1
				get_node("Chekeo").start()
				get_node("Termina").start()
				set_process(false)
				emerger = false
		else:
			img.scale.y -= velCueva * delta
			if img.scale.y <= 0:
				queue_free()

func _on_Comienza_timeout():
	esMortal = mundo.Apocalipsis()
	# ver si cumple con momento
	if not mundo.EsApocalipsis(3):
		queue_free()
		return 0
	# calcular la cantidad de sdevs que invadiran en un momento puntual
	poblaIni = get_tree().get_nodes_in_group("diamante").size()
	if poblaIni >= minimaPoblacion or (esMortal and poblaIni > 0):
		var ppmns = float(poblaIni) / mundo.GetPoblacion()
		if ppmns >= propoDesfase or esMortal:
			var g = max(0, (ppmns - propoDesfase) * mundo.GetPoblacion())
			var z = rand_range(-minimaInva, minimaInva)
			asignados = clamp(round(pow(g, limitInva) + z), minimaInva, maxCaos[0])
			# calcular cantidad invasores y robos en todo el tiempo
			avaricia = mundo.GetRiqueza()
			ppmns = float(avaricia) / poblaIni
			if ppmns >= propoRiqueza or (esMortal and avaricia > 0):
				fuerzas = clamp(round(avaricia * rand_range(0.5, 1.5)), asignados, maxCaos[1])
			avaricia = min(maxCaos[2], avaricia)
	if fuerzas == 0:
		queue_free()
		return 0
	# finalizar la creacion
	set_process(true)

func _on_Termina_timeout():
	fuerzas = 0
	var ok = false
	for s in sdevs:
		if is_instance_valid(s):
			fuerzas += 1
			s.Volarse()
			ok = true
	if ok:
		get_node("SsdevRetirada").play()

func _on_Chekeo_timeout():
	var pp = get_tree().get_nodes_in_group("diamante").size()
	if pp == 0 or robos >= avaricia:
		_on_Termina_timeout()
	elif pp < poblaIni * 0.5 and not esMortal:
		_on_Termina_timeout()
	if sdevs.empty() and fuerzas == 0:
		set_process(true)
		get_node("Chekeo").stop()
	else:
		for s in range(sdevs.size() - 1, -1, -1):
			if not is_instance_valid(sdevs[s]):
				# las fuerzas -1 se quitan desde el sdev
				sdevs.remove(s)
		# crear nuevos sdevs
		if sdevs.size() < asignados and fuerzas > sdevs.size():
			var aux = load("res://scenes/moviles/Sdev.tscn").instance()
			mundo.get_node("Objetos").add_child(aux)
			aux.position = position + Vector2(rand_range(-8, 8), rand_range(-8, 8))
			aux.miCueva = self
			aux.cueva = self
			aux.get_node("SHola").play()
			sdevs.append(aux)

func Save(buffer):
	buffer.put_float(position.x)
	buffer.put_float(position.y)
	buffer.put_u8(asignados)
	buffer.put_u16(robos)
	buffer.put_u16(avaricia)
	buffer.put_u16(fuerzas)
	buffer.put_u16(poblaIni)
	var b = 1 if emerger else 0
	buffer.put_u8(b)
	b = 1 if buscando else 0
	buffer.put_u8(b)
	b = 1 if esMortal else 0
	buffer.put_u8(b)
	b = 1 if esInvoke else 0
	buffer.put_u8(b)
	buffer.put_float(get_node("Comienza").time_left)
	buffer.put_float(get_node("Termina").time_left)

func Open(buffer):
	position.x = buffer.get_float()
	position.y = buffer.get_float()
	asignados = buffer.get_u8()
	robos = buffer.get_u16()
	avaricia = buffer.get_u16()
	fuerzas = buffer.get_u16()
	poblaIni = buffer.get_u16()
	emerger = buffer.get_u8() != 0
	buscando = buffer.get_u8() != 0
	esMortal = buffer.get_u8() != 0
	esInvoke = buffer.get_u8() != 0
	var lefT = buffer.get_float()
	var lefF = buffer.get_float()
	if lefT != 0:
		get_node("Comienza").start(lefT)
	elif lefF != 0:
		get_node("Termina").start(lefF)

func _on_Construccion_area_entered(area):
	if area.get_parent() != self:
		colisiones += 1

func _on_Construccion_area_exited(area):
	if area.get_parent() != self:
		colisiones -= 1

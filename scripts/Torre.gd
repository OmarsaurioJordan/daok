extends Node2D

const telescopio = 1.3 # bonus de distancia de vision por altura
const sVerifi = [1, 2] # cada cuanto disparar un proyectil
const bisco = 0.22 # radianes de desfase aleatorio al disparar

var nombre = "" # para demoler
var colision = [] # guarda enemigos vistos
var mundo = null # nodo maestro para asceso rapido

func _ready():
	mundo = get_tree().get_nodes_in_group("mundo")[0]
	Nombrar()
	get_node("Soldado").start(rand_range(sVerifi[0], sVerifi[1]))

func Nombrar():
	if name.count("@") == 0:
		nombre = name
	else:
		nombre = name.split("@", false)[0]

func Produccion(vacante):
	if get_node("Imagen/Actividad").pressed:
		if vacante:
			return get_node("Imagen/Guardia").get_child_count() == 0
		else:
			return get_node("Imagen/Guardia").get_child_count() != 0
	return false

func Balas():
	var tot = 0
	for i in range(4):
		if get_node("Imagen/Bala" + str(i + 1)).visible:
			tot += 1
	return tot

func TomaBalas():
	var bali = range(4)
	bali.shuffle()
	for b in bali:
		if get_node("Imagen/Bala" + str(b + 1)).visible:
			get_node("Imagen/Bala" + str(b + 1)).visible = false
			return true
	return false

func EsBodegable():
	if get_node("Imagen/Actividad").pressed:
		return Balas() < 4
	return false

func AbastoFull():
	return Balas() == 4

func PoneBalas():
	var bali = range(4)
	bali.shuffle()
	for b in bali:
		if not get_node("Imagen/Bala" + str(b + 1)).visible:
			get_node("Imagen/Bala" + str(b + 1)).visible = true
			return true
	return false

func PoneMercancia():
	var res = PoneBalas()
	res = PoneBalas() or res
	return res

func Robar():
	if get_node("Imagen/Actividad").pressed:
		if TomaBalas():
			return "balas"
	return ""

func PoneCosa():
	return PoneBalas()

func MaterialFull():
	return Balas() == 4

func Activo():
	return get_node("Imagen/Actividad").pressed

func WorkOk():
	if Produccion(true):
		return get_node("Imagen/Guardia")
	return null

func _on_Actividad_toggled(button_pressed):
	get_node("Imagen/Actividad/Sonido").play()
	if not button_pressed:
		Sacarlos()

func Sacarlos():
	if get_node("Imagen/Guardia").get_child_count() != 0:
		get_node("Imagen/Guardia").get_child(0).LiberaEstado()

func TieneAlgo():
	# evita error desde diamante
	return false

func PostSave(buffer):
	buffer.put_u8(1) # es una edificacion terminada
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
	buffer.put_u8(Balas())
	var a = 1 if get_node("Imagen/Actividad").pressed else 0
	buffer.put_u8(a)

func Open(buffer):
	position.x = buffer.get_float()
	position.y = buffer.get_float()
	var rep = buffer.get_u8()
	for _r in range(rep):
		PoneBalas()
	get_node("Imagen/Actividad").pressed = buffer.get_u8() != 0

func Destruir(humo=true):
	if humo:
		mundo.HumoDemolision(self)
	Sacarlos()
	queue_free()

func Deconstruir():
	var aux = load("res://scenes/andamios/C" + nombre + ".tscn").instance()
	mundo.get_node("Objetos").add_child(aux)
	aux.position = position
	aux.ModoDemoler()
	Destruir(false)

func _on_Vigia_area_entered(area):
	colision.append(area.get_parent())

func _on_Vigia_area_exited(area):
	colision.erase(area.get_parent())

func _on_Soldado_timeout():
	if get_node("Imagen/Guardia").get_child_count() == 0:
		get_node("Soldado").start(rand_range(sVerifi[0], sVerifi[1]))
		get_node("Vigia/Coli").shape.radius = 1
	else:
		var bonus = lerp(1, 0.5, get_node("Imagen/Guardia").get_child(0).GetFisico())
		get_node("Soldado").start(rand_range(sVerifi[0], sVerifi[1]) * bonus)
		var v = get_node("Imagen/Guardia").get_child(0).vision() * telescopio
		get_node("Vigia/Coli").shape.radius = v
		# intentar disparar
		var ray = get_node("Ray")
		# guinxu, titan, jasperdev, sdev
		var minDis = [v, v, v, v]
		var minMan = [null, null, null, null]
		var dis
		var i
		for c in colision:
			if c.tipo != 0:
				continue
			if c.is_in_group("guinxu"):
				i = 0
			elif c.is_in_group("titan"):
				i = 1
			elif c.is_in_group("jasperdev"):
				if not c.get_node("Imagen/Suelo/Cuerpo/Objeto").visible:
					continue
				i = 2
			elif c.is_in_group("sdev"):
				i = 3
			else:
				continue
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
				aux.exepcion = self
				aux.Alturizar(telescopio)
				aux.direccion = position.direction_to(m.position)
				aux.direccion = aux.direccion.rotated(rand_range(-bisco, bisco))
				aux.position = position + aux.direccion * 8
				break

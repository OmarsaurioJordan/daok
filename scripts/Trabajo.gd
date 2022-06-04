extends Node2D

const manoObra = 3 # capacidad de guardar diamantes obreros
var rotar = 0 # -1, 0, 1 segun sentido de rotacion
var asalariado = null # quien lleva los minerales
var nombre = "" # para demoler
var bodegas = [] # lugares donde descargar material

func _ready():
	get_node("Horario").start(rand_range(14, 16))
	get_node("SacaAsalariado").start(rand_range(6, 12))
	#get_node("Distribuye").start(rand_range(4, 8))
	Nombrar()
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.SonidoLen([get_node("Sonido"), get_node("SPoner")])

func Nombrar():
	if name.count("@") == 0:
		nombre = name
	else:
		nombre = name.split("@", false)[0]

func _process(delta):
	if rotar != 0:
		get_node("Imagen/Engranaje").rotate(rotar * delta)

func Minerales():
	var tot = 0
	for i in range(3):
		if get_node("Imagen/Mineral" + str(i + 1)).visible:
			tot += 1
	return tot

func Cajas():
	var tot = 0
	for i in range(6):
		if get_node("Imagen/Caja" + str(i + 1)).visible:
			tot += 1
	return tot

func DemeMineral():
	var mine = range(3)
	mine.shuffle()
	for m in mine:
		if get_node("Imagen/Mineral" + str(m + 1)).visible:
			return get_node("Imagen/Mineral" + str(m + 1))
	return null

func MaterialFull():
	return Cajas() == 6

func EsBodegable():
	if get_node("Imagen/Actividad").pressed:
		return Cajas() < 6
	return false

func Obreros():
	return get_node("Imagen/Salon/Sala").get_child_count()

func Compannia():
	return get_node("Imagen/Salon/Sala").get_child_count()

func _on_Horario_timeout():
	var porc = lerp(1, 0.5, float(Obreros()) / manoObra)
	var mens = get_node("Imagen/Salon/Sala").get_children()
	var intel = 0.0
	for m in mens:
		intel += m.GetIntelecto()
	intel = lerp(1, 0.5, intel / manoObra)
	get_node("Horario").start(rand_range(14, 16) * porc * intel)
	if Produccion(false):
		# proceso generacion
		var mine = DemeMineral()
		if Cajas() != 6 and mine != null:
			PoneCaja()
			mine.visible = randf() < 0.5
	# animaciones
	if Produccion(false):
		if rotar == 0:
			get_node("Imagen/Horno/Humo").emitting = true
		rotar = -1 if randf() < 0.5 else 1
		get_node("Anima").play("Go", -1, 0.69)
		get_node("Sonido").play()
	else:
		if rotar != 0:
			get_node("Imagen/Horno/Humo").emitting = false
		rotar = 0
		get_node("Anima").play("RESET")
		Sacarlos()

func _on_SacaAsalariado_timeout():
	get_node("SacaAsalariado").start(rand_range(6, 12))
	if asalariado != null:
		if is_instance_valid(asalariado):
			if not asalariado.EsMinando(get_node("Puerta")):
				asalariado = null
		else:
			asalariado = null

func Produccion(vacante):
	if get_node("Imagen/Actividad").pressed:
		if Cajas() < 6 and Minerales() > 0:
			if vacante:
				return Obreros() < manoObra
			else:
				return Obreros() > 0
	return false

func Vacantes():
	if get_node("Imagen/Actividad").pressed:
		if Cajas() < 6 and Minerales() > 0:
			return manoObra - Obreros()
	return 0

func WorkOk():
	if Produccion(true):
		return get_node("Imagen/Salon/Sala")
	return null

func WorkMinero(elMinero):
	if elMinero == asalariado or asalariado == null:
		if Minerales() < 3:
			asalariado = elMinero
			return true
	return false

func HayWorkMinero():
	return asalariado == null and Minerales() < 3

func TomaCaja():
	var caji = range(6)
	caji.invert()
	for c in caji:
		if get_node("Imagen/Caja" + str(c + 1)).visible:
			get_node("Imagen/Caja" + str(c + 1)).visible = false
			var mundo = get_tree().get_nodes_in_group("mundo")[0]
			mundo.AddMercancia(-1)
			return true
	return false

func PoneCaja():
	var caji = range(6)
	for c in caji:
		if not get_node("Imagen/Caja" + str(c + 1)).visible:
			get_node("Imagen/Caja" + str(c + 1)).visible = true
			var mundo = get_tree().get_nodes_in_group("mundo")[0]
			mundo.AddMercancia(1)
			return true
	return false

func TieneAlgo():
	if get_node("Imagen/Actividad").pressed:
		return Cajas() != 0
	return false

func PoneMercancia():
	return PoneCaja()

func PoneMineral():
	var list = [1, 2, 3]
	list.shuffle()
	for l in list:
		if not get_node("Imagen/Mineral" + str(l)).visible:
			get_node("Imagen/Mineral" + str(l)).visible = true
			return true
	return false

func EspacioMinerales():
	if get_node("Imagen/Actividad").pressed:
		return Minerales() < 3
	return false

func Robar():
	if get_node("Imagen/Actividad").pressed:
		if TomaCaja():
			return "caja"
		else:
			var m = DemeMineral()
			if m != null:
				m.visible = false
				return "mina"
	return ""

func _on_Distribuye_timeout():
	get_node("Distribuye").start(rand_range(4, 8))
	var nod = get_node("Puerta")
	bodegas = []
	var bod = get_tree().get_nodes_in_group("bodega")
	for b in bod:
		if b.EsBodegable():
			if nod.TieneDestino(b.get_node("Puerta")):
				bodegas.append(b.get_node("Puerta"))

func _on_Actividad_toggled(button_pressed):
	get_node("Imagen/Actividad/Sonido").play()
	if not button_pressed:
		Sacarlos()

func Sacarlos():
	var mens = get_node("Imagen/Salon/Sala").get_children()
	for m in mens:
		m.busEmple = false
		m.LiberaEstado()
	get_node("Sonido").stop()

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
	buffer.put_u8(Minerales())
	buffer.put_u8(Cajas())
	var a = 1 if get_node("Imagen/Actividad").pressed else 0
	buffer.put_u8(a)

func Open(buffer):
	position.x = buffer.get_float()
	position.y = buffer.get_float()
	var rep = buffer.get_u8()
	for _r in range(rep):
		PoneMineral()
	rep = buffer.get_u8()
	for _r in range(rep):
		PoneCaja()
	get_node("Imagen/Actividad").pressed = buffer.get_u8() != 0

func Destruir(humo=true):
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	if humo:
		mundo.HumoDemolision(self)
	mundo.AddMercancia(-Cajas())
	Sacarlos()
	queue_free()

func Deconstruir():
	var aux = load("res://scenes/andamios/C" + nombre + ".tscn").instance()
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.get_node("Objetos").add_child(aux)
	aux.position = position
	aux.ModoDemoler()
	Destruir(false)

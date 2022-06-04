extends Node2D

var nombre = "" # para demoler

func _ready():
	get_node("Escuchador").start(rand_range(4, 6))
	Nombrar()

func Nombrar():
	if name.count("@") == 0:
		nombre = name
	else:
		nombre = name.split("@", false)[0]

func Produccion(vacante):
	if get_node("Imagen/Actividad").pressed:
		if vacante:
			return get_node("Imagen/Balcon").get_child_count() == 0
		else:
			return get_node("Imagen/Balcon").get_child_count() != 0
	return false

func WorkOk():
	if Produccion(true):
		return get_node("Imagen/Balcon")
	return null

func EsActivo():
	return get_node("Imagen/Actividad").pressed

func _on_Actividad_toggled(button_pressed):
	get_node("Imagen/Actividad/Sonido").play()
	if not button_pressed:
		Sacarlos()
		get_node("Imagen/Necesitan").visible = false

func Sacarlos():
	if get_node("Imagen/Balcon").get_child_count() != 0:
		get_node("Imagen/Balcon").get_child(0).LiberaEstado()

func _on_Escuchador_timeout():
	get_node("Escuchador").start(rand_range(4, 6))
	if get_node("Imagen/Actividad").pressed:
		var nes = [0, 0, 0, 0, 0, 0, 0, 0, 0]
		var mens = get_tree().get_nodes_in_group("diamante")
		for m in mens:
			if m.EsPuto():
				nes[m.protesta] += 1
		if get_node("Imagen/Balcon").get_child_count() != 0:
			var el = get_node("Imagen/Balcon").get_child(0)
			if el.protesta != -1:
				nes[el.protesta] += 1
		var mx = nes.find(nes.max())
		if nes[mx] == 0:
			get_node("Imagen/Necesitan").visible = false
		else:
			get_node("Imagen/Necesitan").visible = true
			get_node("Imagen/Necesitan").frame = mx
	# animacion
	if get_node("Imagen/Balcon").get_child_count() != 0:
		get_node("Anima").play("Go", -1, 0.5)
	else:
		get_node("Anima").play("RESET")

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
	Sacarlos()
	queue_free()

func Deconstruir():
	var aux = load("res://scenes/andamios/C" + nombre + ".tscn").instance()
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.get_node("Objetos").add_child(aux)
	aux.position = position
	aux.ModoDemoler()
	Destruir(false)

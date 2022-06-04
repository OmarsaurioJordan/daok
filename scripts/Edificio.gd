extends Node2D

const vision = 500.0 # radio para hallar enemigos

var colision = [] # guardara los enemigos vistos
var asalariado = null # quien lleva los minerales
var nombre = "" # para demoler

func _ready():
	get_node("SacaAsalariado").start(rand_range(6, 12))
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.AddEdificio(5)
	Nombrar()
	get_node("Hulle/Coli").shape.radius = vision
	mundo.SonidoLen([get_node("SonidoCompra"), get_node("SPoner")])

func Nombrar():
	if name.count("@") == 0:
		nombre = name
	else:
		nombre = name.split("@", false)[0]

func Ocupado():
	var tot = 0
	for i in range(5):
		if get_node("Imagen/Ventana" + str(i + 1)).get_child_count() != 0:
			tot += 1
	return tot

func WorkOk():
	if get_node("Imagen/Actividad").pressed:
		var camas = range(5)
		camas.shuffle()
		for i in camas:
			if get_node("Imagen/Ventana" + str(i + 1)).get_child_count() == 0:
				return get_node("Imagen/Ventana" + str(i + 1))
	return null

func _on_Edificio_tree_exiting():
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.AddEdificio(-5)

func _on_Actividad_toggled(button_pressed):
	get_node("Imagen/Actividad/Sonido").play()
	if not button_pressed:
		Sacarlos()

func Sacarlos():
	for i in range(5):
		if get_node("Imagen/Ventana" + str(i + 1)).get_child_count() != 0:
			get_node("Imagen/Ventana" + str(i + 1)).get_child(0).LiberaEstado()

func PoneMineral():
	if not get_node("Imagen/Mineral").visible:
		get_node("Imagen/Mineral").visible = true
		return true
	return false

func Mineral():
	return get_node("Imagen/Mineral").visible

func EsBodegable():
	if get_node("Imagen/Actividad").pressed:
		return not Mineral()
	return false

func QuitaMineral():
	get_node("Imagen/Mineral").visible = false

func WorkMinero(elMinero):
	if elMinero == asalariado or asalariado == null:
		if not get_node("Imagen/Mineral").visible:
			asalariado = elMinero
			return true
	return false

func HayWorkMinero():
	return asalariado == null and not get_node("Imagen/Mineral").visible

func _on_SacaAsalariado_timeout():
	get_node("SacaAsalariado").start(rand_range(6, 12))
	if asalariado != null:
		if is_instance_valid(asalariado):
			if not asalariado.EsMinando(get_node("Puerta")):
				asalariado = null
		else:
			asalariado = null

func Robar():
	if get_node("Imagen/Actividad").pressed:
		if get_node("Imagen/Mineral").visible:
			get_node("Imagen/Mineral").visible = false
			return "mina"
	return ""

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
	var d = 1 if get_node("Imagen/Mineral").visible else 0
	buffer.put_u8(d)
	var a = 1 if get_node("Imagen/Actividad").pressed else 0
	buffer.put_u8(a)

func Open(buffer):
	position.x = buffer.get_float()
	position.y = buffer.get_float()
	get_node("Imagen/Mineral").visible = buffer.get_u8() != 0
	get_node("Imagen/Actividad").pressed = buffer.get_u8() != 0

func Destruir(humo=true):
	if humo:
		var mundo = get_tree().get_nodes_in_group("mundo")[0]
		mundo.HumoDemolision(self)
	Sacarlos()
	queue_free()

func EsSeguro():
	return colision.empty()

func Deconstruir():
	var aux = load("res://scenes/andamios/C" + nombre + ".tscn").instance()
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.get_node("Objetos").add_child(aux)
	aux.position = position
	aux.ModoDemoler()
	Destruir(false)

func _on_Hulle_area_entered(area):
	colision.append(area.get_parent())

func _on_Hulle_area_exited(area):
	colision.erase(area.get_parent())

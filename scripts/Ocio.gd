extends Node2D

const asientos = 4 # capacidad de guardar diamantes
var nombre = "" # para demoler

func _ready():
	get_node("Rockola").start(rand_range(10, 15))
	Nombrar()
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.SonidoLen([get_node("SonidoCopa"), get_node("SPoner"), get_node("SMusica")])

func Nombrar():
	if name.count("@") == 0:
		nombre = name
	else:
		nombre = name.split("@", false)[0]

func Chuspas():
	var tot = 0
	for i in range(4):
		if get_node("Imagen/Chuspa" + str(i + 1)).visible:
			tot += 1
	return tot

func Copas():
	var tot = 0
	for i in range(4):
		if get_node("Imagen/Copa" + str(i + 1)).visible:
			tot += 1
	return tot

func MaterialFull():
	return Chuspas() == 4

func ComidaFull():
	return Copas() == 4

func Bailantes():
	return get_node("Imagen/Salon/Sala").get_child_count()

func Compannia():
	return get_node("Imagen/Salon/Sala").get_child_count()

func TomaChuspa():
	var chuspi = range(4)
	chuspi.shuffle()
	for c in chuspi:
		if get_node("Imagen/Chuspa" + str(c + 1)).visible:
			get_node("Imagen/Chuspa" + str(c + 1)).visible = false
			var mundo = get_tree().get_nodes_in_group("mundo")[0]
			mundo.AddMercancia(-1)
			return true
	return false

func PoneChuspa():
	var chuspi = range(4)
	chuspi.shuffle()
	for c in chuspi:
		if not get_node("Imagen/Chuspa" + str(c + 1)).visible:
			get_node("Imagen/Chuspa" + str(c + 1)).visible = true
			var mundo = get_tree().get_nodes_in_group("mundo")[0]
			mundo.AddMercancia(1)
			return true
	return false

func EsBodegable():
	if get_node("Imagen/Actividad").pressed:
		return Chuspas() < 4
	return false

func EsNeverable():
	if get_node("Imagen/Actividad").pressed:
		return Copas() < 4
	return false

func GetAlimento():
	if get_node("Imagen/Actividad").pressed:
		return Copas() != 0
	return false

func GetBolsas():
	if get_node("Imagen/Actividad").pressed:
		return Chuspas() != 0
	return false

func TomarAlimento():
	var comi = range(4)
	comi.shuffle()
	for c in comi:
		if get_node("Imagen/Copa" + str(c + 1)).visible:
			get_node("Imagen/Copa" + str(c + 1)).visible = false
			var mundo = get_tree().get_nodes_in_group("mundo")[0]
			mundo.AddComida(-1)
			return true
	return false

func PonerAlimento():
	var comi = range(4)
	comi.shuffle()
	for c in comi:
		if not get_node("Imagen/Copa" + str(c + 1)).visible:
			get_node("Imagen/Copa" + str(c + 1)).visible = true
			var mundo = get_tree().get_nodes_in_group("mundo")[0]
			mundo.AddComida(1)
			return true
	return false

func PoneComida():
	var res = PonerAlimento()
	res = PonerAlimento() or res
	return res

func PoneMercancia():
	var res = PoneChuspa()
	res = PoneChuspa() or res
	return res

func WorkOk():
	if get_node("Imagen/Actividad").pressed:
		if Bailantes() < asientos:
			return get_node("Imagen/Salon/Sala")
	return null

func _on_Actividad_toggled(button_pressed):
	get_node("Imagen/Actividad/Sonido").play()
	if not button_pressed:
		Sacarlos()

func Sacarlos():
	var mens = get_node("Imagen/Salon/Sala").get_children()
	for m in mens:
		m.LiberaEstado()

func TieneAlgo():
	# evita error desde diamante
	return false

func Robar():
	if get_node("Imagen/Actividad").pressed:
		if randf() < 0.5:
			if TomarAlimento():
				return "copa"
			elif TomaChuspa():
				return "bolsa"
		else:
			if TomaChuspa():
				return "bolsa"
			elif TomarAlimento():
				return "copa"
	return ""

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
	buffer.put_u8(Copas())
	buffer.put_u8(Chuspas())
	var a = 1 if get_node("Imagen/Actividad").pressed else 0
	buffer.put_u8(a)

func Open(buffer):
	position.x = buffer.get_float()
	position.y = buffer.get_float()
	var rep = buffer.get_u8()
	for _r in range(rep):
		PonerAlimento()
	rep = buffer.get_u8()
	for _r in range(rep):
		PoneChuspa()
	get_node("Imagen/Actividad").pressed = buffer.get_u8() != 0

func Destruir(humo=true):
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	if humo:
		mundo.HumoDemolision(self)
	mundo.AddComida(-Copas())
	mundo.AddMercancia(-Chuspas())
	Sacarlos()
	queue_free()

func Deconstruir():
	var aux = load("res://scenes/andamios/C" + nombre + ".tscn").instance()
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.get_node("Objetos").add_child(aux)
	aux.position = position
	aux.ModoDemoler()
	Destruir(false)

func _on_Rockola_timeout():
	if Bailantes() != 0:
		var mundo = get_tree().get_nodes_in_group("mundo")[0]
		get_node("SMusica").stream = mundo.musicas[randi() % mundo.musicas.size()]
		get_node("SMusica").play()
		get_node("Imagen/Tocadiscos/Onda").emitting = true
		get_node("Anima").play("Go", -1, 0.8)
	else:
		get_node("Rockola").start(rand_range(6, 9))
		get_node("Imagen/Tocadiscos/Onda").emitting = false
		get_node("Anima").play("RESET")

func _on_SMusica_finished():
	_on_Rockola_timeout()

extends Node2D

const manoObra = 3 # cantidad diamantes adentro
var rotar = false # giro de la helice
var sombra = null # huella de fondo
var nombre = "" # para demoler
var neveras = [] # lugares donde llevar comida

func _ready():
	get_node("Semillax").start(rand_range(9, 12))
	get_node("Fermenta").start(rand_range(1, 10))
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
	if rotar:
		get_node("Imagen/Helice").rotate(3 * delta)

func Maisez():
	var tot = 0
	for i in range(10):
		if get_node("Imagen/Salon/Sala/Maiz" + str(i + 1)).visible:
			tot += 1
	return tot

func Comidas():
	var tot = 0
	for i in range(4):
		if get_node("Imagen/Comida" + str(i + 1)).visible:
			tot += 1
	return tot

func ComidaFull():
	return Comidas() == 4

func Agricultores():
	var tot = 0
	var cosas = get_node("Imagen/Salon/Sala").get_children()
	for c in cosas:
		if c.is_in_group("diamante"):
			tot += 1
	return tot

func Compannia():
	return Agricultores()

func _on_Semillax_timeout():
	var porc = lerp(1, 0.5, Agricultores() / float(manoObra))
	var cosas = get_node("Imagen/Salon/Sala").get_children()
	var intel = 0
	for c in cosas:
		if c.is_in_group("diamante"):
			intel += c.GetIntelecto()
	intel = lerp(1, 0.5, intel / float(manoObra))
	get_node("Semillax").start(rand_range(9, 12) * porc * intel)
	rotar = Produccion(false)
	if rotar:
		var tot = Maisez()
		var coc = Comidas()
		if tot < 10 and randf() > tot / 10.0:
			CreceMaiz()
		if coc < 4 and tot >= 3:
			var k = [DameMaiz(), DameMaiz()]
			if k[0] != k[1]:
				PonerAlimento()
				k[0].visible = false
				k[1].visible = randf() < 0.5
	if Produccion(false):
		get_node("Sonido").play()
	else:
		Sacarlos()

func _on_Fermenta_timeout():
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	if mundo.esDia:
		get_node("Fermenta").start(rand_range(9, 12))
	else:
		get_node("Fermenta").start(rand_range(6, 9))
	if randf() < 0.25 and not Produccion(false):
		var mz = DameMaiz()
		if mz != null:
			mz.visible = false

func CreceMaiz():
	var mz = range(10)
	mz.shuffle()
	for m in mz:
		if not get_node("Imagen/Salon/Sala/Maiz" + str(m + 1)).visible:
			get_node("Imagen/Salon/Sala/Maiz" + str(m + 1)).visible = true
			return true
	return false

func DameMaiz():
	var mz = range(10)
	mz.shuffle()
	for m in mz:
		if get_node("Imagen/Salon/Sala/Maiz" + str(m + 1)).visible:
			return get_node("Imagen/Salon/Sala/Maiz" + str(m + 1))
	return null

func PonerAlimento():
	var comi = range(4)
	comi.shuffle()
	for c in comi:
		if not get_node("Imagen/Comida" + str(c + 1)).visible:
			get_node("Imagen/Comida" + str(c + 1)).visible = true
			var mundo = get_tree().get_nodes_in_group("mundo")[0]
			mundo.AddComida(1)
			return true
	return false

func TomarAlimento():
	var comi = range(4)
	comi.shuffle()
	for c in comi:
		if get_node("Imagen/Comida" + str(c + 1)).visible:
			get_node("Imagen/Comida" + str(c + 1)).visible = false
			var mundo = get_tree().get_nodes_in_group("mundo")[0]
			mundo.AddComida(-1)
			return true
	return false

func PoneComida():
	return PonerAlimento()

func GetAlimento():
	if get_node("Imagen/Actividad").pressed:
		return Comidas() != 0
	return false

func TieneAlgo():
	return Comidas() != 0

func Produccion(vacante):
	if get_node("Imagen/Actividad").pressed:
		var mundo = get_tree().get_nodes_in_group("mundo")[0]
		if mundo.esDia:
			if Comidas() < 4 or Maisez() < 10:
				if vacante:
					return Agricultores() < manoObra
				else:
					return Agricultores() > 0
	return false

func Vacantes():
	if get_node("Imagen/Actividad").pressed:
		var mundo = get_tree().get_nodes_in_group("mundo")[0]
		if mundo.esDia:
			if Comidas() < 4 or Maisez() < 10:
				return manoObra - Agricultores()
	return 0

func WorkOk():
	if Produccion(true):
		return get_node("Imagen/Salon/Sala")
	return null

func _on_Distribuye_timeout():
	get_node("Distribuye").start(rand_range(4, 8))
	var nod = get_node("Puerta")
	neveras = []
	var bod = get_tree().get_nodes_in_group("nevera")
	for b in bod:
		if b.EsNeverable():
			if nod.TieneDestino(b.get_node("Puerta")):
				neveras.append(b.get_node("Puerta"))

func _on_Actividad_toggled(button_pressed):
	get_node("Imagen/Actividad/Sonido").play()
	if not button_pressed:
		Sacarlos()

func EsNeverable():
	if get_node("Imagen/Actividad").pressed:
		return Comidas() < 4
	return false

func Sacarlos():
	var cosas = get_node("Imagen/Salon/Sala").get_children()
	for c in cosas:
		if c.is_in_group("diamante"):
			c.busEmple = false
			c.LiberaEstado()
	get_node("Sonido").stop()

func Robar():
	if get_node("Imagen/Actividad").pressed:
		if TomarAlimento():
			return "guaro"
	return ""

func _on_PoneSombra_timeout():
	sombra = get_node("Imagen/Suelo")
	sombra.get_parent().remove_child(sombra)
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.get_node("Romboys").add_child(sombra)
	sombra.position = position

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
	buffer.put_u8(Comidas())
	buffer.put_u8(Maisez())
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
		CreceMaiz()
	get_node("Imagen/Actividad").pressed = buffer.get_u8() != 0

func Destruir(humo=true):
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	if humo:
		mundo.HumoDemolision(self)
	mundo.AddComida(-Comidas())
	if sombra != null:
		sombra.queue_free()
	Sacarlos()
	queue_free()

func Deconstruir():
	var aux = load("res://scenes/andamios/C" + nombre + ".tscn").instance()
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	mundo.get_node("Objetos").add_child(aux)
	aux.position = position
	aux.ModoDemoler()
	Destruir(false)

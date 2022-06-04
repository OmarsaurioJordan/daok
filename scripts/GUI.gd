extends Control

const aceleration = 3 # multiplo para acelerar el juego
const transpa = 0.5 # nivel de transparencia de botones no investigados
const maxTimeNeg = 0.5 # tiempo para mostrar pantalla oscura para salir
const tiempoLibroOscilaImg = 3.0 # segundos oscilacion imagenes libro
# velocidad de investigacion en segundos
const nameEdi = ["Edificio", "Ocio", "Cultivo", "Trabajo", "Puerto", "Hospital", "Torre",
"Estudio", "Juego", "Parque", "Centro"]
const velInv = [10, 100, 60, 300, 80, 320, 150, 350, 100, 60, 555]

var mundo = null # nodo maestro para asceso rapido
var investiga = [] # guarda los progresos de investigacion, 1 ya investigado
var antRef = "" # anteriro referencia del tooltip
var timeNegritud = 0.0 # tiempo mostrando pantalla oscura

func _ready():
	mundo = get_tree().get_nodes_in_group("mundo")[0]
	for _r in range(11):
		investiga.append(0)
	investiga[0] = 1
	ActivaBuilds()
	get_node("Ordenes/BCaos").modulate = Color(1, 1, 1, transpa)
	get_node("Ordenes/BLores").modulate = Color(1, 1, 1, transpa)
	get_node("Ordenes/BDinamita").modulate = Color(1, 1, 1, transpa)
	get_node("Opciones/BSeguidor").modulate = Color(1, 1, 1, transpa)
	# cargar ruta de archivos
	var path = ""
	var directory = Directory.new()
	if directory.file_exists("user://png.txt"):
		var file = File.new()
		if file.open("user://png.txt", File.READ) == OK:
			path = file.get_as_text()
			file.close()
	get_node("FileDialog").current_file = ""
	get_node("FileDialog").current_dir = path.get_base_dir()
	get_node("FileDialog").current_path = path.get_base_dir() + "/"
	# organizar libro
	get_node("Libro").rect_position = Vector2(170, 80)
	var hjs = get_node("Libro/Hojas").get_children()
	for h in range(hjs.size()):
		hjs[h].get_node("Titulo").text = str(h + 1) + ". " + hjs[h].get_node("Titulo").text
		hjs[h].visible = false
	hjs[0].visible = true
	CambiaLibro(false)

func _process(delta):
	get_node("Value").global_position = get_global_mouse_position()
	# salir del juego
	if timeNegritud != 0:
		if get_node("Opciones/BSpeedOn").visible:
			var mxtn = maxTimeNeg * aceleration
			get_node("Negritud").modulate = Color(0.4, 0.4, 0.4, (timeNegritud / mxtn) * 0.8)
		else:
			get_node("Negritud").modulate = Color(0.4, 0.4, 0.4, (timeNegritud / maxTimeNeg) * 0.8)
		timeNegritud = max(0, timeNegritud - delta)
		if timeNegritud == 0:
			get_node("Negritud").visible = false
	# tecla de retroceso
	if visible:
		if Input.is_action_just_pressed("ui_cancel"):
			if get_node("Libro").visible:
				CambiaLibro(false)
			elif get_node("Opciones/BEyeOff").visible:
				if get_node("Negritud").visible:
					if mundo.GetDia() != 0:
						mundo.Guardar("user://savegame.save")
					var menu = load("res://scenes/Menu.tscn").instance()
					mundo.get_parent().add_child(menu)
					mundo.queue_free()
				else:
					get_node("Negritud").visible = true
					if get_node("Opciones/BSpeedOn").visible:
						timeNegritud = maxTimeNeg * aceleration
					else:
						timeNegritud = maxTimeNeg
			else:
				_on_BEyeOn_button_down()
	# tecla de foto guardada internamente
	if Input.is_action_just_pressed("ui_foto"):
		var image = get_viewport().get_texture().get_data()
		image.flip_y()
		image.save_png("user://img.png")
	# mantener el file dialog bien
	if get_node("FileDialog").visible:
		var esq = get_parent().get_node("Esquina")
		var posMin = esq.rect_position + Vector2(13, 27) * esq.rect_scale
		var posMax = esq.rect_position + Vector2(940, 516) * esq.rect_scale
		var fiDi = get_node("FileDialog")
		fiDi.rect_position.x = clamp(fiDi.rect_position.x, posMin.x, posMax.x)
		fiDi.rect_position.y = clamp(fiDi.rect_position.y, posMin.y, posMax.y)
	# cambiar hojas libro
	if get_node("Libro").visible:
		if Input.is_action_just_pressed("ui_left"):
			_on_Anterior_button_down()
		elif Input.is_action_just_pressed("ui_right"):
			_on_Siguiente_button_down()

func _input(event):
	if get_node("Libro").visible:
		if event is InputEventMouseButton:
			if event.is_pressed():
				if event.button_index == BUTTON_MIDDLE:
					CambiaLibro(false)

func CambiaLibro(esVisible):
	get_node("Libro").visible = esVisible
	get_node("SubLibro").visible = esVisible
	get_tree().paused = esVisible and get_node("Libro/Pausador").pressed
	get_node("LibroTime").start(Engine.time_scale * tiempoLibroOscilaImg)

func CambiaMapa(ind):
	get_node("Minimapa/Mapa").frame = ind - 1

func ActivaBuilds():
	var c
	for i in range(11):
		c = Color(1, 1, 1, max(transpa, floor(investiga[i])))
		get_node("Buildings/B" + nameEdi[i]).modulate = c
	mundo = get_tree().get_nodes_in_group("mundo")[0]
	if mundo.Trofeo() and mundo.Apocalipsis(true):
		get_node("Ordenes/BCaos").modulate = Color(1, 1, 1, 1)
		get_node("Ordenes/BLores").modulate = Color(1, 1, 1, 1)
	if mundo.medalla[2] == 1: # jasperdev
		get_node("Ordenes/BDinamita").modulate = Color(1, 1, 1, 1)
	mundo.CambiaCaos(mundo.modoCaos)

func Construir(ind):
	var aux = mundo.loadBuilds[2][ind].instance()
	mundo.get_node("Objetos").add_child(aux)
	aux.position = get_global_mouse_position()
	aux.indBuild = ind
	_on_BSpeedOn_button_down()

func EsInvestigado(ind):
	if investiga[ind] == 1:
		return true
	elif get_node("Investigacion").visible:
		if get_node("Investigacion/Proyecto").frame == ind + 1:
			get_node("Investigacion").visible = false
			get_node("Cientifik").stop()
			get_node("SBoton").play()
	else:
		get_node("Investigacion").visible = true
		get_node("Investigacion/Proyecto").frame = ind + 1
		get_node("Investigacion/Progreso").value = investiga[ind] * 100.0
		get_node("Cientifik").start()
		get_node("SBoton").play()
	return false

func _on_BInfo_button_down():
	CambiaLibro(true)

func _on_Pausador_toggled(button_pressed):
	get_tree().paused = button_pressed

func _on_BScreenshot_button_down():
	get_node("FileDialog").window_title = "Guardar pantallazo"
	get_node("FileDialog").popup()
	get_node("SBoton").play()
	# guardar foto
	var image = get_viewport().get_texture().get_data()
	image.flip_y()
	image.save_png("user://img.png")
	# mover file dialog
	var esq = get_parent().get_node("Esquina")
	var pos = esq.rect_position + Vector2(255, 99) * esq.rect_scale
	get_node("FileDialog").rect_position = pos
	get_node("FileDialog").rect_scale = esq.rect_scale

func _on_BSeguidor_button_down():
	var sc = mundo.get_node("SeguirCam")
	mundo.camSeguir = null
	if sc.is_stopped():
		sc.start()
		get_node("Opciones/BSeguidor").modulate = Color(1, 1, 1, 1)
	else:
		sc.stop()
		get_node("Opciones/BSeguidor").modulate = Color(1, 1, 1, transpa)
	get_node("SBoton").play()

func NoSeguir():
	mundo.get_node("SeguirCam").stop()
	mundo.camSeguir = null
	get_node("Opciones/BSeguidor").modulate = Color(1, 1, 1, transpa)

func _on_FileDialog_file_selected(path):
	# guardar el path general
	get_node("FileDialog").current_file = ""
	get_node("FileDialog").current_dir = path.get_base_dir()
	get_node("FileDialog").current_path = path.get_base_dir() + "/"
	var file = File.new()
	if file.open("user://png.txt", File.WRITE) == OK:
		file.store_string(path)
		file.close()
	# guardar foto
	var directory = Directory.new()
	directory.copy("user://img.png", path)
	get_node("SFoto").play()

func _on_BCalle_button_down():
	var aux = load("res://scenes/otros/Nodal.tscn").instance()
	mundo.get_node("Objetos").add_child(aux)
	aux.position = get_global_mouse_position()
	_on_BSpeedOn_button_down()
	get_node("SBoton").play()

func _on_BEdificio_button_down():
	if EsInvestigado(0):
		Construir(0)
		get_node("SBoton").play()

func _on_BOcio_button_down():
	if EsInvestigado(1):
		Construir(1)
		get_node("SBoton").play()

func _on_BCultivo_button_down():
	if EsInvestigado(2):
		Construir(2)
		get_node("SBoton").play()

func _on_BTrabajo_button_down():
	if EsInvestigado(3):
		Construir(3)
		get_node("SBoton").play()

func _on_BPuerto_button_down():
	if EsInvestigado(4):
		Construir(4)
		get_node("SBoton").play()

func _on_BHospital_button_down():
	if EsInvestigado(5):
		Construir(5)
		get_node("SBoton").play()

func _on_BTorre_button_down():
	if EsInvestigado(6):
		Construir(6)
		get_node("SBoton").play()

func _on_BEstudio_button_down():
	if EsInvestigado(7):
		Construir(7)
		get_node("SBoton").play()

func _on_BJuego_button_down():
	if EsInvestigado(8):
		Construir(8)
		get_node("SBoton").play()

func _on_BParque_button_down():
	if EsInvestigado(9):
		Construir(9)
		mundo.Circulo(mundo.radioReserva)
		mundo.get_node("CircleComand").visible = true
		get_node("SBoton").play()

func _on_BCentro_button_down():
	if EsInvestigado(10):
		if get_tree().get_nodes_in_group("unico").empty():
			Construir(10)
			get_node("SBoton").play()

func _on_BDemolision_button_down():
	var aux = load("res://scenes/otros/Destructor.tscn").instance()
	mundo.add_child(aux)
	aux.position = get_global_mouse_position()
	_on_BSpeedOn_button_down()
	get_node("SBoton").play()

func _on_Stadistics_timeout():
	if not get_node("Libro").visible:
		var diam = get_tree().get_nodes_in_group("diamante")
		get_node("Recursos/Poblacion/Num").text = str(diam.size())
		var felix = 0
		var enfermos = 0
		var soldiers = 0
		for d in diam:
			felix += d.felicidad
			if d.Armado():
				soldiers += 1
			if d.EsEnfermo():
				enfermos += 1
		felix /= float(max(1, diam.size()))
		get_node("Recursos/Felicidad/Num").text = str(round(felix * 100.0)) + "%"
		get_node("Recursos/Virus/Num").text = str(enfermos)
		var monsters = get_tree().get_nodes_in_group("monster").size()
		get_node("Recursos/Defensas/Num").text = str(soldiers) + "/" + str(monsters)

func _on_BEyeOff_button_down():
	get_node("Opciones/BEyeOff").visible = false
	get_node("Opciones/BEyeOn").visible = true
	var act = get_tree().get_nodes_in_group("actividad")
	for a in act:
		a.visible = true
	get_node("SBoton").play()

func _on_BEyeOn_button_down():
	if get_node("Opciones/BEyeOn").visible:
		get_node("Opciones/BEyeOn").visible = false
		get_node("Opciones/BEyeOff").visible = true
		var act = get_tree().get_nodes_in_group("actividad")
		for a in act:
			a.visible = false
		get_node("SBoton").play()

func _on_BSpeedOff_button_down():
	get_node("Opciones/BSpeedOn").visible = true
	get_node("Opciones/BSpeedOff").visible = false
	Engine.time_scale = aceleration
	get_node("SBoton").play()

func _on_BSpeedOn_button_down():
	get_node("Opciones/BSpeedOn").visible = false
	get_node("Opciones/BSpeedOff").visible = true
	Engine.time_scale = 1
	get_node("SBoton").play()

func _on_MaskMap_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_LEFT:
				mundo.SaltaCamara(event.position / 180.0)

func _on_GUI_visibility_changed():
	get_node("Value").visible = false
	get_node("Value/ViSuave").visible = false
	get_node("Rtooltip").stop()
	antRef = ""
	if visible:
		get_node("TimProtektor").start()
	else:
		get_node("Protektor").visible = true

func _on_TimProtektor_timeout():
	get_node("Protektor").visible = false

func _on_Cientifik_timeout():
	if get_node("Investigacion").visible and not get_node("Libro").visible:
		if mundo.Comprando("investigacion"):
			var i = get_node("Investigacion/Proyecto").frame - 1
			investiga[i] = min(1, investiga[i] + get_node("Cientifik").wait_time / velInv[i])
			get_node("Investigacion/Progreso").value = investiga[i] * 100.0
			if investiga[i] == 1:
				mundo.Log("investigado " + nameEdi[i])
				get_node("Investigacion").visible = false
				get_node("Cientifik").stop()
				ActivaBuilds()
				get_node("SDesbloqueo").play()

func _on_BNacer_button_down():
	var pos = rect_position + get_viewport().size * rect_scale * 0.5
	var rad = get_viewport().size.y * rect_scale.y * 0.5
	var newpos = Vector2(0, 0)
	var freno = 100
	while newpos.x == 0 and freno > 0:
		freno -= 1
		newpos = pos + Vector2(randf() * rad, 0).rotated(randf() * 2.0 * PI)
		if not mundo.Enrraizado(newpos):
			newpos = Vector2(0, 0)
	if freno > 0 and mundo.Comprando("nace"):
		get_node("Protektor").visible = true
		get_node("TimProtektor").start()
		var aux = mundo.newDiamante.instance()
		mundo.get_node("Objetos").add_child(aux)
		var limits = mundo.get_node("Agua").rect_size
		if randf() < 0.5:
			aux.position.x = 0 if randf() < 0.5 else limits.x
			aux.position.y = randf() * limits.y
		else:
			aux.position.y = 0 if randf() < 0.5 else limits.y
			aux.position.x = randf() * limits.x
		aux.Volando(newpos)
		get_node("SNace").play()

func _on_BComando_button_down():
	var aux = load("res://scenes/otros/Comando.tscn").instance()
	mundo.get_node("Objetos").add_child(aux)
	aux.position = get_global_mouse_position()
	get_node("SBoton").play()

func _on_BObreros_button_down():
	get_node("Protektor").visible = true
	get_node("TimProtektor").start()
	var pos = rect_position + get_viewport().size * rect_scale * 0.5
	var andami = get_tree().get_nodes_in_group("ediAndamios")
	var minDis = get_viewport().size.y * rect_scale.y * 0.5
	var cual = null
	var dis
	for a in andami:
		if a.Trabajable():
			dis = pos.distance_to(a.position)
			if dis < minDis:
				minDis = dis
				cual = a
	if cual != null:
		var diams = get_tree().get_nodes_in_group("diamante")
		minDis = -1
		var quien = null
		for d in diams:
			if d.EsBlanco():
				dis = cual.position.distance_to(d.position)
				if mundo.LineaTierra(cual.position, dis, cual.position.direction_to(d.position)):
					if dis < minDis or minDis == -1:
						minDis = dis
						quien = d
		if quien != null:
			quien.Construyamelo(cual)
			get_node("SBoton").play()

func _on_BDinamita_button_down():
	if mundo.medalla[2] == 1:
		var aux = load("res://scenes/otros/Dinamita.tscn").instance()
		mundo.get_node("Objetos").add_child(aux)
		aux.position = get_global_mouse_position()
		_on_BSpeedOn_button_down()
		get_node("SBoton").play()

func _on_BCaos_button_down():
	if mundo.Trofeo() and mundo.Apocalipsis(true):
		#mundo.InvocaCaos() # funcion descontinuada, disenno viejo del juego
		get_node("SBoton").play()
		mundo.CambiaCaos(false)

func _on_BLores_button_down():
	if mundo.Trofeo() and mundo.Apocalipsis(true):
		get_node("SBoton").play()
		mundo.CambiaCaos(true)

func _on_Siguiente_button_down():
	var hjs = get_node("Libro/Hojas").get_children()
	if get_node("Libro/Hojas/Hoja" + str(hjs.size() - 1)).visible:
		get_node("Libro/Hojas/Hoja" + str(hjs.size() - 1)).visible = false
		get_node("Libro/Hojas/Hoja0").visible = true
	else:
		for h in range(hjs.size()):
			if hjs[h].visible:
				hjs[h].visible = false
				hjs[h + 1].visible = true
				break

func _on_Anterior_button_down():
	var hjs = get_node("Libro/Hojas").get_children()
	if get_node("Libro/Hojas/Hoja0").visible:
		get_node("Libro/Hojas/Hoja0").visible = false
		get_node("Libro/Hojas/Hoja" + str(hjs.size() - 1)).visible = true
	else:
		for h in range(hjs.size()):
			if hjs[h].visible:
				hjs[h].visible = false
				hjs[h - 1].visible = true
				break

func _on_LibroTime_timeout():
	var hjs = get_node("Libro/Hojas").get_children()
	for h in range(hjs.size()):
		if hjs[h].has_node("Titilante"):
			if hjs[h].get_node("Image1").visible:
				hjs[h].get_node("Image1").visible = false
				hjs[h].get_node("Image2").visible = true
			else:
				hjs[h].get_node("Image2").visible = false
				hjs[h].get_node("Image1").visible = true

func _on_Next_button_down():
	var aux
	var hjs = get_node("Libro/Hojas").get_children()
	for h in range(hjs.size()):
		if hjs[h].has_node("Video"):
			aux = hjs[h].get_node("Video")
			break
	if aux.frame >= aux.hframes - 1:
		aux.frame = 0
	else:
		aux.frame += 1

func _on_SubLibro_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_LEFT:
				CambiaLibro(false)

# para ver precios como tooltip

func PoneValor(referencia, dineroso=true, esEntra=false):
	if not dineroso:
		if (esEntra and antRef == "") or (not esEntra and referencia == antRef):
			if esEntra:
				get_node("Rtooltip").start()
				get_node("Value/ViSuave").visible = true
				for n in range(nameEdi.size()):
					if nameEdi[n] == referencia:
						get_node("Value/Valor").text = "$" + str(velInv[n])
						break
				antRef = referencia
			else:
				get_node("Rtooltip").start()
				get_node("Value/ViSuave").visible = false
				antRef = ""
	else:
		if (esEntra and antRef == "") or (not esEntra and referencia == antRef):
			if esEntra:
				get_node("Rtooltip").start()
				get_node("Value/ViSuave").visible = true
				get_node("Value/Valor").text = "$" + str(mundo.Costos(referencia))
				antRef = referencia
			else:
				get_node("Rtooltip").start()
				get_node("Value/ViSuave").visible = false
				antRef = ""

func _on_BCalle_mouse_entered():
	PoneValor("calle", true, true)

func _on_BCalle_mouse_exited():
	PoneValor("calle")

func _on_BEdificio_mouse_entered():
	PoneValor("Edificio", investiga[0] == 1, true)

func _on_BEdificio_mouse_exited():
	PoneValor("Edificio", investiga[0] == 1)

func _on_BOcio_mouse_entered():
	PoneValor("Ocio", investiga[1] == 1, true)

func _on_BOcio_mouse_exited():
	PoneValor("Ocio", investiga[1] == 1)

func _on_BCultivo_mouse_entered():
	PoneValor("Cultivo", investiga[2] == 1, true)

func _on_BCultivo_mouse_exited():
	PoneValor("Cultivo", investiga[2] == 1)

func _on_BTrabajo_mouse_entered():
	PoneValor("Trabajo", investiga[3] == 1, true)

func _on_BTrabajo_mouse_exited():
	PoneValor("Trabajo", investiga[3] == 1)

func _on_BPuerto_mouse_entered():
	PoneValor("Puerto", investiga[4] == 1, true)

func _on_BPuerto_mouse_exited():
	PoneValor("Puerto", investiga[4] == 1)

func _on_BHospital_mouse_entered():
	PoneValor("Hospital", investiga[5] == 1, true)

func _on_BHospital_mouse_exited():
	PoneValor("Hospital", investiga[5] == 1)

func _on_BTorre_mouse_entered():
	PoneValor("Torre", investiga[6] == 1, true)

func _on_BTorre_mouse_exited():
	PoneValor("Torre", investiga[6] == 1)

func _on_BEstudio_mouse_entered():
	PoneValor("Estudio", investiga[7] == 1, true)

func _on_BEstudio_mouse_exited():
	PoneValor("Estudio", investiga[7] == 1)

func _on_BJuego_mouse_entered():
	PoneValor("Juego", investiga[8] == 1, true)

func _on_BJuego_mouse_exited():
	PoneValor("Juego", investiga[8] == 1)

func _on_BParque_mouse_entered():
	PoneValor("Parque", investiga[9] == 1, true)

func _on_BParque_mouse_exited():
	PoneValor("Parque", investiga[9] == 1)

func _on_BCentro_mouse_entered():
	PoneValor("Centro", investiga[10] == 1, true)

func _on_BCentro_mouse_exited():
	PoneValor("Centro", investiga[10] == 1)

func _on_BDemolision_mouse_entered():
	PoneValor("demoler", true, true)

func _on_BDemolision_mouse_exited():
	PoneValor("demoler")

func _on_BNacer_mouse_entered():
	PoneValor("xnace", true, true)

func _on_BNacer_mouse_exited():
	PoneValor("xnace")

func _on_BDinamita_mouse_entered():
	if mundo.medalla[2] == 1:
		PoneValor("dinamita", true, true)

func _on_BDinamita_mouse_exited():
	PoneValor("dinamita")

func _on_BCaos_mouse_entered():
	# desconectada ya que el boton no cuesta
	PoneValor("caos", true, true)

func _on_BCaos_mouse_exited():
	# desconectada ya que el boton no cuesta
	PoneValor("caos")

func _on_Rtooltip_timeout():
	get_node("Value").visible = get_node("Value/ViSuave").visible

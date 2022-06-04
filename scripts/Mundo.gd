extends Node2D

# reloj dia 300 segundos
const debug = false
const debuMonsters = false # true elimina la espera apocaliptica de invasiones
const debugNodo = false # para pegar nodos calle al azar al incio en testeo
const dia_wait_time = 300.0 # duracion en segundos de un dia
const temporada = [0.666, 0.3] # porcentaje inicio de noche, oscuridad de la noce: 1 negro
const sEmpleo = [5, 8] # reloj ciclo buscar empleos disponibles
const sCongestion = [8, 12] # reloj ciclo para contar diamantes en calles
const sArboles = [60, 180] # reloj ciclo sembrar arboles
const camZoom = [0.5, 2.5] # minimo y maximo del zoom de la camara
const sFlores = [60, 120] # reloj ciclo sembrar flores
const maxArboles = 0.05 # densidad maxima para poblar con arboles
const semillaReproduccion = 225.0 # distancia a otro arbol o flor para germinar
const maxDinero = 10000 # limite de capacidad del banco
const monsterPorYear = 0.8 # probabilidad tratar de crear enemigo invasor por year
const incubacion = 3 # dias iniciales en que los diamantes son inmortales
const radioReserva = 374.0 # radio de la zona cultibable del parque
const densidadLluvia = 200 # numero de particulas de lluvia ante la camara
const alturaGota = 500.0 # altura a la que las gotas aparecen
const probabiLluvia = 0.2 # probabilidad de llover cada nuevo dia
const velGota = 200.0 # velocidad caida gotas
const velociCam = 600.0 # velocidad maxima de la camara al seguir
# dias para aparecer: guinxu, titan, jasperdev, sdev, virus, todohard
const apocalipsis = [23, 27, 14, 18, 31, 40]
# los nombres de todas las edificaciones
const edifiNames = ["Edificio", "Ocio", "Cultivo", "Trabajo", "Puerto", "Hospital", "Torre",
"Estudio","Juego", "Parque", "Centro"]

enum {numComida, numMercancia, numDinero, numArbol, numPoblacion, dieSalud, dieComida,
dieWar, dieLoco}
enum {tipSuelo, tipAire, tipAsomado, tipInterno, tipEstatico}
enum {stAnda, stCarga, stCome, stGuarece, stEscribe, stLee, stJuega, stVigila,
stPatrulla, stCultiva, stMina, stTrabaja, stPolitico, stMedico, stReposo,
stConstruye, stDemuele, stCompra, stDuerme, stRescata, stHabla, stBaila,
stRelaja, stVota, stEspera, stAzar, stHierba}

# catastrofe pandemia
const poblaVirus = [10, 69] # poblacion para eliminar virus, poblacion para crearlo
const respetoViral = 3 # cantidad de dias que no dara cuarentena desde ultima vez
var cuarentena = 0 # ultimo dia en que hubo infestacion
var amenazaVirus = false # para saber si habia virus antes de chequeo ciclico
# para testeo: muerte, locurajeringa, seautosana, contagiar, hospital
var conteoVirus = [0, 0, 0, 0, 0]

# jasperdev cosas
const jasperCaos = 6 # cantidad de jasperdev invocados por usuario

# sub constantes
var matrix = BitMap.new() # para definir tierra y agua
var tallMatrix = 0 # talla matrix, para asceso rapido
var celda = 0 # talla de la cuadricula
var loadBuilds = [] # matrix para pre cargar las construcciones
var manchis = [] # referencias para instanciar rapido manchas de explosion, humo y sonido
var elProyectil = null # referencia para instanciar rapido los proyectiles
var puntico = null # punto visual de color para el minimapa
var newDiamante = null # para load de diamante y acceso rapido
var losTramos = null # trozos de calle verdes
var exploSound = null # para instanciar rapido la sonida de explosion
var arbolSound = null # para instanciar rapido la sonida arbol cae
var gotiquita = null # para instanciar rapido las gotas
var lasombrita = null # para instanciar rapido las sombras
var musicas = [] # para guardar los audios del edificio de ocio
var marcoCam = Vector2(0, 0) # guardara la mitad de la talla para vista de camara
var marcoImagen = Rect2(0, 0, 0, 0) # para calculo rapido de imagenes en vista de camara
var goticas = [] # pooling de gotas de lluvia
var busIndecx = -1 # para acceso rapido al bus de efectos

# variables de calculos intermedios
var camSeguir = null # instancia a ser seguida por camara
var esDia = true # dice si es de dia o de noche
var aproxDiamantes = 0 # cantidad aproximada de diamantes
var comandoEscudo = false # guarda el estado de la herramienta comando
var anclaMouse = Vector2(0, 0) # para mover la camara
# segun estados del diamante
var empleo = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# variables importantes al guardar
var dia_time_left = dia_wait_time # contador para ver la hora del dia
var myLog = "" # informacion textual de la partida, historial de sucesos
var lloviendo = 0 # define el clima actual: 0:seco, 1:llueve, 2:escurre
var modoCaos = true # para ver si el usuario quiere tirarse las bombas encima
var introduccion = true # para hacer sonar saludo inicial de devalen
var edifiPuesto = [] # dira si ya se puso el primer edificio de cada uno
# comida mercancia dinero arbol poblacion dieSalud dieComida dieWar dieLoco
var conteoRecurso = [0, 0, 0, 0, 0, 0, 0, 0, 0]
# medallas obtenidas: guinxu, titan, jasperdev, sdev, virus, noone
var medalla = [0, 0, 0, 0, 0, 0]

# nota: el sistema de savegame por buffers es dificil de hackear, pero puede causar
# incompatibilidad de versiones facilmente, en comparacion a .ini o formato JSON

func _on_Mundo_tree_entered():
	randomize()

func _ready():
	elProyectil = load("res://scenes/otros/Proyectil.tscn")
	manchis.append(load("res://scenes/otros/Mancha.tscn"))
	manchis.append(load("res://scenes/otros/Demolision.tscn"))
	manchis.append(load("res://scenes/otros/DemolisionSonido.tscn"))
	puntico = load("res://scenes/otros/Puntico.tscn")
	newDiamante = load("res://scenes/moviles/Diamante.tscn")
	losTramos = load("res://scenes/otros/Tramo.tscn")
	exploSound = load("res://scenes/otros/ExploSonido.tscn")
	arbolSound = load("res://scenes/otros/ArbolSonido.tscn")
	gotiquita = load("res://scenes/otros/Gota.tscn")
	lasombrita = load("res://scenes/otros/Sombra.tscn")
	musicas.append(load("res://sounds/mu_davejf_freemusic.wav"))
	musicas.append(load("res://sounds/mu_farcusholton_almostsalsa.wav"))
	musicas.append(load("res://sounds/mu_jibey_rockmusic.wav"))
	musicas.append(load("res://sounds/mu_lenaorsa_passiontango.wav"))
	musicas.append(load("res://sounds/mu_mammo_electronic.wav"))
	musicas.append(load("res://sounds/mu_migfus20_rockmusic.wav"))
	musicas.append(load("res://sounds/mu_oymaldonado_salsaloopintro110bpm.wav"))
	musicas.append(load("res://sounds/mu_puredesigngirl_popmusic.wav"))
	busIndecx = AudioServer.get_bus_index("BusEfectos")
	marcoCam = get_viewport().size * 0.5 + Vector2(180, 360)
	LoadBuildings()
	get_node("HadaSiembra").start(rand_range(sArboles[0], sArboles[1]))
	get_node("HadaSopla").start(rand_range(sFlores[0], sFlores[1]))
	get_node("Congestion").start(rand_range(sCongestion[0], sCongestion[1]))
	get_node("VeEmpleo").start(rand_range(sEmpleo[0], sEmpleo[1]))
	get_node("ReMapa").start(rand_range(5, 7))
	get_node("Camara").position = get_node("Agua").rect_size * 0.5
	MoveGUI()

func NuevoMundo():
	AddEdificio(5) # aunque no halla edificios, minima poblacion (viviendas) es esta
	CreaMundo(get_parent().mapa)
	var creados = []
	while creados.empty():
		creados = CreaNatuales("solidos/Mina", 0.001, 0.002, 72, 0.6, creados)
	creados = CreaNatuales("solidos/Arbol", 0.01, maxArboles, 55, 0.75, creados)
	creados = CreaNatuales("otros/Flor", 0.03, 0.3, 36, 0.4, creados)
	for n in edifiNames:
		if n == "Edificio" or n == "Centro":
			edifiPuesto.append(true)
		else:
			edifiPuesto.append(false)
	CreaFauna("moviles/Tortuga", 0.002, 0.004, 4, 400)
	CreaDiamantes(10)
	AddDinero("inicial", true)
	Saludo(get_parent().mapa)
	get_node("GUI").CambiaMapa(get_parent().mapa)
	SonidoLen()
	CambiaCaos(modoCaos)
	get_node("GUI")._on_BInfo_button_down()
	# debug
	EstadisDebug()
	EstadisVirus()

func LoadBuildings():
	loadBuilds.append([])
	for n in edifiNames:
		loadBuilds[-1].append(load("res://scenes/solidos/" + n + ".tscn"))
	loadBuilds.append([])
	for n in edifiNames:
		loadBuilds[-1].append(load("res://scenes/andamios/C" + n + ".tscn"))
	loadBuilds.append([])
	for n in edifiNames:
		loadBuilds[-1].append(load("res://scenes/planes/P" + n + ".tscn"))

func _process(delta):
	#Ahorrografico()
	dia_time_left -= delta
	if dia_time_left <= 0:
		dia_time_left += dia_wait_time
		NuevoDia()
	var num = 1 - dia_time_left / dia_wait_time
	get_node("GUI/Fecha/Time").value = num * 100.0
	if num <= temporada[0] + 0.025:
		if not esDia:
			esDia = true
			get_node("Noche").modulate = Color(1, 1, 1, 0)
	else:
		if esDia:
			esDia = false
			get_node("Noche").modulate = Color(1, 1, 1, temporada[1])
	if num > temporada[0] and num < temporada[0] + 0.05:
		get_node("Noche").modulate = Color(1, 1, 1, temporada[1] * (num - temporada[0]) / 0.05)
	elif num > 0.95:
		get_node("Noche").modulate = Color(1, 1, 1, temporada[1] * (1 - (num - 0.95) / 0.05))
	SiguiendoCam(delta)
	Llovizna(delta)

func LimitaVirus():
	if Apocalipsis():
		return 0
	var diam = get_tree().get_nodes_in_group("diamante")
	if diam.size() <= poblaVirus[0]:
		for d in diam:
			d.Viral(false)

func SiguiendoCam(delta):
	if camSeguir == null:
		return 0
	elif not is_instance_valid(camSeguir):
		return 0
	if camSeguir.EsSeguible():
		var pos = camSeguir.global_position - Vector2(0, 70)
		var cam = get_node("Camara")
		var dir = cam.position.direction_to(pos)
		var dis = cam.position.distance_to(pos)
		cam.position += dir * min(dis, min(velociCam * delta, dis * 2.0 * delta))
		LimiteCamara()
	else:
		camSeguir = null

func Ahorrografico():
	var vvv = get_tree().get_nodes_in_group("imagen")
	var camP = get_node("Camara").position
	var camZ = marcoCam * get_node("Camara").zoom.x
	marcoImagen.position = camP - camZ
	marcoImagen.end = camP + camZ
	for v in vvv:
		v.visible = marcoImagen.has_point(v.global_position)

func _on_SeguirCam_timeout():
	if camSeguir == null:
		var diams = get_tree().get_nodes_in_group("diamante")
		if not diams.empty():
			camSeguir = diams[randi() % diams.size()]

func InfoVirus(ind):
	conteoVirus[ind] += 1

func EstadisVirus():
	if debug:
		var prnt = "VIRUS die:" + str(conteoVirus[0])
		prnt += " cura:" + str(conteoVirus[1])
		prnt += " sana:" + str(conteoVirus[2])
		prnt += " contagia:" + str(conteoVirus[3])
		prnt += " hospi:" + str(conteoVirus[4])
		print(prnt)
		for i in range(5):
			conteoVirus[i] = 0

func EstadisDebug():
	if debug:
		var prnt = "DIE salud:" + str(conteoRecurso[dieSalud])
		prnt += " comida:" + str(conteoRecurso[dieComida])
		prnt += " war:" + str(conteoRecurso[dieWar])
		prnt += " crazy:" + str(conteoRecurso[dieLoco])
		prnt += " TOT diam:" + str(get_tree().get_nodes_in_group("diamante").size())
		print(prnt)
		conteoRecurso[dieComida] = 0
		conteoRecurso[dieSalud] = 0
		conteoRecurso[dieWar] = 0
		conteoRecurso[dieLoco] = 0

func AddMuerteSalud():
	conteoRecurso[dieSalud] += 1

func AddMuerteComida():
	conteoRecurso[dieComida] += 1

func AddMuerteWar():
	conteoRecurso[dieWar] += 1

func AddMuerteLocura():
	conteoRecurso[dieLoco] += 1

func AddComida(val):
	conteoRecurso[numComida] += val
	get_node("GUI/Recursos/Alimentos/Num").text = str(conteoRecurso[numComida])

func AddMercancia(val):
	conteoRecurso[numMercancia] += val
	get_node("GUI/Recursos/Productos/Num").text = str(conteoRecurso[numMercancia])

func AddArbol(val):
	conteoRecurso[numArbol] += val
	get_node("GUI/Recursos/Arboles/Num").text = str(conteoRecurso[numArbol])

func AddEdificio(val):
	conteoRecurso[numPoblacion] += val
	get_node("GUI/Recursos/Edificios/Num").text = str(conteoRecurso[numPoblacion])

func GetPoblacion():
	return conteoRecurso[numPoblacion]

func Costos(referencia, refExt=""):
	var val = 0
	match referencia:
		"chuspa":
			val = 2 # cuando se compra en edificio
		"chuspita":
			val = 2 # cuando se guarda en ocio
		"copa":
			val = 2
		"baile":
			val = 1 if randf() < 0.25 else 0
		"guaro":
			val = 1 if randf() < 0.25 else 0
		"impuesto":
			if EsIncubadora():
				val = 10
			else:
				val = 1
		"subsidio":
			val = round(dia_wait_time * 0.1)
			val = val * 2 if EsIncubadora() else val
		"investigacion":
			val = int(get_node("GUI/Cientifik").wait_time) # precio cada que el reloj dispara
		"Parque":
			val = ValorMedio(30, referencia)
		"Edificio":
			val = ValorMedio(50, referencia)
		"Cultivo":
			val = ValorMedio(70, referencia)
		"Torre":
			val = ValorMedio(90, referencia)
		"Puerto":
			val = ValorMedio(120, referencia)
		"Juego":
			val = ValorMedio(180, referencia)
		"Ocio":
			val = ValorMedio(220, referencia)
		"Trabajo":
			val = ValorMedio(270, referencia)
		"Hospital":
			val = ValorMedio(310, referencia)
		"Estudio":
			val = ValorMedio(360, referencia)
		"Centro":
			val = ValorMedio(666, referencia)
		"calle":
			val = 10
		"demoler":
			val = 30 + round(Costos(refExt) * 0.25)
		"inicial":
			val = Costos("Edificio") + Costos("Cultivo") + Costos("Ocio") + Costos("subsidio")
			val += get_node("GUI").velInv[2] + get_node("GUI").velInv[1] # investiga cultivo ocio
			val *= 4 # mutiplicar el dinero base inicial pa que sea mas chevere
		"todo":
			val = conteoRecurso[2] # el dinero total que se tiene
		"nace":
			#var diam = get_tree().get_nodes_in_group("diamante").size()
			#val = 25 + round(pow(diam * 0.03, 2.0))
			val = 25
		"xnace":
			#val = 25 + round(pow(aproxDiamantes * 0.03, 2.0))
			val = 25
		"caos":
			# actualmente no cuesta la accion del boton, no se llamara
			val = max(30, ceil(conteoRecurso[2] * 0.1))
		"dinamita":
			#val = 15 + round(sqrt(aproxDiamantes * 4.2))
			val = 15
		"maximo":
			val = maxDinero
	return val

func ValorMedio(costo, referencia):
	for n in range(edifiNames.size()):
		if edifiNames[n] == referencia:
			if edifiPuesto[n]:
				return costo
			else:
				return int(costo / 2)

func AddDinero(referencia, esEntrante, refExt=""):
	var val = Costos(referencia, refExt)
	if esEntrante:
		conteoRecurso[numDinero] = min(maxDinero, conteoRecurso[numDinero] + val)
	else:
		conteoRecurso[numDinero] = max(0, conteoRecurso[numDinero] - val)
	get_node("GUI/Recursos/Dinero/Num").text = str(conteoRecurso[2])

func ValidaDinero(referencia, refExt=""):
	var val = Costos(referencia, refExt)
	return conteoRecurso[numDinero] - val >= 0

func Comprando(referencia, refExt=""):
	if ValidaDinero(referencia, refExt):
		AddDinero(referencia, false, refExt)
		return true
	return false

func EdificacionPuesta(referencia):
	for n in range(edifiNames.size()):
		if edifiNames[n] == referencia:
			edifiPuesto[n] = true
			break

func NuevoDia():
	var num = get_node("GUI/Fecha/Edad/Num")
	num.text = str(int(num.text) + 1)
	AddDinero("subsidio", true)
	EstadisDebug()
	EstadisVirus()
	LimitaVirus()
	# previene errores de estadisticas
	var totEdi = get_tree().get_nodes_in_group("ediEdificio").size()
	conteoRecurso[numPoblacion] = 5 + 5 * totEdi
	conteoRecurso[numArbol] = get_tree().get_nodes_in_group("arbol").size()
	conteoRecurso[numMercancia] = 0
	var edis = get_tree().get_nodes_in_group("ediTrabajo")
	for e in edis:
		conteoRecurso[numMercancia] += e.Cajas()
	conteoRecurso[numComida] = 0
	edis = get_tree().get_nodes_in_group("ediCultivo")
	for e in edis:
		conteoRecurso[numComida] += e.Comidas()
	edis = get_tree().get_nodes_in_group("ediOcio")
	for e in edis:
		conteoRecurso[numComida] += e.Copas()
		conteoRecurso[numMercancia] += e.Chuspas()
	# crear enemigos guinxu y sdev
	var prob = randi() % 3
	var aux
	var algo = false
	if EsApocalipsis(0) and randf() < monsterPorYear and prob <= 1:
		aux = load("res://scenes/otros/Nodriza.tscn").instance()
		get_node("Objetos").add_child(aux)
		algo = true
	if EsApocalipsis(3) and randf() < monsterPorYear and prob >= 1:
		aux = load("res://scenes/solidos/Cueva.tscn").instance()
		get_node("Objetos").add_child(aux)
		algo = true
	var alvas = 1.0 / exp(1.5 * get_tree().get_nodes_in_group("titan").size())
	if EsApocalipsis(1) and randf() < monsterPorYear and randf() < alvas:
		aux = load("res://scenes/moviles/Titan.tscn").instance()
		get_node("Objetos").add_child(aux)
		aux.ReUbicar()
		aux.Configura()
		algo = true
	CreaPeste(not algo)
	var d = get_tree().get_nodes_in_group("diamante").size()
	Log("Diamantes " + str(d) + " - $" + str(conteoRecurso[numDinero]))
	Log()
	Guardar("user://savegame.save")
	get_node("GUI/SDia").play()
	Llover()

func CreaPeste(activar):
	var diam = get_tree().get_nodes_in_group("diamante")
	var sick = false
	for d in diam:
		if d.virus:
			sick = true
			cuarentena = GetDia()
			break
	if not activar:
		return 0
	if EsApocalipsis(4) and randf() < monsterPorYear and not sick:
		if GetDia() - cuarentena >= respetoViral:
			get_node("Peste").start(randf() * dia_wait_time)

func _on_Peste_timeout():
	var diam = get_tree().get_nodes_in_group("diamante")
	if diam.size() > poblaVirus[1] or Apocalipsis():
		diam.shuffle()
		var tot = 0
		var cuantos = ceil(diam.size() * 0.1)
		for d in diam:
			if d.Virusear():
				tot += 1
				cuantos -= 1
				if cuantos <= 0:
					break
		if tot > 0:
			cuarentena = GetDia()
			amenazaVirus = true
			Log("pandemia JLPM con " + str(tot) + " iniciales")
			LaMedalla(4)
			get_node("GUI/SPandemia").play()

func SonidoLen(lista=[]):
	var soom = get_node("Camara").zoom.x
	var radioSound = get_viewport().size.x * soom
	if lista.empty():
		lista = get_tree().get_nodes_in_group("sonido")
		# limitar el sonido con la altura, 0 full, -6 a 1/2, -12 a 1/4, -18 a 1/8 (mitd d mitd 6)
		var volume = lerp(0, -16, (soom - camZoom[0]) / (camZoom[1] - camZoom[0]))
		AudioServer.set_bus_volume_db(busIndecx, volume)
	for li in lista:
		if li.is_in_group("supersonido"):
			li.max_distance = radioSound * 2.0
		else:
			li.max_distance = radioSound

func GetDia():
	return int(get_node("GUI/Fecha/Edad/Num").text)

func GetHora():
	var seg = GetDia() * dia_wait_time + (dia_wait_time - dia_time_left)
	var minut = seg / 60.0
	return minut / 60.0

func GetDate():
	var seg = round(dia_wait_time - dia_time_left)
	var date = get_node("GUI/Fecha/Edad/Num").text + ":" + str(seg)
	while date.length() < 7:
		date += " "
	return date + " -> "

func EsIncubadora():
	return GetDia() <= incubacion

func GetRiqueza():
	return conteoRecurso[numComida] + conteoRecurso[numMercancia]

func EsApocalipsis(ind):
	# guinxu, titan, jasperdev, sdev
	return GetDia() >= apocalipsis[ind] or debuMonsters

func Apocalipsis(forzado=false):
	return EsApocalipsis(5) and (modoCaos or forzado)

func CambiaCaos(caos):
	modoCaos = caos
	get_node("GUI/Ordenes/BCaos").visible = caos
	get_node("GUI/Ordenes/BLores").visible = not caos

func LaMedalla(ind):
	medalla[ind] = 1
	get_node("GUI").ActivaBuilds()

func Trofeo():
	for m in range(5):
		if medalla[m] == 0:
			return false
	return true

func Circulo(radio, tramo=40.0):
	var raCo = get_node("CircleComand")
	raCo.clear_points()
	var perimetro = 2.0 * PI * radio
	var paso = ceil(perimetro / tramo)
	var tramito = 2.0 * PI / paso
	for p in range(paso + 1):
		raCo.add_point(Vector2(radio, 0).rotated(p * tramito))

func _input(event):
	var cam = get_node("Camara")
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP:
				Zoom(-1)
			elif event.button_index == BUTTON_WHEEL_DOWN:
				Zoom(1)
			elif event.button_index == BUTTON_RIGHT:
				anclaMouse = get_global_mouse_position()
			elif event.button_index == BUTTON_MIDDLE:
				if get_node("GUI").visible:
					get_node("GUI")._on_BEyeOn_button_down()
			elif event.button_index == BUTTON_LEFT:
				ElegirSeguido(get_global_mouse_position())
				if Input.is_action_pressed("ui_hold"):
					DebugClic(get_global_mouse_position())
		else:
			if event.button_index == BUTTON_RIGHT:
				anclaMouse = Vector2(0, 0)
	elif event is InputEventMouseMotion:
		if anclaMouse.x != 0 and anclaMouse.y != 0 and not get_node("GUI/FileDialog").visible:
			cam.position += anclaMouse - get_global_mouse_position()
			LimiteCamara()

func ElegirSeguido(pos):
	if not get_node("SeguirCam").is_stopped():
		var diams = get_tree().get_nodes_in_group("diamante")
		camSeguir = null
		var minDis = get_viewport().size.y * get_node("Camara").zoom.y * 0.1
		var dis
		for d in diams:
			if d.EsSeguible():
				dis = d.global_position.distance_to(pos)
				if dis < minDis:
					minDis = dis
					camSeguir = d

func LimiteCamara():
	var cam = get_node("Camara")
	var tall = get_node("Agua").rect_size.x
	var camWH = get_viewport().size * cam.zoom * 0.5
	cam.position.x = clamp(cam.position.x, camWH.x, tall - camWH.x)
	cam.position.y = clamp(cam.position.y, camWH.y, tall - camWH.y)
	MoveGUI()

func Zoom(signo):
	if not get_node("GUI/FileDialog").visible:
		var cam = get_node("Camara")
		var desf = get_global_mouse_position() - cam.position
		var viej = cam.zoom.x
		cam.zoom += Vector2(0.1, 0.1) * signo
		if cam.zoom.x < camZoom[0]:
			cam.zoom = Vector2(camZoom[0], camZoom[0])
		elif cam.zoom.x > camZoom[1]:
			cam.zoom = Vector2(camZoom[1], camZoom[1])
		cam.position += desf * (1 - cam.zoom.x / viej)
		LimiteCamara()
		SonidoLen()

func SaltaCamara(posPorcent):
	var cam = get_node("Camara")
	var tall = get_node("Agua").rect_size.x
	cam.position = posPorcent * tall
	LimiteCamara()

func MoveGUI():
	var cam = get_node("Camara")
	var gui = get_node("GUI")
	var esq = get_node("Esquina")
	gui.rect_scale = cam.zoom
	gui.rect_position = cam.position - get_viewport().size * cam.zoom * 0.5
	esq.rect_scale = gui.rect_scale
	esq.rect_position = gui.rect_position
	# mover tambien en mini mapa
	var mimap = gui.get_node("Minimapa")
	var micam = mimap.get_node("Camara")
	micam.rect_scale = cam.zoom
	micam.rect_position = cam.position * 0.036 - micam.rect_pivot_offset
	# buscar diamante para hacer introduccion sonora
	if introduccion:
		var diams = get_tree().get_nodes_in_group("diamante")
		var pos = gui.rect_position + get_viewport().size * gui.rect_scale * 0.5
		var rad = get_viewport().size.y * gui.rect_scale.y * 0.25
		for d in diams:
			if d.global_position.distance_to(pos) < rad:
				get_node("GUI/SIntroduccion").play()
				introduccion = false
				break

func Llover():
	if get_node("TimeLluvia").is_stopped() and lloviendo == 0:
		if randf() < probabiLluvia:
			get_node("TimeLluvia").start(float() * dia_wait_time)

func UnProyectil():
	# obtiene un proyectil del pooling
	var uno = null
	var proys = get_tree().get_nodes_in_group("proyectil")
	for p in proys:
		if not p.activo:
			uno = p
			uno.Reconstructor()
			break
	if uno == null:
		uno = elProyectil.instance()
		get_node("Objetos").add_child(uno)
	return uno

func _on_TimeLluvia_timeout():
	if lloviendo == 0:
		get_node("TimeLluvia").start(rand_range(dia_wait_time * 0.25, dia_wait_time))
		lloviendo = 1
		get_node("SLuvia").play()
		for _r in range(densidadLluvia):
			goticas.append(gotiquita.instance())
			get_node("Objetos").add_child(goticas[-1])
			goticas[-1].get_node("Gotica").position.y = randf() * -alturaGota
	else:
		lloviendo = 2

func Llovizna(delta):
	if lloviendo != 0:
		var gotot
		var got
		var pos
		var aza
		if lloviendo == 1:
			aza = get_viewport().size * Vector2(camZoom[1], camZoom[1]) + Vector2(200, 200)
			pos = get_node("Camara").position - aza * 0.5 - Vector2(100, 0)
			aza += Vector2(100, alturaGota)
		for g in range(goticas.size() - 1, -1, -1):
			gotot = goticas[g]
			got = gotot.get_node("Gotica")
			got.position.y += velGota * delta
			gotot.position.x -= velGota * 0.25 * delta
			if got.position.y >= 0:
				if lloviendo == 1:
					got.modulate = Color(1, 1, 1, 0)
					got.position.y = -alturaGota
					gotot.position = pos + aza * Vector2(randf(), randf())
				else:
					gotot.queue_free()
					goticas.remove(g)
			else:
				got.modulate = Color(1, 1, 1, 1 - got.position.y / -alturaGota)
		if lloviendo == 2:
			if goticas.empty():
				lloviendo = 0
				get_node("SLuvia").stop()

func CreaMundo(ind):
	# encontrar talla de cuadricula
	celda = get_node("Tierra").cell_size.x
	# cargar la imagen de mapa segun indice
	var img = load("res://sprites/mapas/d_mapa" + str(ind) + ".png")
	img.lock()
	# encontrar datos de imagen y cuadricula discreta
	var tall_img = img.get_width()
	tallMatrix = ceil(get_node("Agua").rect_size.x / celda)
	var esc = float(tallMatrix) / tall_img
	# obtener el tilemap y asignarle los suelos
	var tima = get_node("Tierra")
	matrix.create(Vector2(tallMatrix, tallMatrix))
	for x in range(tallMatrix):
		for y in range(tallMatrix):
			if img.get_pixel(x / esc, y / esc).a > 0.5:
				tima.set_cell(x, y, randi() % 4)
				matrix.set_bit(Vector2(x, y), true)
	# actualizar el dibujado del tilemap
	tima.update_bitmask_region()
	tima.update_dirty_quadrants()

func CreaNatuales(nombre, areaMin, areaMax, radio, agrupar, preCreados=[]):
	var creados = preCreados
	var ente = load("res://scenes/" + nombre + ".tscn")
	var area = matrix.get_true_bit_count()
	var tall = get_node("Agua").rect_size
	var newpos
	var viepos
	var ok
	var freno
	var cluster = false
	for _a in range(max(1, ceil(rand_range(area * areaMin, area * areaMax)))):
		freno = area
		while freno > 0:
			freno -= 1
			if cluster:
				cluster = randf() < agrupar
				newpos = viepos + Vector2(0, randf() * 270).rotated(randf() * 2 * PI)
			else:
				newpos = Vector2(randf() * tall.x, randf() * tall.y)
			if EnTierra(newpos):
				ok = true
				for c in creados:
					if c.position.distance_to(newpos) < radio:
						ok = false
						break
				if ok:
					break
		if freno > 0:
			creados.append(ente.instance())
			get_node("Objetos").add_child(creados[-1])
			creados[-1].position = newpos
			viepos = newpos
			cluster = randf() < agrupar
	return creados

func CreaFauna(nombre, areaMin, areaMax, maxIntentos, vision):
	var ente = load("res://scenes/" + nombre + ".tscn")
	var arbolis = get_tree().get_nodes_in_group("arbol")
	var area = matrix.get_true_bit_count()
	var tall = get_node("Agua").rect_size
	var freno
	var newpos
	var mejorpos
	var mejortot
	var tot
	var dis
	var aux
	var intentos
	for _a in range(max(1, ceil(rand_range(area * areaMin, area * areaMax)))):
		mejortot = 0
		mejorpos = Vector2(0, 0)
		freno = ceil(arbolis.size() * 0.25)
		intentos = maxIntentos
		while freno > 0 and intentos > 0:
			freno -= 1
			newpos = Vector2(randf() * tall.x, randf() * tall.y)
			if EnTierra(newpos):
				tot = 0
				for t in arbolis:
					dis = newpos.distance_to(t.position)
					if dis < vision:
						if LineaTierra(newpos, dis, newpos.direction_to(t.position)):
							tot += 1
				if tot > mejortot:
					mejortot = tot
					mejorpos = newpos
					intentos -= 1
		if mejorpos.x != 0 or mejorpos.y != 0:
			aux = ente.instance()
			get_node("Objetos").add_child(aux)
			aux.position = mejorpos

func CreaDiamantes(tot):
	var ente = load("res://scenes/moviles/Diamante.tscn")
	var tall = get_node("Agua").rect_size
	var newpos
	var aux
	for _a in range(tot):
		while true:
			newpos = Vector2(randf() * tall.x, randf() * tall.y)
			if EnTierra(newpos):
				aux = ente.instance()
				get_node("Objetos").add_child(aux)
				aux.position = newpos
				for i in range(1, 6):
					aux.necesidad[i] = rand_range(0.5, 1)
				for i in range(6, 9):
					aux.necesidad[i] = rand_range(0, 0.5)
				break

func LineaTierra(pos, distan, direct):
	var paso = float(distan) / max(1, ceil(distan / (celda * 0.5)))
	var p = paso
	while p < distan:
		if not EnTierra(pos + direct * p):
			return false
		p += paso
	return true

func EnTierra(pos):
	var xy = (pos / celda).round()
	if xy.x < 0 or xy.y < 0 or xy.x >= tallMatrix or xy.y >= tallMatrix:
		return false
	return matrix.get_bit(xy)

func FreeSpace(pos):
	var ray = get_node("Rayote")
	ray.position = pos
	ray.force_raycast_update()
	return not ray.is_colliding()

func Enrraizado(pos):
	if EnTierra(pos):
		return FreeSpace(pos)
	return false

func QuitaNaturales():
	# disparado cuando se pone una edificacion nueva
	get_node("QuitNat").start()
	var quit = get_tree().get_nodes_in_group("quitable")
	for q in quit:
		q.get_node("Quitable").monitoring = true
	# ademas hacer que las calles se verifiquen
	var puertas = get_tree().get_nodes_in_group("puerta")
	for p in puertas:
		for i in range(p.verificar.size()):
			p.verificar[i] = true

func Explosion(pos, radio, esJasper=false):
	# poner sonido
	var sss = exploSound.instance()
	add_child(sss)
	sss.position = pos
	# tumbar edificacion mas cercana
	var otros
	var minDis
	var edi
	var dis
	if esJasper:
		otros = get_tree().get_nodes_in_group("explotable")
		minDis = radio
		edi = null
		for ot in otros:
			dis = ot.position.distance_to(pos)
			if dis < minDis:
				minDis = dis
				edi = ot
		if edi != null:
			if esJasper:
				Log("derribe de " + edi.nombre + " por JasperDev")
			else:
				Log("derribe de " + edi.nombre + " por explosion")
			edi.Destruir()
		# tumbar andamios
		otros = get_tree().get_nodes_in_group("ediAndamios")
		for ot in otros:
			if ot.position.distance_to(pos) < radio:
				ot.Destruir()
	# matar criaturas moviles
	otros = get_tree().get_nodes_in_group("movil")
	for ot in otros:
		if ot.tipo == tipSuelo:
			if ot.position.distance_to(pos) < radio:
				ot.Destructor()
	# tumbar vegetacion
	otros = get_tree().get_nodes_in_group("vegetal")
	for ot in otros:
		if ot.position.distance_to(pos) < radio:
			ot.Destruir()
	# tumbar titan
	otros = get_tree().get_nodes_in_group("titan")
	minDis = radio
	edi = null
	for ot in otros:
		dis = ot.position.distance_to(pos)
		if dis < minDis:
			minDis = dis
			edi = ot
	if edi != null:
		if esJasper:
			edi.Destructor()
		else:
			edi.Golpeado(true)

func _on_VeEmpleo_timeout():
	get_node("VeEmpleo").start(rand_range(sEmpleo[0], sEmpleo[1]))
	for e in range(empleo.size()):
		empleo[e] = 0
	# carga
	var culti = get_tree().get_nodes_in_group("ediCultivo")
	var traba = get_tree().get_nodes_in_group("ediTrabajo")
	var numTot = [0, 0, 0, 0]
	for c in culti:
		numTot[0] += c.Comidas()
	for t in traba:
		numTot[1] += t.Cajas()
	var ociu = get_tree().get_nodes_in_group("ediOcio")
	for o in ociu:
		numTot[2] += 4 - o.Copas()
		numTot[3] += 4 - o.Chuspas()
	var hospi = get_tree().get_nodes_in_group("ediHospital")
	for h in hospi:
		numTot[2] += h.EspacioComida()
	var tower = get_tree().get_nodes_in_group("ediTorre")
	for t in tower:
		numTot[3] += 4 - t.Balas()
	var maxTot = [min(numTot[0], numTot[2]), min(numTot[1], numTot[3])]
	empleo[stCarga] += maxTot[0] + maxTot[1]
	# escribe
	var estudy = get_tree().get_nodes_in_group("ediEstudio")
	for c in estudy:
		if c.WorkOk() != null:
			empleo[stEscribe] += 1
	# vigila y patrulla
	var torris = 0
	for c in tower:
		if c.WorkOk() != null:
			empleo[stVigila] += 1
		if c.Activo():
			torris += 1
	empleo[stVigila] += max(0, torris * 4.0 - WorkMilicia())
	# cultiva
	for c in culti:
		empleo[stCultiva] += c.Vacantes()
	# trabaja
	for c in traba:
		empleo[stTrabaja] += c.Vacantes()
	# mina
	var edif = get_tree().get_nodes_in_group("diamantino")
	for c in edif:
		if c.HayWorkMinero():
			empleo[stMina] += 1
	# medico y rescata
	var vacunas = 0
	var hospis = 0
	for c in hospi:
		if c.WorkOk() != null:
			empleo[stMedico] += 1
		vacunas += max(0, c.Jeringas() - c.reservaVacuna)
		if c.Activo():
			hospis += 1
	empleo[stRescata] += max(0, min(vacunas, hospis * 2.0) - WorkEnfermeros())
	# construye y demuele
	var andamios = get_tree().get_nodes_in_group("ediAndamios")
	for c in andamios:
		empleo[stDemuele] += c.Vacantes(true)
		empleo[stConstruye] += c.Vacantes(false)

func WorkMilicia():
	var diam = get_tree().get_nodes_in_group("diamante")
	var soldados = 0
	for d in diam:
		if d.Armado():
			if d.tipo == tipEstatico:
				if d.get_parent().name != "Guardia":
					soldados += 1
			else:
				soldados += 1
	return soldados

func WorkEnfermeros():
	var diam = get_tree().get_nodes_in_group("diamante")
	var enfermeros = 0
	for d in diam:
		if d.EsEnfermero():
			enfermeros += 1
	return enfermeros

func _on_QuitNat_timeout():
	# para que arboles y flores no detecten colision todo el tiempo
	var quit = get_tree().get_nodes_in_group("quitable")
	for q in quit:
		q.get_node("Quitable").monitoring = false

func _on_Congestion_timeout():
	# calcula la congestion de las calles
	get_node("Congestion").start(rand_range(sCongestion[0], sCongestion[1]))
	var puertas = get_tree().get_nodes_in_group("puerta")
	var diamantes = get_tree().get_nodes_in_group("diamante")
	aproxDiamantes = diamantes.size()
	for p in puertas:
		p.congestion = 0
	var minDis
	var dis
	var prt
	# se aprovecha este for para revisar si ha pasado la pandemia
	var hayVirus = false
	for d in diamantes:
		if d.virus:
			hayVirus = true
		if d.EsSuelo():
			minDis = pow(96, 2)
			prt = null
			for p in puertas:
				dis = d.position.distance_squared_to(p.global_position)
				if dis < minDis:
					minDis = dis
					prt = p
			if prt != null:
				prt.congestion += 32
	# hacer sonar algo si paso la pandemia
	if not hayVirus and amenazaVirus:
		amenazaVirus = false
		get_node("GUI/SCurados").play()

func InvocaCaos():
	# funcion no utilizada, disenno viejo del juego
	if ValidaDinero("caos"):
		# peso probabilidad: 0:guinxu, 1:alva, 2:jasper, 3:sdev, 4:pandemia
		var prob = [7, 3, 2, 5, 1]
		var casos = []
		for i in range(prob.size()):
			for _r in range(prob[i]):
				casos.append(i)
		var aux
		match casos[randi() % casos.size()]:
			0: # guinxu
				aux = load("res://scenes/otros/Nodriza.tscn").instance()
				get_node("Objetos").add_child(aux)
				aux.Invasion()
			1: # alva
				aux = load("res://scenes/moviles/Titan.tscn").instance()
				get_node("Objetos").add_child(aux)
				aux.ReUbicar()
				aux.Invasion()
			2: # jasper
				var diam = get_tree().get_nodes_in_group("diamante")
				var deseado = jasperCaos
				var quienes = []
				for d in diam:
					if d.EsBlanco():
						quienes.append(d)
						deseado -= 1
						if deseado <= 0:
							break
				if quienes.size() == jasperCaos:
					for d in quienes:
						d.Jasperize()
					Log("invoke " + str(jasperCaos) + " JasperDev")
					Comprando("caos")
			3: # sdev
				aux = load("res://scenes/solidos/Cueva.tscn").instance()
				get_node("Objetos").add_child(aux)
				aux.Invasion()
			4: # pandemia
				var diam = get_tree().get_nodes_in_group("diamante")
				diam.shuffle()
				var tot = 0
				var cuantos = ceil(diam.size() * 0.1)
				for d in diam:
					if d.Virusear():
						tot += 1
						cuantos -= 1
						if cuantos <= 0:
							break
				if tot > 0:
					cuarentena = GetDia()
					Log("invoke pandemia JLPM con " + str(tot) + " iniciales")
					Comprando("caos")

func HumoDemolision(objeto):
	var ppp = objeto.get_node("Fin").get_children()
	ppp.shuffle()
	var pos = Vector2(0, 0)
	var aux
	for p in ppp:
		aux = manchis[1].instance()
		get_node("Objetos").add_child(aux)
		aux.position = p.global_position
		pos += aux.position
		if EnTierra(p.global_position):
			aux = manchis[0].instance()
			get_node("Manchas").add_child(aux)
			aux.position = p.global_position
	aux = manchis[2].instance()
	add_child(aux)
	aux.position = pos / ppp.size()

func _on_ReMapa_timeout():
	get_node("ReMapa").start(rand_range(5, 7))
	var esc = get_node("GUI/Minimapa").rect_size.x / get_node("Agua").rect_size.x
	var raiz = get_node("GUI/Minimapa/Puntos")
	var puntos = raiz.get_children()
	for p in puntos:
		# los puntos invisibles actuan como pooling para estar listos en memoria
		p.visible = false
	var aux
	var arboles = get_tree().get_nodes_in_group("arbol")
	for a in arboles:
		aux = NewPunto(puntos, raiz)
		aux.rect_position = a.position * esc
		aux.modulate = Color(0.9, 0.9, 0.1, 0.7)
	var mines = get_tree().get_nodes_in_group("mina")
	for m in mines:
		aux = NewPunto(puntos, raiz)
		aux.rect_position = m.position * esc
		aux.modulate = Color(0.1, 0.1, 0.8, 0.7)
	var cosas = get_tree().get_nodes_in_group("ediffice")
	for c in cosas:
		aux = NewPunto(puntos, raiz)
		aux.rect_position = c.position * esc
		aux.modulate = Color(0.9, 0.1, 0.1, 0.7)
	var alvas = get_tree().get_nodes_in_group("titan")
	for a in alvas:
		aux = NewPunto(puntos, raiz)
		aux.rect_position = a.position * esc
		aux.modulate = Color(0.2, 0.2, 0.2, 0.6)
		aux.rect_scale = Vector2(0.1, 0.1)

func NewPunto(puntos, raiz):
	# se buscan puntos en el pooling o se crean nuevos si no hay disponibles
	var uno = null
	for p in puntos:
		if not p.visible:
			uno = p
			uno.visible = true
			break
	if uno == null:
		uno = puntico.instance()
		raiz.add_child(uno)
	uno.rect_scale = Vector2(0.15, 0.15)
	return uno

func PegaNodosAll():
	# esta funcion solo se usa con propositos de debug
	var calles = get_tree().get_nodes_in_group("calle")
	var tll = calles.size()
	var ray
	if tll >= 2:
		var p1
		var p2
		var ini
		var fin
		for c in range(tll - 1):
			ini = calles[c].get_node("Puerta")
			for u in range(c + 1, tll):
				fin = calles[u].get_node("Puerta")
				p1 = ini.global_position
				p2 = fin.global_position
				if LineaTierra(p1, p1.distance_to(p2), p1.direction_to(p2)):
					ray = ini.get_node("Ray")
					ray.cast_to = p2 - p1
					ray.force_raycast_update()
					if not ray.is_colliding():
						ini.Conectar(fin, true)
						fin.Conectar(ini, true)
						break
		QuitaNaturales()
	var puertos = get_tree().get_nodes_in_group("ediPuerto")
	if puertos.size() == 2:
		var ini1 = puertos[0].get_node("Puerta")
		var ini2 = puertos[1].get_node("Puerta")
		var fin1 = null
		var fin2 = null
		for c in calles:
			if fin1 == null:
				if ini2.global_position.distance_to(c.position) < ini2.disPorton:
					fin1 = c.get_node("Puerta")
			if fin2 == null:
				if ini1.global_position.distance_to(c.position) < ini1.disPorton:
					fin2 = c.get_node("Puerta")
		ini1.Conectar(fin1, true, 2)
		fin1.Conectar(ini1, true, 2)
		ini2.Conectar(fin2, true, 2)
		fin2.Conectar(ini2, true, 2)

func _on_PostReady_timeout():
	if debugNodo:
		PegaNodosAll()

func _on_HadaSiembra_timeout():
	get_node("HadaSiembra").start(rand_range(sArboles[0], sArboles[1]))
	var pos = get_node("Agua").rect_size * Vector2(randf(), randf())
	if EnTierra(pos):
		var arbis = get_tree().get_nodes_in_group("arbol")
		var pp
		var veci = false
		var ok = true
		for a in arbis:
			pp = a.position.distance_to(pos)
			if pp < 55:
				ok = false
				break
			if pp < semillaReproduccion:
				veci = true
		if ok and veci:
			var aux = load("res://scenes/solidos/Arbol.tscn").instance()
			get_node("Objetos").add_child(aux)
			aux.position = pos
			QuitaFlor([aux])
			QuitaNaturales()

func QuitaFlor(arbis=[]):
	var flores = get_tree().get_nodes_in_group("flor")
	if arbis.empty():
		arbis = get_tree().get_nodes_in_group("arbol")
	var ok
	for f in flores:
		ok = false
		for a in arbis:
			if a.position.distance_to(f.position) < 36:
				ok = true
				break
		if ok:
			f.queue_free()

func _on_HadaSopla_timeout():
	randomize()
	var ok = true
	get_node("HadaSopla").start(rand_range(sFlores[0], sFlores[1]))
	var pos = get_node("Agua").rect_size * Vector2(randf(), randf())
	if EnTierra(pos):
		var vegeta = get_tree().get_nodes_in_group("vegetal")
		var pp
		var veci = false
		for v in vegeta:
			pp = v.position.distance_to(pos)
			if pp < 36:
				ok = false
				break
			if pp < semillaReproduccion:
				veci = true
		if ok and veci:
			var aux = load("res://scenes/otros/Flor.tscn").instance()
			get_node("Objetos").add_child(aux)
			aux.position = pos
			QuitaNaturales()
			ok = false
	if ok:
		QuitaNaturales()

func Abrir(nameFile):
	var file = File.new()
	if file.open(nameFile, File.READ) != OK:
		return false
	var buf = StreamPeerBuffer.new()
	buf.data_array = file.get_buffer(file.get_len())
	file.close()
	# informacion general de la partida
	var _grabage = buf.get_string() # version, puede ponerse que compare con la actual
	get_parent().mapa = buf.get_u8()
	CreaMundo(get_parent().mapa)
	get_node("GUI").CambiaMapa(get_parent().mapa)
	get_node("GUI/Fecha/Edad/Num").text = str(buf.get_u16())
	dia_time_left = buf.get_float()
	for m in range(medalla.size()):
		medalla[m] = buf.get_u8()
	for r in range(conteoRecurso.size()):
		conteoRecurso[r] = buf.get_u16()
	for i in range(get_node("GUI").investiga.size()):
		get_node("GUI").investiga[i] = buf.get_float()
	cuarentena = buf.get_u16()
	var ll = buf.get_float()
	if ll != 0:
		_on_TimeLluvia_timeout()
		get_node("TimeLluvia").start(ll)
	var b = buf.get_u8() != 0
	CambiaCaos(b)
	introduccion = buf.get_u8() != 0
	get_node("GUI").ActivaBuilds()
	AddDinero("", true)
	for _n in edifiNames:
		b = buf.get_u8() != 0
		edifiPuesto.append(b)
	# agregar cosas del medio ambiente
	DeslistaCosas(buf, "solidos/Mina")
	DeslistaCosas(buf, "solidos/Arbol")
	DeslistaCosas(buf, "otros/Flor")
	DeslistaCosas(buf, "moviles/Tortuga")
	DeslistaCosas(buf, "otros/Calle")
	# agregar criaturas moviles y objetos importantes
	DeslistaMoviles(buf, "moviles/Diamante")
	DeslistaMoviles(buf, "otros/Nodriza")
	DeslistaMoviles(buf, "moviles/Guinxu")
	DeslistaMoviles(buf, "solidos/Cueva")
	DeslistaMoviles(buf, "moviles/Sdev")
	DeslistaMoviles(buf, "moviles/Jasperdev")
	DeslistaMoviles(buf, "moviles/Titan")
	DeslistaEdificios(buf)
	var totEdi = get_tree().get_nodes_in_group("ediEdificio").size()
	conteoRecurso[numPoblacion] = 5 + 5 * totEdi
	# agregar la informacion de conexion de puertas
	DeslistaPuertas(buf)
	# adjuntar el historial de sucesos
	myLog = buf.get_string()
	SonidoLen()
	Log()
	return true

func DeslistaCosas(buffer, path):
	var tot = buffer.get_u16()
	var ente = load("res://scenes/" + path + ".tscn")
	var aux
	for _r in range(tot):
		aux = ente.instance()
		get_node("Objetos").add_child(aux)
		aux.position.x = buffer.get_float()
		aux.position.y = buffer.get_float()

func DeslistaMoviles(buffer, path):
	var tot = buffer.get_u16()
	var ente = load("res://scenes/" + path + ".tscn")
	var aux
	for _r in range(tot):
		aux = ente.instance()
		get_node("Objetos").add_child(aux)
		aux.Open(buffer)

func DeslistaEdificios(buffer):
	var tot = buffer.get_u16()
	var aux
	for _r in range(tot):
		if buffer.get_u8() != 0:
			aux = loadBuilds[0][buffer.get_u8()].instance()
		else:
			aux = loadBuilds[1][buffer.get_u8()].instance()
		get_node("Objetos").add_child(aux)
		aux.Open(buffer)

func DeslistaPuertas(buffer):
	var prt = get_tree().get_nodes_in_group("puerta")
	var tot = buffer.get_u32()
	var posP = Vector2(0, 0)
	var _garbage
	var subtot
	var ok
	for _r in range(tot):
		posP.x = buffer.get_float()
		posP.y = buffer.get_float()
		ok = false
		for p in prt:
			if p.global_position.x == posP.x and p.global_position.y == posP.y:
				p.Open(buffer, prt)
				ok = true
				break
		if not ok:
			subtot = buffer.get_u16()
			for _b in range(subtot):
				_garbage = buffer.get_u8()
				_garbage = buffer.get_float()
				_garbage = buffer.get_float()

func Guardar(nameFile):
	var file = File.new()
	if file.open(nameFile, File.WRITE) != OK:
		return false
	var buf = StreamPeerBuffer.new()
	# informacion general de la partida
	buf.put_string(get_parent().version)
	buf.put_u8(get_parent().mapa)
	buf.put_u16(GetDia())
	buf.put_float(dia_time_left)
	for m in medalla:
		buf.put_u8(m)
	for r in conteoRecurso:
		buf.put_u16(r)
	for i in get_node("GUI").investiga:
		buf.put_float(i)
	buf.put_u16(cuarentena)
	var ll = get_node("TimeLluvia").time_left if lloviendo == 1 else 0
	buf.put_float(ll)
	var b = 1 if modoCaos else 0
	buf.put_u8(b)
	b = 1 if introduccion else 0
	buf.put_u8(b)
	for n in edifiPuesto:
		b = 1 if n else 0
		buf.put_u8(b)
	# agregar cosas del medio ambiente
	EnlistaCosas(buf, "mina")
	EnlistaCosas(buf, "arbol")
	EnlistaCosas(buf, "flor")
	EnlistaCosas(buf, "tortuga")
	EnlistaCosas(buf, "calle")
	# agregar criaturas moviles y objetos importantes
	EnlistaMoviles(buf, "diamante")
	EnlistaMoviles(buf, "nodriza")
	EnlistaMoviles(buf, "guinxu")
	EnlistaMoviles(buf, "cueva")
	EnlistaMoviles(buf, "sdev")
	EnlistaMoviles(buf, "jasperdev")
	EnlistaMoviles(buf, "titan")
	EnlistaMoviles(buf, "ediffice")
	# agregar la informacion de conexion de puertas
	var prt = get_tree().get_nodes_in_group("puerta")
	buf.put_u32(prt.size())
	for p in prt:
		p.Save(buf)
	# adjuntar el historial de sucesos
	buf.put_string(myLog)
	# guardar en el archivo
	file.store_buffer(buf.data_array)
	file.close()
	return true

func EnlistaCosas(buffer, namecosa):
	var cosa = get_tree().get_nodes_in_group(namecosa)
	buffer.put_u16(cosa.size())
	for c in cosa:
		buffer.put_float(c.position.x)
		buffer.put_float(c.position.y)

func EnlistaMoviles(buffer, namemovil):
	var cosa = get_tree().get_nodes_in_group(namemovil)
	buffer.put_u16(cosa.size())
	for c in cosa:
		c.Save(buffer)

func Log(texto="", poneDate=true):
	if texto == "":
		var file = File.new()
		if file.open("user://historial.txt", File.WRITE) == OK:
			file.store_string(myLog)
			file.close()
	elif poneDate:
		myLog += GetDate() + texto + "\n"
	else:
		myLog += texto + "\n"

func Saludo(ind):
	myLog = ""
	var d = OS.get_datetime(true)
	var fecha = str(d["day"]) + "/" + str(d["month"]) + "/" + str(d["year"])
	fecha += "-" + str(d["hour"]) + ":" + str(d["minute"]) + "-UTC"
	Log("DAOK v" + get_parent().version, false)
	Log("citybuilder by Omwekiatl 2022", false)
	Log("videogame fan-art to DEValen, Guinxu, JasperDev, AlvaMajo, S-Dev, JLPM", false)
	Log(fecha + " map:" + str(ind), false)
	Log(" ", false)
	Log()

func DebugClic(posMous):
	if debug:
		var _p = posMous

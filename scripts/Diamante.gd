extends Node2D

const debug = false
const velociSuelo = [100.0, 50.0] # rapidez al andar por suelo y su bonus de mejora
const velociVuelo = 150.0 # rapidez al andar por el aire en globo
const visionFull = [300.0, 100.0] # distancia de vision y su bonus de mejora
const disMele = 100.0 # distancia ataque cuerpo a cuerpo
const escudo = 0.6 # probabilidad de aguantar un golpe
const persistencia = 4 # intentos de encontrar un edificio para suplir necesidad
const borracho = 0.17 # unos 10 grados en radianes, para dar tumbos al andar
const upDownVuelo = [50.0, 75.0] # velocidad ascenso y descenso
const disPnt = 24.0 # distancia para considerar que llego a un punto
const disEnte = 40.0 # distancia para considerar cercania a personaje o cosa
const bisco = 0.17 # radianes de desfase aleatorio al disparar
const verEnemigos = 0.5 # probabilidad civil ve enemigos para huir, cada que hace busqueda
const rangoPelea = [0.5, 0.75] # porcentaje de radio de vision donde mantenerse en pelea
const probReBuscar = 0.3 # probabilidad volver a realizar busqueda ya exitosa
const probQuitaObj = 0.5 # probabilidad de quitar objeto innecesario
const towerDifference = 500.0 # distancia entre torres con y sin municion para elegir
const microRevision = 0.1 # probabilidad baja para calculos lentos
const radioProtesta = 220.0 # distancia en torno al centro urbano para protestar
const paramErrar = [0.333, 0.666, 90.0] # al errar: probabi inv moverse, detenerse, giro max
const probDialogo = 0.5 # probabilidad de mostrar dialogo
const probNoProtesta = 0.3 # probabilidad quitar carteles protesta
const felizDesove = [0.15, 0.9] # minimo y maxino nivel de felicidad para reproducirse
const valorHijo = 0.3 # costo del hijo en comida, se le suma la carencia
const mutacion = 0.1 # probabilidad personalidad de hijo aleatoria
const politiGod = 0.1 # aumento de estadisticas de necesidad en politico en podio
const devolverLibro = 0.2 # probabilidad de devolver libro a estudio luego de leerlo
const valorCopa = 0.25 # cuanta necesidad +diversion -trabajo afecta la compra
const valorBolsa = 0.5 # cuanta necesidad +diversion -trabajo afecta la compra
const valorCarga = 0.3 # aumento de necesidad de trabajo cuando entrega cargamento
const bonusHippie = 0.12 # aumenta la energia una vez cuando va a hippiar al parque
const arbolComida = 6 # cantidad de arboles que considera como fuente de alimento
const sMonologo = 5 # segundos que dura el cuadro de texto cuando 0 necesidad social
const saturaSound = 0.5 # probabilidad de sonar efectos recurrentes del personaje
const sComer = [5, 15] # tiempo para estar en edificio ocio cuando compra copa
const sLee = [15, 30] # tiempo para estar en edificio educacion cuando compra libro
const sCompra = [8, 16] # tiempo para estar en edificio ocio cuando compra bolsa
const sBuscaCharla = [10, 20] # tiempo para andar buscando con quien hablar
const sReposo = [11, 22] # tiempo para reposar en el hospital
const sWait = [9, 16] # tiempo en estado de espera, parado por ahi
const sEsquive = [2, 4] # reloj ciclo para esquive social
const sNesReloj = [4, 6] # reloj ciclo de calculo de necesidades
const sErrar = [1, 5] # reloj ciclo para andar al azar
const sBuscador = [3, 5] # reloj ciclo buscar cosas o entes con la vista
const sAtasco = [10, 15] # reloj ciclo evitar atascos al andar
const sPolitic = [15, 30] # tiempo de estar el politico en el podio
const sEspera = [5, 10] # tiempo para quedarse quieto porque si
const sBuskar = [0.5, 1.5] # tiempo ciclo para activar buscador de destinos
const sDispara = [3, 4] # tiempo ciclo rafaga de disparos, cadencia
# seguridad, salud, comida, energia, social, diversion, trabajo, fisico, intelecto
const nesecityGo = [-0.5, -0.075, -0.015, -0.015, -0.05, -0.02, -0.02, -0.01, -0.01]
const reestablece = [0.12, 0.5, 0.2, 0.0555, 0.2, 0.15, 0.069, 0.1, 0.1]
const carencia = [1.0, 0.25, 0.15, 0.15, 0.1, 0.3, 0.3, 0.2, 0.2]
const pesoFeliz = [0.3, 0.3, 0.5, 0.5, 0.8, 0.7, 0.7, 0.9, 0.9]

enum {tipSuelo, tipAire, tipAsomado, tipInterno, tipEstatico}
enum {stAnda, stCarga, stCome, stGuarece, stEscribe, stLee, stJuega, stVigila,
stPatrulla, stCultiva, stMina, stTrabaja, stPolitico, stMedico, stReposo,
stConstruye, stDemuele, stCompra, stDuerme, stRescata, stHabla, stBaila,
stRelaja, stVota, stEspera, stAzar, stHierba}
enum {objNull, objCopa, objVacuna, objBolsa, objCaja, objBomba, objCartel, objMina,
objLibro, objEscudoPro, objEscudo, objRojo, objGuaro}
enum {nesSeguridad, nesSalud, nesComida, nesEnergia, nesSocial, nesDiversion,
nesTrabajo, nesFisico, nesIntelecto}
enum {persHouse, persWork, persAll}

var tipo = tipSuelo # modo de desplazamiento o anclaje a punto
var estado = stAnda # comportamiento actual
var colision = [[], [], [], [], []] # 0:solido, 1:movil, 2:aire, 3:perseguir, 4:huir
var mundo = null # nodo maestro para asceso rapido
var limirec = Vector2(0, 0) # limites del marco del mundo
var anterior = Vector2(0, 0) # posicion previa para mantenerse en tierra
var mover = false # true si esta en movimiento al errar
var direccion = Vector2(0, 0) # direccion al errar
var esqSocio = true # para evitar embotellamiento, colision intermitente
var aterrizaje = Vector2(0, 0) # coordenadas de llegada en globo
var altura = 0 # 0:subiendo, 1:volando, 2:bajando
var aniPaso = false # hacer cambio de animacion
var meta = [null, null] # nodo puerta a donde ir: calle y build
var next = [null, null] # nodo proximo para llegar a meta: calle y build
var sombrita = null # sombra del personaje
var antiAtascoPos = Vector2(0, 0) # para evitar estancamiento
var necesidad = [] # conteo 0 a 1 segun cada necesidad
var felicidad = 1 # conteo 0 a 1 dependiendo de todas las necesidades
var frustracion = 0 # contador para intentar hacer algo
var blanco = null # objeto objetivo a donde ir o seguir
var supervivencia = 0 # para estado come, 0:ocio, 1:cultivo, 2:cultivo-trabajo
var protesta = -1 # ind segun la necesidad que presenta problemas, ej: nesComida
var buscaActiva = true # para hacer intermitente la labor de busqueda, optimizar
var guardaBala = false # cuando entra a torre con la municion puesta
var tomaGuaro = false # para saber si compro el guaro o lo esta transportando
var lugarEntrega = "" # nombre de grupo de edificacion a donde ir a entregar
var busEmple = false # para saber si esta buscando empleo activamente
var reclutar = true # cuando lleva arma en mano, saber si trabajara de patrulla o regresa arma
var monologo = false # poner a true para que reloj esquivesocial desactive dialogo
var caracter = false # dos tipos de personalidades, true fisico o false intelectual
var ultima = null # ultimo nodo puerta alcanzado o next
var critico = false # para ver si llego a buscar el trabajo por necesidad
var posComando = Vector2(0, 0) # lugar a donde ir ordenado por el usuario
var compannia = [] # bools para calcular aislamiento del diamante, todo en false es solo

# para pandemia viral jlmp
const debilidad = 0.7 # porcentaje a partir del cual se contagia y gravedad inicial de enfermedad
var virus = false # para saber si tiene virus o no
var tosiendo = false # para saber si esta expulsando particulas y cambiar eso

# para enemigos loco jasperdev
const poblaLocos = 33 # valor de poblacion a partir del cual aparecen jasperdev
const azaEnloquecer = 0.9 # probabilidad enloquecerse si no hay diversion
var enloquecer = false # flag para cuando muera por temporizador y locura

func _ready():
	caracter = randf() < 0.5
	mundo = get_tree().get_nodes_in_group("mundo")[0]
	sombrita = mundo.lasombrita.instance()
	mundo.get_node("Sombras").add_child(sombrita)
	limirec = mundo.get_node("Agua").rect_size
	for _n in range(5):
		necesidad.append(1)
	for _n in range(4):
		necesidad.append(0)
	compannia = [false, false, false]
	get_node("EsquiveSocial").start(rand_range(sEsquive[0], sEsquive[1]))
	get_node("Errar").start(rand_range(sErrar[0], sErrar[1]))
	get_node("NecesiReloj").start(rand_range(sNesReloj[0], sNesReloj[1]))
	get_node("AntiAtasco").start(rand_range(sAtasco[0], sAtasco[1]))
	get_node("Buscador").start(rand_range(sBuscador[0], sBuscador[1]))
	get_node("PaBuscar").start(rand_range(sBuskar[0], sBuskar[1]))
	get_node("Disparador").start(rand_range(sDispara[0], sDispara[1]))
	get_node("Anima").play("idle")
	CambiaTipo(tipSuelo)
	mundo.SonidoLen([get_node("SHola"), get_node("STos"), get_node("SProtesta"),
	get_node("SCharla"), get_node("SGuardia"), get_node("SHulle")])
	if debug:
		get_node("Imagen/Prg").visible = true
	else:
		get_node("Imagen/Prg").queue_free()

func _process(delta):
	match tipo:
		tipSuelo:
			anterior = position
			var ok = not Rebote(0, delta)
			if ok and esqSocio:
				ok = not Rebote(1, delta)
			if ok and posComando.x != 0:
				ok = false
				position += position.direction_to(posComando) * velocidad() * delta
				if position.distance_to(posComando) < disPnt:
					posComando = Vector2(0, 0)
			if ok and Temor(true):
				ok = not Perseguir(delta)
			if ok and Temor() and estado != stPatrulla and estado != stVigila:
				ok = not Rebote(4, delta, true)
			if ok:
				Estados(delta)
			Limites(delta)
		tipAire:
			if altura == 1:
				if not Rebote(2, delta):
					Volar(delta)
				Limites(delta)
			else:
				Volar(delta)
		tipInterno:
			anterior = position
			if not Rebote(1, delta):
				Errar(delta)
			Limites(delta)
		_: # asomado y estatico
			if aniPaso:
				get_node("Anima").play("idle", -1, 1)
				aniPaso = false

func Rebote(ind, delta, esHuir=false):
	var rebote = Vector2(0, 0)
	if esHuir:
		for c in colision[ind]:
			if c.is_in_group("titan"):
				rebote += c.position.direction_to(position) * 4.0
			else:
				rebote += c.position.direction_to(position)
	else:
		for c in colision[ind]:
			rebote += c.position.direction_to(position)
	if rebote.x != 0 or rebote.y != 0:
		if esHuir:
			rebote = rebote.rotated(PI * 0.5 * direccion.x)
		else:
			direccion = Vector2(1, 0).rotated(randf() * 2 * PI)
		position += rebote.normalized() * velocidad() * delta
		return true
	return false

func Perseguir(delta):
	var ray = get_node("Ray")
	# guinxu, titan, jasperdev, sdev
	var v = vision()
	var minDis = [v, v, v, v]
	var minMan = [null, null, null, null]
	var dis
	var i
	for c in colision[3]:
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
	for m in range(minMan.size()):
		if minMan[m] != null:
			dis = minDis[0]
			if Armado(true) and m != 2:
				if dis > v * rangoPelea[1]:
					var dir = position.direction_to(minMan[m].position)
					position += dir * velocidad() * delta
					direccion = Vector2(1, 0).rotated(randf() * 2 * PI)
				elif dis < v * rangoPelea[0]:
					var dir = position.direction_to(minMan[m].position)
					position -= dir.rotated(PI * 0.5 * direccion.x) * velocidad() * delta
				else:
					position += direccion * velocidad() * delta
			else:
				if dis > disEnte:
					var dir = position.direction_to(minMan[m].position)
					position += dir * velocidad() * delta
			return true
		minDis.remove(0)
	return false

func Limites(delta):
	var ant = position
	if tipo == tipInterno:
		var pMin = get_parent().get_parent().get_node("Sala1").position
		var pMax = get_parent().get_parent().get_node("Sala2").position
		position.x = clamp(position.x, pMin.x, pMax.x)
		position.y = clamp(position.y, pMin.y, pMax.y)
	else:
		position.x = clamp(position.x, 0, limirec.x)
		position.y = clamp(position.y, 0, limirec.y)
		if tipo == tipSuelo:
			if not mundo.EnTierra(position):
				position = anterior + Vector2(0, velocidad() * delta).rotated(randf() * 2 * PI)
				if not mundo.EnTierra(position):
					position = anterior
	if ant.x != position.x or ant.y != position.y:
		direccion = Vector2(1, 0).rotated(randf() * 2 * PI)
	#animaciones
	if aniPaso:
		if anterior.x == position.x or anterior.y == position.y:
			get_node("Anima").play("idle", -1, 1)
			aniPaso = false
	else:
		if anterior.x != position.x or anterior.y != position.y:
			get_node("Anima").play("walk", -1, 3)
			aniPaso = true
	# muevesombra
	if tipo == tipInterno:
		sombrita.position = global_position
	else:
		sombrita.position = position

func Volar(delta):
	# 0:subiendo, 1:volando, 2:bajando
	if altura == 0:
		get_node("Imagen/Aire").position.y -= upDownVuelo[0] * delta
		if get_node("Imagen/Aire").position.y <= get_node("Imagen/Altura").position.y:
			get_node("Imagen/Aire").position.y = get_node("Imagen/Altura").position.y
			altura = 1
	elif altura == 2:
		get_node("Imagen/Aire").position.y += upDownVuelo[1] * delta
		if get_node("Imagen/Aire").position.y >= 0:
			get_node("Imagen/Aire").position.y = 0
			anterior = aterrizaje
			CambiaTipo(tipSuelo)
			if estado != stAnda:
				next[0] = null
	else:
		var dis = position.distance_to(aterrizaje)
		var dir = position.direction_to(aterrizaje)
		if direccion.x > 0:
			position += (dir.rotated(randf() * borracho * 2) * velociVuelo * delta).clamped(dis)
		else:
			position += (dir.rotated(randf() * -borracho * 2) * velociVuelo * delta).clamped(dis)
		if dis < disPnt:
			altura = 2

func Volando(llegada):
	CambiaTipo(tipAire)
	aterrizaje = llegada
	get_node("Imagen/Aire").position.y = get_node("Imagen/Altura").position.y
	altura = 1

func GetObj():
	return get_node("Imagen/Suelo/Cuerpo/Objeto").frame

func SetObj(ind):
	var ant = GetObj()
	if (ant == objGuaro and tomaGuaro) or ant == objCopa:
		necesidad[nesComida] = 1
		tomaGuaro = false
	get_node("Imagen/Suelo/Cuerpo/Objeto").frame = ind
	get_node("Imagen/Aire/Cuerpo/Objeto").frame = ind
	# poner en modo huida porque perdio armas
	if (ant == objEscudo or ant == objEscudoPro) and ind != ant:
		get_node("Vigia").monitoring = false
		colision[3] = []
		if tipo == tipSuelo:
			get_node("Hulle").monitoring = true
		else:
			get_node("Hulle").monitoring = false
			colision[4] = []
	# poner en modo persecucion porque tiene armas
	if (ind == objEscudo or ind == objEscudoPro) and ind != ant:
		get_node("Hulle").monitoring = false
		colision[4] = []
		if tipo == tipSuelo:
			get_node("Vigia").monitoring = true
		else:
			get_node("Vigia").monitoring = false
			colision[3] = []

func BuscaBuildOk(destino, ind, alAzar=false, forzar=false):
	# devuelve 0:nada, 1:fallo
	if buscaActiva or forzar:
		buscaActiva = false
	else:
		return 0
	# encontrar la puerta mas cercana para analizar caminos
	if ultima == null:
		var cll = get_tree().get_nodes_in_group("puerta")
		var minDis = vision() * 2.0
		var ray = get_node("Ray")
		var dis
		for c in cll:
			dis = position.distance_to(c.global_position)
			if dis < minDis:
				if mundo.LineaTierra(position, dis, position.direction_to(c.global_position)):
					ray.cast_to = c.global_position - position
					ray.force_raycast_update()
					if not ray.is_colliding():
						minDis = dis
						ultima = c
		if ultima == null:
			return 1
	elif not is_instance_valid(ultima):
		ultima = null
		return 0
	# verificar que el candidato sea alcanzable y hallar la distancia
	var candidatos = get_tree().get_nodes_in_group(destino)
	var distancia = []
	var dist
	for i in range(candidatos.size() - 1, -1, -1):
		dist = ultima.CostoDestino(candidatos[i].get_node("Puerta"))
		if dist == -1:
			candidatos.remove(i)
		else:
			distancia.append(dist)
	distancia.invert()
	# retorna fallo buscando candidatos
	if candidatos.empty():
		return 1
	# elegir candidato al azar
	if alAzar:
		meta[ind] = candidatos[randi() % candidatos.size()].get_node("Puerta")
		next[ind] = null
		return 0
	# buscar la torre mas cercana que cumpla con los requerimientos
	if destino == "ediTorre" and estado == stPatrulla:
		var minDis = -1
		var minMaluco = -1
		var maluco = null
		for i in range(candidatos.size()):
			if candidatos[i].Activo():
				if candidatos[i].Balas() == 0:
					if distancia[i] < minMaluco or minMaluco == -1:
						minMaluco = distancia[i]
						maluco = candidatos[i].get_node("Puerta")
				else:
					if distancia[i] < minDis or minDis == -1:
						minDis = distancia[i]
						meta[ind] = candidatos[i].get_node("Puerta")
		if maluco != null:
			if meta[ind] == null or minDis - minMaluco > towerDifference:
				meta[ind] = maluco
		next[ind] = null
		return 0
	# buscar el candidato mas cercano que cumpla con los requerimientos
	var minDis = -1
	var ok
	for i in range(candidatos.size()):
		if distancia[i] < minDis or minDis == -1:
			ok = true
			match destino:
				"ediEdificio":
					if estado == stDuerme or estado == stGuarece:
						ok = candidatos[i].WorkOk() != null
					elif estado == stMina and GetObj() == objMina:
						ok = candidatos[i].EsBodegable()
				"ediOcio":
					if estado == stBaila:
						ok = candidatos[i].WorkOk() != null
					elif estado == stCarga:
						if GetObj() == objCaja:
							ok = candidatos[i].EsBodegable()
						elif GetObj() == objGuaro:
							ok = candidatos[i].EsNeverable()
					elif estado == stCome:
						ok = candidatos[i].GetAlimento()
					elif estado == stCompra:
						ok = candidatos[i].GetBolsas()
				"ediCultivo":
					if (estado == stCome and supervivencia == 2) or estado == stCultiva:
						ok = candidatos[i].WorkOk() != null
					elif estado == stCome:
						ok = candidatos[i].GetAlimento()
					elif estado == stCarga:
						if GetObj() == objNull:
							ok = candidatos[i].GetAlimento()
						elif GetObj() == objGuaro:
							ok = candidatos[i].EsNeverable()
				"ediTrabajo":
					if estado == stTrabaja:
						ok = candidatos[i].WorkOk() != null
					elif estado == stMina and GetObj() == objMina:
						ok = candidatos[i].EspacioMinerales()
					elif estado == stCarga:
						if GetObj() == objNull:
							ok = candidatos[i].TieneAlgo()
						elif GetObj() == objCaja:
							ok = candidatos[i].EsBodegable()
				"ediHospital":
					if estado == stMedico:
						ok = candidatos[i].WorkOk() != null
					elif estado == stReposo:
						ok = candidatos[i].CamillaOk() != null
					elif estado == stRescata:
						ok = candidatos[i].SuficienteVacuna()
					elif estado == stCarga:
						if GetObj() == objVacuna:
							ok = candidatos[i].EsJeringable()
						elif GetObj() == objGuaro:
							ok = candidatos[i].EsNeverable()
				"ediTorre":
					if estado == stVigila:
						ok = candidatos[i].WorkOk() != null
					elif estado == stCarga and (GetObj() == objCaja or GetObj() == objEscudoPro):
						ok = candidatos[i].EsBodegable()
				"ediEstudio":
					if estado == stEscribe:
						ok = candidatos[i].WorkOk() != null
					elif estado == stLee:
						ok = candidatos[i].GetLibros()
					elif estado == stCarga and GetObj() == objLibro:
						ok = candidatos[i].EsBodegable()
				"ediJuego":
					if estado == stJuega:
						ok = candidatos[i].WorkOk() != null
				"ediCentro":
					if estado == stPolitico:
						ok = candidatos[i].WorkOk() != null
				"ediAndamios":
					if estado == stConstruye or estado == stDemuele:
						ok = candidatos[i].WorkOk(false, true) != null
			if ok:
				minDis = distancia[i]
				meta[ind] = candidatos[i].get_node("Puerta")
	next[ind] = null
	return 0

func Navegar(delta, destino, alAzar=false):
	# devuelve 0:nada, 1:fallo, 2:llego, 3:andar
	var t = 0 if destino == "calle" or destino == "conmina" else 1
	if meta[t] == null:
		# buscar lugar a donde ir
		return BuscaBuildOk(destino, t, alAzar)
	elif is_instance_valid(meta[t]):
		if next[t] == null:
			var cll = get_tree().get_nodes_in_group("calle")
			var minDis = vision() * 2.0
			var ray = get_node("Ray")
			var dis
			var nxt
			for c in cll:
				dis = position.distance_to(c.position)
				if dis < minDis:
					nxt = c.get_node("Puerta").Proximo(meta[t])
					if nxt[0] != null:
						if mundo.LineaTierra(position, dis, position.direction_to(c.position)):
							ray.cast_to = c.position - position
							ray.force_raycast_update()
							if not ray.is_colliding():
								minDis = dis
								next[t] = c.get_node("Puerta")
			if next[t] == null:
				meta[t] = null
				return 1
			else:
				ultima = next[t]
		elif is_instance_valid(next[t]):
			var dir
			if direccion.x > 0:
				dir = position.direction_to(next[t].global_position).rotated(randf() * borracho)
			else:
				dir = position.direction_to(next[t].global_position).rotated(randf() * -borracho)
			position += dir * velocidad() * delta
			if position.distance_to(next[t].global_position) < disPnt:
				if next[t] == meta[t]:
					next[t] = null
					return 2
				else:
					var nxt = next[t].Proximo(meta[t])
					next[t] = nxt[0]
					if nxt[1] == 2:
						aterrizaje = next[t].global_position
						CambiaTipo(tipAire)
					ultima = next[t] if next[t] != null else ultima
			return 3
		else:
			next[t] = null
	else:
		meta[t] = null
	return 0

func NavErrar(delta, destino, alAzar=false):
	# navegar devuelve 0:nada, 1:fallo, 2:llego, 3:andar
	var r = Navegar(delta, destino, alAzar)
	if r == 2:
		return true
	elif r != 3:
		if destino != "calle" and destino != "conmina":
			if NavErrar(delta, "calle", true):
				meta[0] = null
		else:
			Errar(delta)
	return false

func CambioEstado(ind):
	estado = ind
	meta[1] = null
	frustracion = 0
	blanco = null
	supervivencia = 0
	lugarEntrega = ""
	reclutar = true
	critico = false
	if protesta != -1 and estado != stAnda and estado != stVota and estado != stPolitico:
		Descontento(-1)
	elif busEmple:
		if not EstaTrabajando(false):
			busEmple = false
			Descontento(nesTrabajo)
	get_node("RelojEstado").stop()
	get_node("RelojSaca").stop()
	Dialogar(false)
	Saquese()
	if debug:
		get_node("Imagen/Prg/Estao").text = NamEstado(estado)

func Saquese():
	var superior = get_parent()
	if superior.is_in_group("interior"):
		match superior.name:
			"Guardia":
				if guardaBala:
					guardaBala = false
				else:
					SetObj(objNull)
			"Camilla2":
				var curador = superior.get_parent().get_parent()
				var salut = min(necesidad[nesSalud], carencia[nesSalud])
				var cura = curador.CuroAlguien(salut / carencia[nesSalud])
				if cura >= 2:
					if virus:
						mundo.InfoVirus(4)
					VidaFull()
				elif cura == 1:
					if virus:
						mundo.InfoVirus(4)
					VidaFull(true)
			"Camilla1":
				var otracamilla = superior.get_parent().get_node("Camilla2")
				if otracamilla.get_child_count() == 1:
					var quien = otracamilla.get_child(0)
					quien.Saquese()
					quien.LiberaEstado()
		while superior.get_parent().name != "Objetos":
			superior = superior.get_parent()
		get_parent().remove_child(self)
		mundo.get_node("Objetos").add_child(self)
		position = superior.get_node("Puerta").global_position
		CambiaTipo(tipSuelo)

func DemeSuperior():
	var superior = get_parent()
	if superior.is_in_group("interior"):
		while superior.get_parent().name != "Objetos":
			superior = superior.get_parent()
		return superior
	return null

func LiberaEstado():
	CambioEstado(stAnda)

func Introducirse(lugar, forma):
	CambiaTipo(forma)
	get_parent().remove_child(self)
	lugar.add_child(self)
	position = Vector2(0, 0)
	mover = true
	if tipo == tipEstatico:
		match get_parent().name:
			"Guardia":
				if GetObj() == objEscudoPro:
					guardaBala = not get_parent().get_parent().get_parent().PoneBalas()
				else:
					SetObj(objEscudoPro)
	elif get_parent().is_in_group("habitacion"):
		match GetObj():
			objBolsa:
				var ed = get_parent().get_parent().get_parent()
				mundo.AddDinero("chuspa", true)
				if not ed.get_node("SonidoCompra").is_playing():
					ed.get_node("SonidoCompra").play()
				SetObj(objNull)
			objMina:
				var ed = get_parent().get_parent().get_parent()
				if ed.PoneMineral():
					SetObj(objNull)

func Frustrado(quitaEstado=true, quitaCosa=true):
	frustracion += 1
	if frustracion >= persistencia:
		frustracion = 0
		if quitaEstado:
			LiberaEstado()
		if quitaCosa and randf() < probQuitaObj:
			SetObj(objNull)
		return true
	return false

func HacerMineria(delta):
	if tipo == tipSuelo:
		if meta[1] == null:
			var intenta = buscaActiva
			NavErrar(delta, "diamantino")
			if intenta:
				if meta[1] == null:
					Frustrado()
				elif not meta[1].get_parent().WorkMinero(self):
					meta[1] = null
					Frustrado()
		elif not is_instance_valid(meta[1]):
			meta[1] = null
		elif not meta[1].get_parent().WorkMinero(self):
			meta[1] = null
			Frustrado()
		elif GetObj() == objMina:
			var intenta = buscaActiva
			if NavErrar(delta, "diamantino"):
				if meta[1].get_parent().PoneMineral():
					if Entregado():
						return 0
					if not meta[1].get_parent().WorkMinero(self):
						meta[1] = null
				else:
					meta[1] = null
					Frustrado()
			elif meta[1] != null:
				if not meta[1].get_parent().WorkMinero(self):
					meta[1] = null
					Frustrado()
			elif intenta:
				Frustrado()
		elif blanco != null:
			position += position.direction_to(blanco.position) * velocidad() * delta
			if position.distance_to(blanco.position) < disEnte:
				SetObj(objMina)
				blanco.get_node("Sonido").play()
				frustracion = 0
				blanco = null
		elif NavErrar(delta, "conmina"):
			meta[0] = null

func Alimentarse(delta):
	# supervivencia: 0:ocio, 1:cultivo, 2:cultivo-trabajo
	if tipo == tipSuelo:
		if GetObj() == objCopa or GetObj() == objGuaro:
			if not tomaGuaro:
				tomaGuaro = true
			if NavErrar(delta, "calle", true):
				meta[0] = null
		elif supervivencia == 2:
			if GoWork(delta, "ediCultivo", tipInterno):
				Descontento(nesComida)
		elif meta[1] == null:
			var intenta = buscaActiva
			if supervivencia == 0:
				NavErrar(delta, "ediOcio")
				if intenta:
					if meta[1] == null:
						if Frustrado(false):
							supervivencia += 1
			else:
				NavErrar(delta, "ediCultivo")
				if intenta:
					if meta[1] == null:
						if Frustrado(false):
							supervivencia += 1
		elif not is_instance_valid(meta[1]):
			meta[1] = null
		elif not meta[1].get_parent().GetAlimento():
			meta[1] = null
			if Frustrado(false):
				supervivencia += 1
		else:
			var h = "ediOcio" if supervivencia == 0 else "ediCultivo"
			if NavErrar(delta, h):
				if meta[1].get_parent().TomarAlimento():
					if supervivencia == 0:
						SetObj(objCopa)
						if not meta[1].get_parent().get_node("SonidoCopa").is_playing():
							meta[1].get_parent().get_node("SonidoCopa").play()
						mundo.AddDinero("copa", true)
						necesidad[nesDiversion] = min(1, necesidad[nesDiversion] + valorCopa)
						necesidad[nesTrabajo] = max(0, necesidad[nesTrabajo] - valorCopa)
						var work = meta[1].get_parent().WorkOk()
						if work != null:
							Introducirse(work, tipInterno)
							get_node("RelojSaca").start(rand_range(sComer[0], sComer[1]))
					else:
						tomaGuaro = true
						mundo.AddDinero("guaro", true)
						SetObj(objGuaro)
				meta[1] = null

func GoLeer(delta):
	if tipo == tipSuelo:
		if GetObj() == objLibro:
			if NavErrar(delta, "calle", true):
				meta[0] = null
		elif meta[1] == null:
			var intenta = buscaActiva
			NavErrar(delta, "ediEstudio")
			if intenta:
				if meta[1] == null:
					return Frustrado()
		elif not is_instance_valid(meta[1]):
			meta[1] = null
		elif meta[1].get_parent().Libros() == 0:
			meta[1] = null
			return Frustrado()
		elif NavErrar(delta, "ediEstudio"):
			if meta[1].get_parent().TomaLibro():
				SetObj(objLibro)
				if not meta[1].get_parent().get_node("SonidoLibro").is_playing():
					meta[1].get_parent().get_node("SonidoLibro").play()
				var work = meta[1].get_parent().WorkLee()
				if work != null:
					Introducirse(work, tipInterno)
					get_node("RelojSaca").start(rand_range(sLee[0], sLee[1]))
			meta[1] = null
	return false

func IrDeCompras(delta):
	if tipo == tipSuelo:
		if GetObj() == objBolsa:
			var intenta = buscaActiva
			if NavErrar(delta, "ediEdificio", true):
				SetObj(objNull)
				mundo.AddDinero("chuspa", true)
				if not meta[1].get_parent().get_node("SonidoCompra").is_playing():
					meta[1].get_parent().get_node("SonidoCompra").play()
				LiberaEstado()
			elif intenta and meta[1] == null:
				return Frustrado()
		elif meta[1] == null:
			var intenta = buscaActiva
			NavErrar(delta, "ediOcio")
			if intenta:
				if meta[1] == null:
					return Frustrado()
		elif not is_instance_valid(meta[1]):
			meta[1] = null
		elif meta[1].get_parent().Chuspas() == 0:
			meta[1] = null
			return Frustrado()
		elif NavErrar(delta, "ediOcio"):
			if meta[1].get_parent().TomaChuspa():
				SetObj(objBolsa)
				mundo.AddDinero("chuspita", true)
				necesidad[nesDiversion] = min(1, necesidad[nesDiversion] + valorBolsa)
				necesidad[nesTrabajo] = max(0, necesidad[nesTrabajo] - valorBolsa)
				frustracion = 0
				var work = meta[1].get_parent().WorkOk()
				if work != null:
					Introducirse(work, tipInterno)
					get_node("RelojSaca").start(rand_range(sCompra[0], sCompra[1]))
			meta[1] = null
	return false

func GoBuild(delta, esDemoler):
	if tipo == tipSuelo:
		var intenta = buscaActiva
		if NavErrar(delta, "ediAndamios"):
			var work = meta[1].get_parent().WorkOk(esDemoler)
			if work != null:
				Introducirse(work, tipEstatico)
			meta[1] = null
		elif meta[1] != null:
			if meta[1].get_parent().WorkOk(esDemoler) == null:
				meta[1] = null
				Frustrado()
		elif intenta:
			Frustrado()

func Hippie(delta):
	if tipo == tipSuelo:
		var intenta = buscaActiva
		if NavErrar(delta, "ediParque"):
			var ant = meta[1]
			necesidad[nesEnergia] = min(1, necesidad[nesEnergia] + bonusHippie)
			CambioEstado(stHierba)
			meta[1] = ant
		elif meta[1] != null:
			if not meta[1].get_parent().Forestado():
				meta[1] = null
				Frustrado()
		elif intenta:
			Frustrado()

func Ermitanno(delta):
	if tipo == tipSuelo:
		if meta[1] != null:
			if is_instance_valid(meta[1]):
				Errar(delta)
				var dis = position.distance_to(meta[1].get_parent().position)
				if dis > meta[1].get_parent().get_node("Reserva/Coli").shape.radius:
					direccion = position.direction_to(meta[1].get_parent().position)
				return 0
	LiberaEstado()

func Hablar(delta):
	if tipo == tipSuelo:
		var ok = true
		if blanco != null:
			var borra = true
			if is_instance_valid(blanco):
				if blanco.tipo == tipSuelo and blanco.estado == stHabla and blanco.blanco == self:
					borra = false
					ok = false
					var dis = position.distance_to(blanco.position)
					if dis > disEnte:
						position += position.direction_to(blanco.position) * velocidad() * delta
					elif virus and not blanco.virus:
						if blanco.necesidad[nesSalud] < debilidad:
							blanco.Viral(true)
			if borra:
				blanco = null
				Frustrado()
		if ok:
			if get_node("RelojEstado").is_stopped():
				get_node("RelojEstado").start(rand_range(sBuscaCharla[0], sBuscaCharla[1]))
			if NavErrar(delta, "calle", true):
				meta[0] = null

func Rescatar(delta):
	if tipo == tipSuelo:
		if GetObj() == objVacuna:
			if blanco == null:
				if NavErrar(delta, "calle", true):
					meta[0] = null
			elif not is_instance_valid(blanco):
				blanco = null
			elif blanco.tipo == tipSuelo and blanco.EsEnfermo():
				position += position.direction_to(blanco.position) * velocidad() * delta
				if position.distance_to(blanco.position) < disEnte:
					Curarlo(blanco)
					blanco = null
			else:
				blanco = null
		else:
			# cada tanto mirar si ya esta lleno el cupo de enfermeros
			if randf() < microRevision:
				if not WorkEnfermeros():
					LiberaEstado()
					return 0
			# ahora si buscar hospital para armarse
			if meta[1] == null:
				var intenta = buscaActiva
				NavErrar(delta, "ediHospital")
				if intenta:
					if meta[1] == null:
						Frustrado()
			elif not is_instance_valid(meta[1]):
				meta[1] = null
			elif not meta[1].get_parent().SuficienteVacuna():
				meta[1] = null
				Frustrado()
			elif NavErrar(delta, "ediHospital"):
				if WorkEnfermeros():
					if meta[1].get_parent().SuficienteVacuna():
						meta[1].get_parent().TomaJeringa()
						SetObj(objVacuna)
						blanco = null
					meta[1] = null
				else:
					LiberaEstado()

func Patrullar(delta):
	if tipo == tipSuelo:
		if Armado():
			if Armado(true):
				if NavErrar(delta, "calle", true):
					meta[0] = null
			elif meta[1] == null:
				if NavErrar(delta, "calle", true):
					meta[0] = null
				BuscaBuildOk("ediTorre", 1)
				if meta[1] != null:
					if meta[1].get_parent().Balas() == 0:
						meta[1] = null
			elif not is_instance_valid(meta[1]):
				meta[1] = null
			elif meta[1].get_parent().Balas() == 0:
				meta[1] = null
			elif NavErrar(delta, "ediTorre"):
				if meta[1].get_parent().TomaBalas():
					SetObj(objEscudoPro)
				meta[1] = null
		else:
			# cada tanto mirar si ya esta lleno el cupo de soldados
			if randf() < microRevision:
				if not WorkMilicia():
					if Temor():
						CambioEstado(stGuarece)
					else:
						LiberaEstado()
					return 0
			# ahora si buscar torre para armarse
			if meta[1] == null:
				var intenta = buscaActiva
				NavErrar(delta, "ediTorre")
				if intenta:
					if meta[1] == null:
						if Frustrado(false):
							if Temor():
								CambioEstado(stGuarece)
							else:
								LiberaEstado()
			elif not is_instance_valid(meta[1]):
				meta[1] = null
			elif NavErrar(delta, "ediTorre"):
				if WorkMilicia():
					if meta[1].get_parent().TomaBalas():
						SetObj(objEscudoPro)
					else:
						SetObj(objEscudo)
					frustracion = 0
					meta[1] = null
				elif Temor():
					CambioEstado(stGuarece)
				else:
					LiberaEstado()

func GoReposo(delta):
	if tipo == tipSuelo:
		var intenta = buscaActiva
		if NavErrar(delta, "ediHospital"):
			var work = meta[1].get_parent().CamillaOk()
			if work != null:
				Introducirse(work, tipAsomado)
				get_node("RelojEstado").start(rand_range(sReposo[0], sReposo[1]))
			meta[1] = null
		elif meta[1] != null:
			if meta[1].get_parent().CamillaOk() == null:
				meta[1] = null
				return Frustrado()
		elif intenta:
			return Frustrado()
	return false

func Votacion(delta):
	if tipo == tipSuelo:
		if protesta != -1:
			var ok = true
			if meta[1] != null:
				if is_instance_valid(meta[1]):
					if meta[1].get_parent().EsActivo():
						var dis = position.distance_to(meta[1].get_parent().position)
						# re ajustar direccion azarosa hacia centro
						if dis > radioProtesta - disPnt:
							direccion = position.direction_to(meta[1].get_parent().position)
						elif dis < 96:
							direccion = meta[1].get_parent().position.direction_to(position)
						# moverse
						if dis < radioProtesta:
							ok = false
							Errar(delta)
							if meta[1].get_parent().WorkOk() != null:
								CambioEstado(stPolitico)
				else:
					meta[1] = null
			if ok:
				NavErrar(delta, "ediCentro")
		else:
			LiberaEstado()

func Transportador(delta):
	match GetObj():
		objNull:
			if NavErrar(delta, lugarEntrega):
				if lugarEntrega == "ediCultivo":
					if meta[1].get_parent().TomarAlimento():
						SetObj(objGuaro)
						frustracion = 0
					else:
						Frustrado()
				elif lugarEntrega == "ediTrabajo":
					if meta[1].get_parent().TomaCaja():
						SetObj(objCaja)
						frustracion = 0
					else:
						Frustrado()
				meta[1] = null
				lugarEntrega = ""
			elif meta[1] != null:
				if not meta[1].get_parent().TieneAlgo():
					meta[1] = null
					Frustrado()
					lugarEntrega = ""
			# el reloj de busqueda hara frustracion si no hay donde conseguir objeto
		objCaja:
			if meta[1] == null:
				if randf() < 0.1:
					lugarEntrega = "ediTrabajo"
				elif randf() < 0.666:
					lugarEntrega = "ediTorre"
				else:
					lugarEntrega = "ediOcio"
			var intenta = buscaActiva
			if NavErrar(delta, lugarEntrega):
				if meta[1].get_parent().PoneMercancia():
					lugarEntrega = ""
					if Entregado():
						return 0
				else:
					Frustrado()
				meta[1] = null
			elif meta[1] != null:
				if meta[1].get_parent().MaterialFull():
					meta[1] = null
					Frustrado()
			elif intenta:
				Frustrado()
		objGuaro:
			if tomaGuaro:
				SetObj(objNull)
			else:
				if meta[1] == null:
					if randf() < 0.1:
						lugarEntrega = "ediCultivo"
					elif randf() < 0.666:
						lugarEntrega = "ediHospital"
					else:
						lugarEntrega = "ediOcio"
				var intenta = buscaActiva
				if NavErrar(delta, lugarEntrega):
					if meta[1].get_parent().PoneComida():
						lugarEntrega = ""
						if Entregado():
							return 0
					else:
						Frustrado()
					meta[1] = null
				elif meta[1] != null:
					if meta[1].get_parent().ComidaFull():
						meta[1] = null
						Frustrado()
				elif intenta:
					Frustrado()
		objBolsa:
			CambioEstado(stCompra)
		objMina:
			CambioEstado(stMina)
		objLibro:
			Encargo(delta, "ediEstudio")
		objVacuna:
			if randf() < 0.5 and reclutar:
				reclutar = false
				Encargo(delta, "ediHospital")
			else:
				CambioEstado(stRescata)
		objEscudoPro:
			if randf() < 0.5 and reclutar:
				reclutar = false
				Encargo(delta, "ediTorre")
			else:
				CambioEstado(stPatrulla)
		objEscudo:
			if randf() < 0.5:
				SetObj(objNull)
			else:
				CambioEstado(stPatrulla)
		_:
			SetObj(objNull)

func Encargo(delta, destino):
	if tipo == tipSuelo:
		var intenta = buscaActiva
		if NavErrar(delta, destino):
			if meta[1].get_parent().PoneCosa():
				if Entregado():
					return 0
			else:
				Frustrado()
			meta[1] = null
		elif meta[1] != null:
			if meta[1].get_parent().AbastoFull():
				meta[1] = null
				Frustrado()
		elif intenta:
			Frustrado()

func GoWork(delta, destino, forma, duracion=-1, alAzar=false):
	if tipo == tipSuelo:
		var intenta = buscaActiva
		if NavErrar(delta, destino, alAzar):
			var work = meta[1].get_parent().WorkOk()
			if work != null:
				Introducirse(work, forma)
				if duracion != -1:
					get_node("RelojEstado").start(duracion)
			meta[1] = null
		elif meta[1] != null:
			if meta[1].get_parent().WorkOk() == null:
				meta[1] = null
				return Frustrado()
		elif intenta:
			return Frustrado()
	return false

func Estados(delta):
	match estado:
		stAnda:
			if NavErrar(delta, "calle", true):
				meta[0] = null
		stAzar:
			Errar(delta)
		stHierba:
			Ermitanno(delta)
		stBaila:
			var antTipo = tipo
			if GoWork(delta, "ediOcio", tipInterno):
				Descontento(nesDiversion)
			elif antTipo == tipSuelo and tipo == tipInterno:
				mundo.AddDinero("baile", true)
		stCompra:
			if IrDeCompras(delta):
				CambioEstado(stBaila)
		stCome:
			Alimentarse(delta)
		stConstruye:
			GoBuild(delta, false)
		stCultiva:
			GoWork(delta, "ediCultivo", tipInterno)
		stDemuele:
			GoBuild(delta, true)
		stDuerme:
			if GoWork(delta, "ediEdificio", tipAsomado, -1, true):
				Descontento(nesEnergia)
				CambioEstado(stEspera)
		stEscribe:
			if GoWork(delta, "ediEstudio", tipAsomado) and critico:
				critico = false
				Descontento(nesIntelecto)
		stEspera:
			if get_node("RelojEstado").is_stopped():
				get_node("RelojEstado").start(rand_range(sWait[0], sWait[1]))
		stGuarece:
			if GoWork(delta, "ediEdificio", tipAsomado):
				Descontento(nesSeguridad)
		stHabla:
			Hablar(delta)
		stJuega:
			if GoWork(delta, "ediJuego", tipInterno):
				Descontento(nesFisico)
		stLee:
			if GoLeer(delta):
				CambioEstado(stEscribe)
				critico = true
		stMedico:
			if GoWork(delta, "ediHospital", tipAsomado):
				var c = critico
				CambioEstado(stRescata)
				critico = c
		stMina:
			HacerMineria(delta)
		stPolitico:
			if GoWork(delta, "ediCentro", tipEstatico, rand_range(sPolitic[0], sPolitic[1])):
				CambioEstado(stVota)
		stRelaja:
			Hippie(delta)
		stTrabaja:
			GoWork(delta, "ediTrabajo", tipInterno)
		stVigila:
			if GoWork(delta, "ediTorre", tipEstatico):
				CambioEstado(stPatrulla)
		stVota:
			Votacion(delta)
		stPatrulla:
			Patrullar(delta)
		stReposo:
			if GoReposo(delta):
				if not HayEnfermero():
					CambioEstado(stMedico)
					critico = true
		stRescata:
			if Rescatar(delta) and critico:
				critico = false
				Descontento(nesSalud)
		stCarga:
			Transportador(delta)

func Comandado(pos):
	if mundo.LineaTierra(position, position.distance_to(pos), position.direction_to(pos)):
		meta[0] = null
		next[0] = null
		posComando = pos
		get_node("AntiAtasco").start(sAtasco[1])

func CambiaTipo(ind):
	var ant = tipo
	tipo = ind
	if ind == tipAire:
		get_node("Imagen/Suelo").visible = false
		get_node("Imagen/Aire").visible = true
		get_node("Imagen/Asomado").visible = false
		get_node("Movil").monitorable = false
		get_node("Movil").monitoring = false
		get_node("Aereo").monitorable = true
		get_node("Aereo").monitoring = true
		sombrita.visible = true
		altura = 0
	elif ind == tipAsomado:
		get_node("Imagen/Suelo").visible = false
		get_node("Imagen/Aire").visible = false
		get_node("Imagen/Asomado").visible = true
		get_node("Movil").monitorable = false
		get_node("Movil").monitoring = false
		get_node("Aereo").monitorable = false
		get_node("Aereo").monitoring = false
		sombrita.visible = false
	else:
		get_node("Imagen/Suelo").visible = true
		get_node("Imagen/Aire").visible = false
		get_node("Imagen/Asomado").visible = false
		get_node("Aereo").monitorable = false
		get_node("Aereo").monitoring = false
		if tipo == tipEstatico:
			get_node("Movil").monitorable = false
			get_node("Movil").monitoring = false
			sombrita.visible = false
		else:
			get_node("Movil").monitorable = true
			get_node("Movil").monitoring = true
			sombrita.visible = true
	# limpiar zonas de colision
	if not get_node("Aereo").monitoring:
		colision[2] = []
	if not get_node("Movil").monitoring:
		colision[0] = []
		colision[1] = []
	# limpiar enemigos vistos
	if ant == tipSuelo and tipo != ant:
		get_node("Vigia").monitoring = false
		get_node("Hulle").monitoring = false
		colision[3] = []
		colision[4] = []
	elif ant != tipSuelo and tipo == tipSuelo:
		if Armado():
			get_node("Vigia").monitoring = true
			get_node("Hulle").monitoring = false
		else:
			get_node("Vigia").monitoring = false
			get_node("Hulle").monitoring = true
	if debug:
		get_node("Imagen/Prg/Estao").text = str(estado) + "." + str(tipo)

func HayEnfermero():
	var mens = get_tree().get_nodes_in_group("diamante")
	for m in mens:
		if m.GetObj() == objVacuna:
			if m == self:
				Curarlo(self)
			return true
	return false

func Curarlo(aQuien):
	if GetObj() == objVacuna:
		if aQuien.virus:
			if randf() < (1 - aQuien.necesidad[nesSalud] / debilidad) * 0.2:
				SetObj(objNull)
		elif randf() < (1 - aQuien.necesidad[nesSalud] / carencia[nesSalud]) * 0.2:
			SetObj(objNull)
		if aQuien.virus:
			mundo.InfoVirus(1)
		aQuien.VidaFull()

func VidaFull(mitad=false):
	if mitad:
		necesidad[nesSalud] = max(carencia[nesSalud] * 2, necesidad[nesSalud])
	else:
		necesidad[nesSalud] = 1
	Viral(false)
	Toser(false)

func Virusear():
	if necesidad[nesSalud] < debilidad:
		Viral(true)
		return true
	return false

func Viral(esViral):
	virus = esViral
	get_node("Contagio").monitoring = virus
	if debug:
		get_node("Imagen/Prg/Tox").visible = virus

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

func _on_Aereo_area_entered(area):
	colision[2].append(area.get_parent())

func _on_Aereo_area_exited(area):
	colision[2].erase(area.get_parent())

func _on_EsquiveSocial_timeout():
	get_node("EsquiveSocial").start(rand_range(sEsquive[0], sEsquive[1]))
	esqSocio = not esqSocio
	if monologo:
		monologo = false
		Dialogar(false)

func NeceSeguridad(lokked):
	var lok = lokked
	var i = nesSeguridad
	if Armado():
		var alert = false
		if tipo == tipSuelo or tipo == tipAire:
			if not colision[3].empty():
				necesidad[i] = clamp(necesidad[i] + nesecityGo[i], 0, 1)
				alert = true
		elif tipo == tipEstatico and estado == stVigila:
			if not DemeSuperior().colision.empty():
				necesidad[i] = clamp(necesidad[i] + nesecityGo[i], 0, 1)
				alert = true
		if not alert:
			necesidad[i] = clamp(necesidad[i] + reestablece[i], 0, 1)
	elif tipo == tipSuelo or tipo == tipAire:
		if not colision[4].empty():
			necesidad[i] = clamp(necesidad[i] + nesecityGo[i], 0, 1)
		else:
			necesidad[i] = clamp(necesidad[i] + reestablece[i], 0, 1)
			if necesidad[i] == 1 and estado == stGuarece:
				LiberaEstado()
	elif tipo == tipAsomado and (estado == stGuarece or estado == stDuerme):
		lok = false
		necesidad[i] = clamp(necesidad[i] + reestablece[i], 0, 1)
		if necesidad[i] == 1 and estado == stGuarece:
			if DemeSuperior().EsSeguro():
				LiberaEstado()
	else:
		necesidad[i] = clamp(necesidad[i] + reestablece[i], 0, 1)
	if necesidad[i] < carencia[i]:
		lok = false
		necesidad[nesEnergia] = max(carencia[nesEnergia] * 0.5, necesidad[nesEnergia])
		necesidad[nesComida] = max(carencia[nesComida] * 0.5, necesidad[nesComida])
		necesidad[nesDiversion] = max(carencia[nesDiversion], necesidad[nesDiversion])
		necesidad[nesSalud] = max(carencia[nesSalud] * 0.5, necesidad[nesSalud])
		if estado != stVigila and estado != stPatrulla and estado != stGuarece:
			CambioEstado(stVigila)
	return lok

func NeceSalud(lokked):
	var lok = lokked
	var i = nesSalud
	if tipo == tipAsomado and (estado == stReposo or estado == stDuerme or estado == stMedico):
		lok = false
	else:
		# -1 mejora, 1 empeora
		var balance
		if virus:
			if necesidad[i] > carencia[i]:
				if randf() < necesidad[nesFisico]:
					balance = -1 if randf() < 0.45 else 1
				else:
					balance = -1 if randf() < 0.4 else 1
			elif randf() < necesidad[nesFisico]:
				balance = -1 if randf() < 0.55 else 1
			else:
				balance = -1 if randf() < 0.5 else 1
		elif randf() < necesidad[nesFisico]:
			balance = -1 if randf() < 0.6 else 1
		elif not caracter:
			balance = -1 if randf() < 0.55 else 1
		else:
			balance = -1 if randf() < 0.5 else 1
		necesidad[i] = clamp(necesidad[i] + nesecityGo[i] * balance, 0, 1)
		if necesidad[i] == 0:
			if true in compannia:
				get_node("Muere").start()
				mundo.AddMuerteSalud()
				if virus:
					mundo.InfoVirus(0)
			else:
				necesidad[i] = carencia[i] * 0.5
		elif lok and necesidad[i] < carencia[i]:
			lok = false
			necesidad[nesDiversion] = max(carencia[nesDiversion], necesidad[nesDiversion])
			if estado != stMedico and estado != stRescata and estado != stReposo:
				CambioEstado(stReposo)
	if virus:
		if necesidad[i] > debilidad:
			Viral(false)
			mundo.InfoVirus(2)
	if not tosiendo and (necesidad[i] < carencia[i] or virus):
		Toser(true)
	elif tosiendo and necesidad[i] > carencia[i] and not virus:
		Toser(false)
	return lok

func NeceComida(lokked):
	var lok = lokked
	var i = nesComida
	if GetObj() == objCopa or (GetObj() == objGuaro and tomaGuaro):
		lok = false
		necesidad[i] = clamp(necesidad[i] + reestablece[nesComida], 0, 1)
		if necesidad[i] == 1:
			SetObj(objNull)
			if estado == stCome:
				LiberaEstado()
	elif tipo == tipInterno and (estado == stCultiva or estado == stCome):
		lok = false
		necesidad[i] = clamp(necesidad[i] + reestablece[nesComida] * 0.25, 0, 1)
		if necesidad[i] > carencia[i] * 2.0 and estado == stCome:
			LiberaEstado()
	elif not EsDormido() and estado != stEspera:
		necesidad[i] = clamp(necesidad[i] + nesecityGo[i], 0, 1)
		if necesidad[i] == 0:
			var tot = 0
			var arbis = get_tree().get_nodes_in_group("arbol")
			for a in arbis:
				if global_position.distance_to(a.position) < vision():
					tot += 1
			if tot >= arbolComida and false in compannia:
				necesidad[i] = carencia[i] * 0.5
			else:
				get_node("Muere").start()
				mundo.AddMuerteComida()
		elif lok and necesidad[i] < carencia[i]:
			lok = false
			necesidad[nesDiversion] = max(carencia[nesDiversion], necesidad[nesDiversion])
			if estado != stCome:
				CambioEstado(stCome)
	return lok

func NeceEnergia(lokked):
	var lok = lokked
	var i = nesEnergia
	if EsDormido():
		lok = false
		if mundo.esDia:
			necesidad[i] = clamp(necesidad[i] + reestablece[i], 0, 1)
		else:
			necesidad[i] = clamp(necesidad[i] + reestablece[i] * 0.8, 0, 1)
		if necesidad[i] == 1:
			mundo.AddDinero("impuesto", true)
			LiberaEstado()
			Reproducirse()
	elif estado == stGuarece and tipo == tipAsomado:
		necesidad[i] = clamp(necesidad[i] + reestablece[i] * 0.5, 0, 1)
	elif estado == stEspera:
		lok = false
		necesidad[i] = clamp(necesidad[i] + reestablece[i] * 2.0, 0, 1)
		if necesidad[i] == 1:
			LiberaEstado()
	else:
		necesidad[i] = clamp(necesidad[i] + nesecityGo[i], 0, 1)
		if necesidad[i] == 0:
			lok = false
			CambioEstado(stEspera)
		elif lok and necesidad[i] < carencia[i]:
			lok = false
			necesidad[nesDiversion] = max(carencia[nesDiversion], necesidad[nesDiversion])
			if estado != stDuerme:
				CambioEstado(stDuerme)
	return lok

func NeceSocial(lokked):
	var lok = lokked
	var i = nesSocial
	if Acompannado():
		necesidad[i] = clamp(necesidad[i] + reestablece[i] * 0.25, 0, 1)
		Dialogar(randf() < probDialogo * 0.5)
	elif estado == stHabla and blanco != null:
		lok = false
		necesidad[i] = clamp(necesidad[i] + reestablece[i], 0, 1)
		if necesidad[i] == 1:
			if is_instance_valid(blanco):
				blanco.LiberaEstado()
			LiberaEstado()
		else:
			Dialogar(randf() < probDialogo)
	elif estado == stHabla:
		necesidad[i] = clamp(necesidad[i] + nesecityGo[i], 0, 1)
		lok = false
	elif not EsDormido() and not EstaTrabajando(true):
		necesidad[i] = clamp(necesidad[i] + nesecityGo[i], 0, 1)
		if necesidad[i] == 0:
			necesidad[i] = 1
			Dialogar(true)
			get_node("EsquiveSocial").start(sMonologo)
			monologo = true
		elif estado == stAnda and lok:
			if necesidad[i] < carencia[i]:
				lok = false
				CambioEstado(stHabla)
	return lok

func NeceDiversion(lokked):
	var lok = lokked
	var i = nesDiversion
	if estado == stHierba or (tipo == tipInterno and estado == stJuega):
		necesidad[i] = clamp(necesidad[i] + reestablece[i] * 0.5, 0, 1)
	elif tipo == tipInterno and estado == stBaila:
		lok = false
		necesidad[i] = clamp(necesidad[i] + reestablece[i], 0, 1)
		if necesidad[i] == 1:
			LiberaEstado()
	elif not EsDormido() and estado != stEspera and not Armado():
		necesidad[i] = clamp(necesidad[i] + nesecityGo[i], 0, 1)
		if necesidad[i] == 0:
			lok = not Locura() and lok
		elif estado == stAnda and lok:
			if necesidad[i] < carencia[i]:
				lok = false
				var compre = false
				var ocios = get_tree().get_nodes_in_group("ediOcio")
				for oc in ocios:
					if oc.Chuspas() != 0 and oc.get_node("Imagen/Actividad").pressed:
						compre = true
						break
				if not compre or randf() < 0.5:
					CambioEstado(stBaila)
				else:
					CambioEstado(stCompra)
	return lok

func NeceTrabajo(lokked):
	var lok = lokked
	var i = nesTrabajo
	if SinDesgasteWork():
		lok = false
	elif estado == stHierba:
		lok = false
		necesidad[i] = clamp(necesidad[i] + nesecityGo[i] * 3.0, 0, 1)
		if necesidad[i] < carencia[i]:
			LiberaEstado()
	elif EstaTrabajando(true):
		lok = false
		if TrabajoLento():
			necesidad[i] = clamp(necesidad[i] + reestablece[i] * 0.5, 0, 1)
		else:
			necesidad[i] = clamp(necesidad[i] + reestablece[i], 0, 1)
		if necesidad[i] == 1:
			if not CargaAlgo() and not Protector():
				busEmple = false
				LiberaEstado()
	elif not EsDormido():
		necesidad[i] = clamp(necesidad[i] + nesecityGo[i], 0, 1)
		if estado == stAnda and lok:
			if necesidad[i] < carencia[i]:
				lok = false
				CambioEstado(BuscaEmpleo())
				if estado == stTrabaja:
					busEmple = true
	return lok

func NeceFisico(lokked):
	var lok = lokked
	var i = nesFisico
	if tipo == tipInterno and estado == stJuega:
		lok = false
		if mover:
			necesidad[i] = clamp(necesidad[i] + reestablece[i], 0, 1)
			if necesidad[i] == 1:
				CompasJueganEnd()
	elif not EsDormido():
		necesidad[i] = clamp(necesidad[i] + nesecityGo[i], 0, 1)
		if estado == stAnda and lok:
			if necesidad[i] < carencia[i]:
				lok = false
				CambioEstado(stJuega)
	return lok

func NeceIntelecto(lokked):
	var lok = lokked
	var i = nesIntelecto
	if estado == stEscribe and tipo == tipAsomado:
		necesidad[i] = clamp(necesidad[i] + reestablece[i] * 0.69, 0, 1)
	elif GetObj() == objLibro:
		lok = false
		necesidad[i] = clamp(necesidad[i] + reestablece[i], 0, 1)
		if necesidad[i] == 1:
			if randf() > devolverLibro:
				SetObj(objNull)
			if estado == stLee:
				LiberaEstado()
	elif not EsDormido():
		necesidad[i] = clamp(necesidad[i] + nesecityGo[i], 0, 1)
		if estado == stAnda and lok:
			if necesidad[i] < carencia[i]:
				lok = false
				CambioEstado(stLee)
	return lok

func NeceDescanso(lokked):
	var lok = lokked
	var i = nesTrabajo
	if estado == stAnda and lok:
		if necesidad[i] > carencia[i]:
			lok = false
			CambioEstado(stRelaja)
	return lok

func _on_NecesiReloj_timeout():
	get_node("NecesiReloj").start(rand_range(sNesReloj[0], sNesReloj[1]))
	if mundo.EsIncubadora():
		Inmortal()
	if estado == stPolitico:
		if tipo == tipEstatico:
			for i in range(9):
				necesidad[i] = clamp(necesidad[i] + politiGod, 0, 1)
	else:
		var lokEstate = true
		lokEstate = NeceSeguridad(lokEstate)
		if lokEstate:
			if estado == stAnda and protesta != -1 and not mundo.EsIncubadora():
				lokEstate = false
				CambioEstado(stVota)
				if randf() < saturaSound:
					get_node("SProtesta").play()
			elif estado == stVota:
				if randf() < probNoProtesta:
					Descontento(-1)
					LiberaEstado()
				else:
					lokEstate = false
		lokEstate = NeceEnergia(lokEstate)
		lokEstate = NeceSalud(lokEstate)
		lokEstate = NeceComida(lokEstate)
		lokEstate = NeceDiversion(lokEstate)
		if lokEstate and estado == stAnda:
			if TieneObjeto():
				lokEstate = false
				CambioEstado(stCarga)
		lokEstate = NeceTrabajo(lokEstate)
		lokEstate = NeceSocial(lokEstate)
		if caracter:
			lokEstate = NeceFisico(lokEstate)
			lokEstate = NeceIntelecto(lokEstate)
		else:
			lokEstate = NeceIntelecto(lokEstate)
			lokEstate = NeceFisico(lokEstate)
		lokEstate = NeceDescanso(lokEstate)
		if lokEstate:
			if estado == stAnda and randf() > necesidad[nesSocial]:
				necesidad[nesSocial] = min(necesidad[nesSocial], 0.8)
				CambioEstado(stHabla)
	Feliz()
	if debug:
		for n in range(9):
			get_node("Imagen/Prg/Prg" + str(n)).value = necesidad[n] * 100.0

func Feliz():
	felicidad = 1
	for i in range(9):
		if necesidad[i] < carencia[i]:
			felicidad *= pesoFeliz[i]
	if debug:
		get_node("Imagen/Prg/PrgF").value = felicidad * 100.0

func EstaTrabajando(contratado):
	if contratado:
		match estado:
			stCarga:
				return CargaAlgo()
			stEscribe:
				return tipo == tipAsomado
			stVigila:
				return tipo == tipEstatico
			stPatrulla:
				return Armado()
			stCultiva:
				return tipo == tipInterno
			stCome:
				var superior = DemeSuperior()
				if superior != null:
					return superior.is_in_group("ediCultivo")
			stMina:
				return GetObj() == objMina
			stTrabaja:
				return tipo == tipInterno
			stMedico:
				return tipo == tipAsomado
			stConstruye:
				return tipo == tipEstatico
			stDemuele:
				return tipo == tipEstatico
			stRescata:
				return GetObj() == objVacuna
		return false
	else:
		return mundo.empleo[estado] != 0

func EstaSocial():
	match estado:
		stHabla:
			return true
		stJuega:
			return true
		stBaila:
			return true
	return false

func SinDesgasteWork():
	match estado:
		stCarga:
			return true
		stMina:
			return true
		stRelaja:
			return true
	return false

func Locura():
	necesidad[nesDiversion] = 1
	if mundo.EsApocalipsis(2) and tipo == tipSuelo and true in compannia:
		if randf() < azaEnloquecer or (mundo.Apocalipsis() and randf() < azaEnloquecer * 0.5):
			var diams = get_tree().get_nodes_in_group("diamante").size()
			if diams >= poblaLocos or mundo.Apocalipsis():
				if randf() < 0.25:
					Jasperize()
					return true
				else:
					# ver si hay bailadero disponible
					CambioEstado(stBaila)
					BuscaBuildOk("ediOcio", 1, false, true)
					if meta[1] == null:
						Jasperize()
						return true
					else:
						necesidad[nesDiversion] = 0.5
	return false

func Jasperize():
	enloquecer = true
	get_node("Muere").start()

func EsDormido():
	return estado == stDuerme and tipo == tipAsomado

func Acompannado():
	if tipo == tipInterno:
		var superior = DemeSuperior()
		if superior != null:
			if superior.Compannia() > 1:
				return true
	return false

func CargaAlgo():
	if estado == stCarga:
		match GetObj():
			objCaja:
				return true
			objEscudoPro:
				return true
			objGuaro:
				return true
			objVacuna:
				return true
	return estado == stMina and GetObj() == objMina

func TieneObjeto():
	match GetObj():
		objCaja:
			return true
		objEscudoPro:
			return true
		objGuaro:
			return true
		objVacuna:
			return true
		objMina:
			return true
		objLibro:
			return true
		objBolsa:
			return true
		objEscudo:
			return true
	return false

func BuscaEmpleo():
	# Construye, Cultiva, Mina, Carga, Demuele, Trabaja, Vigila, Medico, Escribe
	var dado = []
	# buscar con primera prioridad
	if randf() < 0.333:
		for est in range(mundo.empleo.size()):
			if est == stConstruye or est == stCultiva or est == stMina or est == stCarga:
				for _r in range(mundo.empleo[est]):
					dado.append(est)
		if not dado.empty():
			var r = dado[randi() % dado.size()]
			mundo.empleo[r] -= 1
			return r
	# buscar con segunda prioridad
	if randf() < 0.5:
		dado = []
		var ok
		for est in range(mundo.empleo.size()):
			ok = false
			match est:
				stConstruye:
					ok = true
				stCultiva:
					ok = true
				stMina:
					ok = true
				stCarga:
					ok = true
				stDemuele:
					ok = true
				stTrabaja:
					ok = true
				stMedico:
					ok = true
			if ok:
				for _r in range(mundo.empleo[est]):
					dado.append(est)
		if not dado.empty():
			var r = dado[randi() % dado.size()]
			mundo.empleo[r] -= 1
			return r
	# buscar con ultima prioridad
	dado = []
	for est in range(mundo.empleo.size()):
		for _r in range(mundo.empleo[est]):
			dado.append(est)
	if dado.empty():
		return stAnda
	else:
		var r = dado[randi() % dado.size()]
		mundo.empleo[r] -= 1
		return r

func TrabajoLento():
	match estado:
		stVigila:
			return true
		stPatrulla:
			return true
		stRescata:
			return true
		stCultiva:
			return true
		stMina:
			return true
	return false

func Protector(esTrabajo=true):
	if esTrabajo:
		if estado != stVigila and estado != stPatrulla:
			return false
	elif not Armado():
		return false
	if necesidad[nesSeguridad] < 1:
		return true
	var pos = position
	if tipo != tipSuelo and tipo != tipAire:
		pos = DemeSuperior().position
	var mens = get_tree().get_nodes_in_group("diamante")
	var v = vision()
	for m in mens:
		if m.tipo == tipSuelo or m.tipo == tipAire:
			if pos.distance_to(m.position) < v:
				if m.necesidad[nesSeguridad] < 1:
					return true
	return false

func CompasJueganEnd():
	var superior = DemeSuperior()
	if superior != null:
		var manes = superior.LosManes()
		var ok = true
		for m in manes:
			if m.necesidad[nesFisico] != 1:
				ok = false
				break
		if ok:
			for m in manes:
				m.LiberaEstado()

func Entregado():
	SetObj(objNull)
	if not meta[1].get_parent().get_node("SPoner").is_playing():
		meta[1].get_parent().get_node("SPoner").play()
	necesidad[nesTrabajo] = clamp(necesidad[nesTrabajo] + valorCarga, 0, 1)
	if necesidad[nesTrabajo] == 1:
		busEmple = false
		LiberaEstado()
		return true
	return false

func Toser(tose):
	tosiendo = tose
	var antV = get_node("Imagen/Aire/Cuerpo/Tos").emitting
	get_node("Imagen/Aire/Cuerpo/Tos").emitting = tose
	get_node("Imagen/Suelo/Cuerpo/Tos").emitting = tose
	get_node("Imagen/Asomado/Tos").emitting = tose
	if not antV and tose:
		if virus or randf() < saturaSound:
			get_node("STos").play()

func Temor(esSoldado=false):
	if esSoldado:
		return Armado() and necesidad[nesSeguridad] < carencia[nesSeguridad]
	else:
		return necesidad[nesSeguridad] < carencia[nesSeguridad]

func PreveerFinPatrullaEnfermero():
	# funcion actualmente no en uso
	if (Armado() and estado == stPatrulla) or (estado == stRescata and GetObj() == objVacuna):
		if necesidad[nesComida] < carencia[nesComida] + 0.1:
			busEmple = false
			CambioEstado(stCarga)
		elif necesidad[nesTrabajo] < carencia[nesTrabajo] + 0.1:
			busEmple = false
			CambioEstado(stCarga)

func Reproducirse():
	if virus:
		return 0
	# hallar edificio cercano
	var edif = get_tree().get_nodes_in_group("ediEdificio")
	var orig = null
	var tengomineral = GetObj() == objMina
	for e in edif:
		if position.distance_to(e.get_node("Puerta").global_position) < 10:
			if tengomineral or e.Mineral():
				orig = e
				break
	if orig == null:
		return 0
	# hallar nivel de felicidad de generacion
	var diams = get_tree().get_nodes_in_group("diamantes").size()
	var proporcion = float(diams) / mundo.GetPoblacion()
	var feliOk = clamp(lerp(felizDesove[0], felizDesove[1], proporcion), 0.05, 0.95)
	if felicidad < feliOk:
		return 0
	# mirar si suficiente alimento para la creacion de un diamante
	var vh = valorHijo
	if proporcion > 1:
		if randf() < min(proporcion - 1, 0.95):
			return 0
		vh += lerp(vh * 0.5, vh * 1.5, proporcion - 1)
		vh = min(0.9 - carencia[nesComida], vh)
	if necesidad[nesComida] > vh + carencia[nesComida]:
		var hijo = mundo.newDiamante.instance()
		mundo.get_node("Objetos").add_child(hijo)
		hijo.position = position + Vector2(randf(), randf())
		necesidad[nesComida] -= vh
		hijo.necesidad[nesComida] = vh
		hijo.necesidad[nesEnergia] = rand_range(0.5, 0.75)
		hijo.get_node("SHola").play()
		if randf() > mutacion:
			hijo.caracter = caracter
		if tengomineral:
			SetObj(objNull)
		else:
			orig.QuitaMineral()

func Errar(delta):
	if mover:
		position += direccion * velocidad() * delta

func Armado(esPro=false):
	var obj = GetObj()
	if esPro:
		return obj == objEscudoPro
	else:
		return obj == objEscudo or obj == objEscudoPro

func Descontento(ind):
	protesta = ind
	if ind == -1:
		if GetObj() == objCartel:
			SetObj(objNull)
	else:
		posComando = Vector2(0, 0)
		if GetObj() == objNull:
			SetObj(objCartel)
	if debug:
		if ind == -1:
			get_node("Imagen/Prg/Nes").visible = false
		else:
			get_node("Imagen/Prg/Nes").visible = true
			get_node("Imagen/Prg/Nes").frame = ind

func Destructor(cadaver=true):
	LiberaEstado()
	if cadaver:
		var aux = load("res://scenes/otros/DieDiamante.tscn").instance()
		mundo.get_node("Objetos").add_child(aux)
		aux.position = position
		if necesidad[nesComida] == 0:
			aux.get_node("SHambre").play()
		elif necesidad[nesSalud] == 0:
			aux.get_node("SEnfermo").play()
		else:
			aux.get_node("SHerido").play()
	sombrita.queue_free()
	queue_free()

func Construyamelo(andamio):
	CambioEstado(stConstruye)
	necesidad[nesSalud] = max(necesidad[nesSalud], carencia[nesSalud] * 2.0)
	necesidad[nesComida] = max(necesidad[nesComida], carencia[nesComida] * 2.0)
	necesidad[nesEnergia] = max(necesidad[nesEnergia], carencia[nesEnergia] * 2.0)
	necesidad[nesDiversion] = max(necesidad[nesDiversion], carencia[nesDiversion] * 2.0)
	necesidad[nesTrabajo] = min(necesidad[nesTrabajo], carencia[nesTrabajo])
	meta[1] = andamio.get_node("Puerta")

func Inmortal():
	necesidad[nesSalud] = max(necesidad[nesSalud], carencia[nesSalud] * 2.0)
	necesidad[nesComida] = max(necesidad[nesComida], carencia[nesComida] * 2.0)
	necesidad[nesDiversion] = max(necesidad[nesDiversion], carencia[nesDiversion] * 2.0)

func EsSeguible():
	return estado != stDuerme or tipo != tipAsomado

func EsSuelo():
	return tipo == tipSuelo

func EsBlanco():
	return tipo == tipSuelo and estado == stAnda

func EsPuto():
	return tipo == tipSuelo and protesta != -1

func EsManso(exclusivo):
	if exclusivo:
		return tipo == tipSuelo and protesta == -1 and (estado == stAnda or estado == stAzar)
	return tipo == tipSuelo and protesta == -1 and estado != stEspera

func EsEnfermo():
	return necesidad[nesSalud] < carencia[nesSalud] or virus

func EsMinando(elTrabajoPuerta):
	return elTrabajoPuerta == meta[1] and estado == stMina

func velocidad():
	return velociSuelo[0] + necesidad[nesFisico] * velociSuelo[1]

func WorkMilicia():
	var torres = get_tree().get_nodes_in_group("ediTorre")
	var torris = 0
	for t in torres:
		if t.Activo():
			torris += 1
	return mundo.WorkMilicia() < torris * 4

func WorkEnfermeros():
	var hospis = get_tree().get_nodes_in_group("ediHospital")
	var hospus = 0
	for h in hospis:
		if h.Activo():
			hospus += 1
	return mundo.WorkEnfermeros() < hospus * 2

func EsEnfermero():
	return estado == stRescata and GetObj() == objVacuna

func EsEstCome():
	return estado == stCome

func Sabio():
	return randf() < necesidad[nesIntelecto]

func EsHippie():
	return estado == stHierba or estado == stHabla or estado == stRelaja

func EsLoro():
	return estado == stHabla or get_node("Imagen/Suelo/Cuerpo/Dialogo").visible

func GetIntelecto():
	return necesidad[nesIntelecto]

func GetFisico():
	return necesidad[nesFisico]

func Dialogar(dialog):
	var antD = get_node("Imagen/Suelo/Cuerpo/Dialogo").visible
	get_node("Imagen/Suelo/Cuerpo/Dialogo").visible = dialog
	if not antD and dialog and tipo == tipSuelo:
		if randf() < saturaSound * 0.5:
			get_node("SCharla").play()

func vision():
	return visionFull[0] + necesidad[nesIntelecto] * visionFull[1]

func Golpeado(guinxu=null):
	if not Armado() or randf() > escudo:
		if guinxu != null and Armado():
			if is_instance_valid(guinxu):
				guinxu.SetCorona(true)
				guinxu.get_node("SCorona").play()
		Destructor()
		return true
	else:
		mover = true
	return false

func _on_Errar_timeout():
	get_node("Errar").start(rand_range(sErrar[0], sErrar[1]))
	if mover:
		mover = randf() > paramErrar[0]
		direccion = direccion.rotated(rand_range(-paramErrar[2], paramErrar[2]))
	else:
		mover = randf() > paramErrar[1]
		direccion = Vector2(1, 0).rotated(randf() * 2 * PI)
	# evitar soldado guarecido, debe salir a pelear
	if Armado() and tipo != tipSuelo:
		var expecion = [stDuerme, stReposo, stMedico, stCome, stVigila]
		if not expecion.has(estado):
			Saquese()
	# auto curar medicos y enfermeros
	if GetObj() == objVacuna:
		if virus:
			mundo.InfoVirus(4)
		VidaFull()
	elif estado == stMedico and tipo == tipAsomado:
		var superior = DemeSuperior()
		var ok = true
		if superior != null:
			if superior.Jeringas() != 0:
				ok = false
				if virus:
					mundo.InfoVirus(4)
				VidaFull()
		if ok:
			if virus:
				mundo.InfoVirus(4)
			VidaFull(true)
	# PreveerFinPatrullaEnfermero()
	# mostrar hierba
	get_node("Imagen/Suelo/Cuerpo/Hierba").emitting = estado == stHierba
	# ajustar el area de vision de enemigos
	get_node("Hulle/Coli").shape.radius = vision()
	get_node("Vigia/Coli").shape.radius = vision()
	# poner alerta help
	var antH = get_node("Imagen/Suelo/Cuerpo/Help").visible
	get_node("Imagen/Suelo/Cuerpo/Help").visible = Temor()
	if not antH and get_node("Imagen/Suelo/Cuerpo/Help").visible:
		if not Armado():
			if randf() < saturaSound:
				get_node("SHulle").play()
		else:
			if randf() < saturaSound:
				get_node("SGuardia").play()

func _on_Buscador_timeout():
	get_node("Buscador").start(rand_range(sBuscador[0], sBuscador[1]))
	if tipo != tipSuelo:
		return 0
	match estado:
		stCarga:
			if GetObj() == objNull and lugarEntrega == "":
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
				if maxTot[0] + maxTot[1] == 0:
					LiberaEstado()
				else:
					if randf() < maxTot[0] / float(maxTot[0] + maxTot[1]):
						lugarEntrega = "ediCultivo"
					else:
						lugarEntrega = "ediTrabajo"
		stMina:
			if GetObj() != objMina:
				var minas = get_tree().get_nodes_in_group("mina")
				var ray = get_node("Ray")
				var minDis = vision()
				var dis
				for m in minas:
					dis = position.distance_to(m.position)
					if dis < minDis:
						if mundo.LineaTierra(position, dis, position.direction_to(m.position)):
							ray.cast_to = m.position - position
							ray.force_raycast_update()
							if not ray.is_colliding():
								minDis = dis
								blanco = m
		stRescata:
			if GetObj() == objVacuna and (blanco == null or randf() < probReBuscar):
				var manes = get_tree().get_nodes_in_group("diamante")
				var ray = get_node("Ray")
				var minDis = vision()
				var dis
				for m in manes:
					if m != self and m.tipo == tipSuelo and m.EsEnfermo():
						dis = position.distance_to(m.position)
						if dis < minDis:
							if mundo.LineaTierra(position, dis, position.direction_to(m.position)):
								ray.cast_to = m.position - position
								ray.force_raycast_update()
								if not ray.is_colliding():
									minDis = dis
									blanco = m
		stHabla:
			if blanco == null:
				var manes = get_tree().get_nodes_in_group("diamante")
				var ray = get_node("Ray")
				var minDis = vision()
				var minSoci = 1
				var dir
				var dis
				for m in manes:
					if m != self and m.tipo == tipSuelo:
						if m.estado == stAnda or m.estado == stHabla or m.estado == stHierba:
							if m.necesidad[nesSocial] < minSoci:
								dis = position.distance_to(m.position)
								if dis < minDis and m.blanco == null:
									dir = position.direction_to(m.position)
									if mundo.LineaTierra(position, dis, dir):
										ray.cast_to = m.position - position
										ray.force_raycast_update()
										if not ray.is_colliding():
											minDis = dis
											minSoci = m.necesidad[nesSocial]
											blanco = m
				if blanco != null:
					blanco.CambioEstado(stHabla)
					blanco.blanco = self
					var n = (blanco.necesidad[nesSocial] + necesidad[nesSocial]) * 0.5
					blanco.necesidad[nesSocial] = n
					necesidad[nesSocial] = n
					get_node("RelojEstado").stop()

func _on_AntiAtasco_timeout():
	get_node("AntiAtasco").start(rand_range(sAtasco[0], sAtasco[1]))
	if position.distance_to(antiAtascoPos) < disEnte and tipo == tipSuelo:
		meta = [null, null]
		next = [null, null]
		blanco = null
		lugarEntrega = ""
		posComando = Vector2(0, 0)
	antiAtascoPos = position
	# calcular soledad
	var diams = get_tree().get_nodes_in_group("diamante")
	var hay = false
	var dis
	var dir
	for d in diams:
		dis = global_position.distance_to(d.global_position)
		if d != self and dis < vision():
			dir = global_position.direction_to(d.global_position)
			if mundo.LineaTierra(global_position, dis, dir):
				hay = true
				break
	for c in range(compannia.size() -1, 0, -1):
		compannia[c] = compannia[c - 1]
	compannia[0] = hay

func _on_RelojEstado_timeout():
	LiberaEstado()

func _on_RelojSaca_timeout():
	Saquese()

func _on_Muere_timeout():
	if enloquecer:
		mundo.AddMuerteLocura()
		var aux = load("res://scenes/moviles/Jasperdev.tscn").instance()
		mundo.get_node("Objetos").add_child(aux)
		aux.position = position
		aux.velocidad = velocidad()
		aux.vision = vision()
		aux.get_node("SHola").play()
		Destructor(false)
	else:
		Destructor()

func _on_PaBuscar_timeout():
	get_node("PaBuscar").start(rand_range(sBuskar[0], sBuskar[1]))
	buscaActiva = true

func _on_Hulle_area_entered(area):
	colision[4].append(area.get_parent())

func _on_Hulle_area_exited(area):
	colision[4].erase(area.get_parent())

func _on_Vigia_area_entered(area):
	colision[3].append(area.get_parent())

func _on_Vigia_area_exited(area):
	colision[3].erase(area.get_parent())

func _on_Contagio_area_entered(area):
	if virus and (tipo == tipSuelo or tipo == tipInterno):
		var c = area.get_parent()
		if c.tipo == tipSuelo or c.tipo == tipInterno:
			if not c.virus and c.necesidad[nesSalud] < debilidad:
				c.Viral(true)
				mundo.InfoVirus(3)

func _on_Disparador_timeout():
	var bonus = lerp(1, 0.5, necesidad[nesFisico])
	bonus = bonus if Armado(true) else bonus * 1.3
	get_node("Disparador").start(rand_range(sDispara[0], sDispara[1]) * bonus)
	# evitar disparar si no tiene permisos
	if not Armado() or tipo != tipSuelo:
		return 0
	var ray = get_node("Ray")
	# guinxu, titan, jasperdev, sdev
	var v = vision() if Armado(true) else disMele
	var minDis = [v, v, v, v]
	var minMan = [null, null, null, null]
	var dis
	var i
	for c in colision[3]:
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
			aux.direccion = position.direction_to(m.position)
			aux.direccion = aux.direccion.rotated(rand_range(-bisco, bisco))
			aux.position = position + aux.direccion * 8.0
			if not Armado(true):
				aux.Mele(disMele)
			break

func Save(buffer):
	if tipo == tipSuelo or tipo == tipAire:
		buffer.put_float(position.x)
		buffer.put_float(position.y)
	else:
		var edi = DemeSuperior().get_node("Puerta")
		buffer.put_float(edi.global_position.x + randf())
		buffer.put_float(edi.global_position.y + randf())
	if estado != stVota and estado != stPolitico:
		buffer.put_u8(estado)
	else:
		buffer.put_u8(stAnda)
	buffer.put_u8(GetObj())
	var g = 1 if virus else 0
	buffer.put_u8(g)
	g = 1 if caracter else 0
	buffer.put_u8(g)
	for n in necesidad:
		buffer.put_u8(n * 255)
	if tipo == tipAire:
		buffer.put_u8(tipAire)
		buffer.put_float(aterrizaje.x)
		buffer.put_float(aterrizaje.y)
	else:
		buffer.put_u8(tipSuelo)

func Open(buffer):
	position.x = buffer.get_float()
	position.y = buffer.get_float()
	CambioEstado(buffer.get_u8())
	SetObj(buffer.get_u8())
	virus = buffer.get_u8() != 0
	caracter = buffer.get_u8() != 0
	for n in range(necesidad.size()):
		necesidad[n] = buffer.get_u8() / 255.0
	tipo = buffer.get_u8()
	if tipo == tipAire:
		CambiaTipo(tipAire)
		aterrizaje.x = buffer.get_float()
		aterrizaje.y = buffer.get_float()
		get_node("Imagen/Aire").position.y = get_node("Imagen/Altura").position.y
		altura = 1

func NamEstado(ind):
	return ["Anda", "Carga", "Come", "Guarece", "Escribe", "Lee", "Juega", "Vigila",
	"Patrulla", "Cultiva", "Mina", "Trabaja", "Politico", "Medico", "Reposo",
	"Construye", "Demuele", "Compra", "Duerme", "Rescata", "Habla", "Baila",
	"Relaja", "Vota", "Espera", "Azar", "Hierba"][ind]

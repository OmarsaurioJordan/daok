extends Node2D

const velocidad = 250.0 # rapidez del proyectil
const bajada = 250.0 # rapidez descenso de torre
const alcance = 500.0 # distancia para desaparecer proyectil

var direccion = Vector2(0, 0) # hacia donde se mueve el proyectil
var altico = false # para saber si debe bajar
var exepcion = null # objeto exepcion de colision
var sombrita = null # sombra del objeto
var duenno = null # lleva id de enemigo guinxu que dispara
var activo = true # dice si debe procesarse

func _ready():
	get_node("Alcance").start((alcance + randf() * 50) / velocidad)
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	sombrita = mundo.lasombrita.instance()
	mundo.get_node("Sombras").add_child(sombrita)
	sombrita.scale = Vector2(0.75, 0.75)
	mundo.SonidoLen([get_node("Sonido"), get_node("SonidoMele")])

func _process(delta):
	if activo:
		var ray = get_node("Ray")
		var newP = position + direccion * velocidad * delta
		ray.cast_to = newP - position
		ray.force_raycast_update()
		if ray.is_colliding():
			position = ray.get_collision_point()
		else:
			position = newP
		if altico:
			get_node("Imagen/Balin").position.y += bajada * delta
			if get_node("Imagen/Balin").position.y >= -34:
				get_node("Imagen/Balin").position.y = -34.0
				altico = false
		sombrita.position = position

func Maligno(deQuien):
	get_node("Imagen/Balin").frame = 7
	duenno = deQuien

func Mele(disMele):
	get_node("Alcance").start(disMele / velocidad)
	get_node("Imagen/Balin").visible = false
	sombrita.visible = false
	#sombrita.remove_from_group("imagen")
	get_node("Sonido").stop()
	get_node("SonidoMele").play()

func Alturizar(bonusDist):
	get_node("Imagen/Balin").position.y = -134.0
	altico = true
	get_node("Alcance").start(get_node("Alcance").wait_time * bonusDist)

func _on_Alcance_timeout():
	Destructor()

func _on_Bala_area_entered(area):
	if area.get_parent() == exepcion:
		return 0
	var ok = false
	if area.name == "Movil":
		if area.get_parent().tipo == 0:
			if get_node("Imagen/Balin").frame == 6:
				if area.get_parent().is_in_group("monster"):
					area.get_parent().call_deferred("Golpeado")
					ok = true
			else:
				if area.get_parent().is_in_group("diamante"):
					area.get_parent().call_deferred("Golpeado", duenno)
					ok = true
	else:
		ok = true
	if ok:
		Destructor()

func Destructor():
	# esconder el proyectil y activar temporizador de destruccion
	activo = false
	visible = false
	sombrita.visible = false
	position.x = -1000.0
	get_node("Alcance").stop()
	get_node("PoolingFin").start()

func Reconstructor():
	activo = true
	visible = true
	sombrita.visible = true
	get_node("Alcance").start((alcance + randf() * 50) / velocidad)
	get_node("PoolingFin").stop()
	duenno = null
	exepcion = null
	altico = false
	get_node("Imagen/Balin").visible = true
	get_node("Imagen/Balin").frame = 6
	get_node("Imagen/Balin").position.y = -34.0

func _on_PoolingFin_timeout():
	sombrita.queue_free()
	queue_free()

extends Node2D

func _ready():
	if is_in_group("arbol"):
		set_process(true)
		get_node("Imagen/Frente").scale = Vector2(1, 0.2)
		var mundo = get_tree().get_nodes_in_group("mundo")[0]
		mundo.AddArbol(1)
	else:
		set_process(false)
	if is_in_group("calle"):
		get_node("BuscaMina").start(rand_range(10, 20))

func _process(delta):
	if get_node("Imagen/Frente").scale.y < 1:
		get_node("Imagen/Frente").scale.y += 0.2 * delta
	else:
		get_node("Imagen/Frente").scale.y = 1
		set_process(false)

func _on_Quitable_area_entered(area):
	if area.get_parent() != self:
		if is_in_group("calle"):
			if area.is_in_group("carretera"):
				return 0
			elif get_node("Garantia") != null:
				var mundo = get_tree().get_nodes_in_group("mundo")[0]
				mundo.AddDinero("calle", true)
		CaenHojas()
		queue_free()

func CaenHojas():
	if is_in_group("arbol"):
		var aux = load("res://scenes/otros/Deforestacion.tscn").instance()
		var mundo = get_tree().get_nodes_in_group("mundo")[0]
		mundo.get_node("Objetos").add_child(aux)
		aux.position = position
		aux = mundo.arbolSound.instance()
		mundo.add_child(aux)
		aux.position = position

func _on_Arbol_tree_exiting():
	if is_in_group("arbol"):
		var mundo = get_tree().get_nodes_in_group("mundo")[0]
		mundo.AddArbol(-1)

func Destruir():
	if is_in_group("calle"):
		if has_node("Garantia"):
			var mundo = get_tree().get_nodes_in_group("mundo")[0]
			mundo.AddDinero("calle", true)
		get_node("Puerta").Resetear()
	CaenHojas()
	queue_free()

func _on_BuscaMina_timeout():
	if is_in_group("calle"):
		get_node("BuscaMina").start(rand_range(25, 35))
		var mundo = get_tree().get_nodes_in_group("mundo")[0]
		var mines = get_tree().get_nodes_in_group("mina")
		var ray = get_node("Ray")
		var dis
		var ok = false
		for m in mines:
			dis = position.distance_to(m.position)
			if dis < 200:
				if mundo.LineaTierra(position, dis, position.direction_to(m.position)):
					ray.cast_to = m.position - position
					ray.force_raycast_update()
					if not ray.is_colliding():
						ok = true
						break
		if is_in_group("conmina"):
			if not ok:
				remove_from_group("conmina")
		elif ok:
			add_to_group("conmina")

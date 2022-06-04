extends Node2D

const debug = false
const disPorton = 128.0 # longitud maxima del camino edificacion a calle
const sClk = [3, 5] # ciclo principal para pasarse datos

var destino = [] # id puerta final a alcanzar
var costo = [] # valor que tiene llegar al destino
var next = [] # id proxima puerta hacia el destino
var conect = [] # 0:distante, 1:directo, 2:aereo, 3:off
var verificar = [] # true si esta por verificarse
var romboy = null # sprite de calle
var tramos = [] # sprites de las calles
var congestion = 0 # cantidad de diamantes cerca, por una constante

func _ready():
	get_node("Clk").start(rand_range(sClk[0], sClk[1]))
	get_node("Verifica").start(rand_range(sClk[0], sClk[1]) * 2.0)
	if get_parent().is_in_group("conReserva"):
		var reserve = get_parent().get_node("Reserva")
		get_node("Ray").add_exception(reserve)
	if not debug:
		get_node("Total").queue_free()

func Debug():
	print("")
	var p1 = global_position
	p1 = str(round(p1.x))
	print("Puerta: " + p1 + " (congestion: " + str(congestion) + ")")
	print("Dest - Cost - Next - Con")
	var p2
	for i in range(destino.size()):
		p1 = destino[i].global_position
		p1 = str(round(p1.x))
		p2 = next[i].global_position
		p2 = str(round(p2.x))
		print(p1 + " - " + str(round(costo[i])) + " - " + p2 + " - " + str(conect[i]))

func RIP():
	var veci
	var cost
	var pos
	var des
	# recorre todas las filas de la tabla
	for i in range(destino.size()):
		# solo procesa puertas no distantes
		if conect[i] != 0 and conect[i] != 3:
			veci = destino[i]
			# verificar que exista el vecino
			if not is_instance_valid(veci):
				Eliminar(veci)
				break
			# verificar si hay conexion mutua
			if veci.destino.find(self) == -1:
				Eliminar(veci)
				break
			# verificar actividad del puerto aereo
			if conect[i] == 2:
				if not PuertoAbierto():
					continue
			# recorre filas de la tabla de la puerta vecina
			for k in range(veci.destino.size()):
				# procesar fila que no coincida con self
				des = veci.destino[k]
				if des != self and veci.conect[k] != 3:
					# verificar actividad del puerto aereo
					if veci.conect[k] == 2:
						if not veci.PuertoAbierto():
							continue
					# calcular el costo
					cost = costo[i] + veci.costo[k] + congestion
					# buscar si destino de veci esta en self
					pos = destino.find(des)
					# agregar nueva entrada
					if pos == -1:
						Agregar(des, cost, veci, 0)
					# actualizar costo de entrada existente
					elif next[pos] == veci:
						costo[pos] = cost
					# reemplazar next con mejor opcion
					elif cost < costo[pos]:
						costo[pos] = cost
						next[pos] = veci

func PuertoAbierto():
	if get_parent().is_in_group("puerto"):
		return get_parent().Abierto()
	return true

func Verifique():
	var veci
	# recorre todas las filas de la tabla
	for i in range(destino.size()):
		# solo procesa puertas no distantes y en cola para verificacion
		if conect[i] == 1 and verificar[i]:
			verificar[i] = false
			veci = destino[i]
			# verificar que exista el vecino
			if not is_instance_valid(veci):
				Eliminar(veci)
			else:
				# ver si pasa por agua
				var mundo = get_tree().get_nodes_in_group("mundo")[0]
				var p1 = global_position
				var p2 = veci.global_position
				if not mundo.LineaTierra(p1, p1.distance_to(p2), p1.direction_to(p2)):
					Eliminar(veci, true)
				else:
					var ray = get_node("Ray")
					ray.cast_to = p2 - p1
					ray.force_raycast_update()
					if ray.is_colliding():
						Eliminar(veci, true)
					else:
						veci.DesVerificar(self)
			# solo una verificacion a la vez
			break

func DesVerificar(puerta):
	var p = destino.find(puerta)
	if p != -1:
		verificar[p] = false

func Resetear():
	var puertas = get_tree().get_nodes_in_group("puerta")
	var ok
	for p in puertas:
		ok = 0
		while ok != -1:
			ok = p.conect.find(0)
			if ok != -1:
				p.Remover(ok, false)
	for p in puertas:
		p.MyRomboy()

func Agregar(des, cost, nex, con):
	destino.append(des)
	costo.append(cost)
	next.append(nex)
	if con == 2:
		if get_parent().is_in_group("puerto"):
			conect.append(2)
		else:
			conect.append(3)
	else:
		conect.append(con)
	verificar.append(true)
	MyRomboy()

func Reemplazar(des, cost, nex, con, excluir=false):
	var p = destino.find(des)
	if p == -1:
		Agregar(des, cost, nex, con)
	elif excluir:
		Remover(p, false)
		Resetear()
	else:
		costo[p] = cost
		next[p] = nex
		conect[p] = con
		verificar[p] = true
		MyRomboy()

func Conectar(puerta, excluir=false, tipo=1):
	var c = puerta.global_position.distance_to(global_position)
	Reemplazar(puerta, c, puerta, tipo, excluir)
	get_node("Clk").start(rand_range(1, 1.5))
	get_node("Verifica").start(rand_range(2, 2.5))

func Eliminar(puerta, forzado=false, romb=true, reset=true):
	var p = destino.find(puerta)
	if p != -1:
		if forzado:
			puerta.Eliminar(self, false, true, false)
		Remover(p, false)
	while true:
		p = next.find(puerta)
		if p == -1:
			break
		else:
			Remover(p, false)
	if reset:
		Resetear()
	elif romb:
		MyRomboy()

func Remover(ind, romb=true):
	destino.remove(ind)
	costo.remove(ind)
	next.remove(ind)
	conect.remove(ind)
	verificar.remove(ind)
	if romb:
		MyRomboy()

func MyRomboy():
	if romboy == null:
		# poner romboy
		romboy = load("res://scenes/otros/Romboy.tscn").instance()
		var mundo = get_tree().get_nodes_in_group("mundo")[0]
		mundo.get_node("Romboys").add_child(romboy)
		romboy.position = global_position
	if get_parent().is_in_group("calle"):
		var tot = 0
		var inedi = false
		for i in range(destino.size()):
			if conect[i] == 1:
				if is_instance_valid(next[i]):
					if next[i].get_parent().is_in_group("calle"):
						tot += 1
					else:
						inedi = true
		if inedi:
			romboy.get_node("Rombo").visible = tot != 2 and tot != 1
		else:
			romboy.get_node("Rombo").visible = tot != 2
	else:
		romboy.get_node("Rombo").visible = false
	AllTramos()
	if get_parent().is_in_group("puerto"):
		get_parent().PoneLinea()

func Porton():
	# pone conexion automatica a edificaciones
	if get_parent().is_in_group("porton"):
		var newCalle = null
		var minDis = disPorton
		var anterior = conect.find(1)
		if anterior == -1 or randf() < 0.1:
			if get_parent().is_in_group("conReserva"):
				minDis += get_parent().get_node("Reserva/Coli").shape.radius
			var mundo = get_tree().get_nodes_in_group("mundo")[0]
			var cll = get_tree().get_nodes_in_group("calle")
			var ray = get_node("Ray")
			var p1 = global_position
			var p2
			var dis
			for c in cll:
				p2 = c.position
				dis = p1.distance_to(p2)
				if dis < minDis:
					if mundo.LineaTierra(p1, dis, p1.direction_to(p2)):
						ray.cast_to = p2 - p1
						ray.force_raycast_update()
						if not ray.is_colliding():
							minDis = dis
							newCalle = c.get_node("Puerta")
		if newCalle != null:
			if anterior != -1:
				if destino[anterior] == newCalle:
					return 0
				else:
					# limpiar condicion de exepcion con reserva
					if get_parent().is_in_group("conReserva"):
						if is_instance_valid(destino[anterior]):
							var reservu = get_parent().get_node("Reserva")
							destino[anterior].get_node("Ray").remove_exception(reservu)
					Eliminar(destino[anterior], true, false)
			Agregar(newCalle, minDis, newCalle, 1)
			newCalle.Reemplazar(self, minDis, self, 1)
			# prevenir colisionar con reserva de parque
			if get_parent().is_in_group("conReserva"):
				var reserve = get_parent().get_node("Reserva")
				newCalle.get_node("Ray").add_exception(reserve)

func AllTramos():
	# destruir todo
	for t in tramos:
		t.queue_free()
	tramos = []
	# crear todo
	var veci
	for i in range(destino.size()):
		# solo procesa puertas no distantes y en cola para verificacion
		if conect[i] == 1:
			veci = destino[i]
			# verificar que exista el vecino
			if is_instance_valid(veci):
				var p1 = global_position
				var p2 = veci.global_position
				NewTramo(p1, p1.distance_to(p2) * 0.5, p1.direction_to(p2))

func NewTramo(pos, distan, direct):
	var mundo = get_tree().get_nodes_in_group("mundo")[0]
	if mundo.LineaTierra(pos, distan, direct):
		var paso = float(distan) / max(1, ceil(distan / 60.0))
		var esc = paso / 60.0
		var rot = direct.angle()
		var p = paso * 0.5
		while p < distan - (paso * 0.5 - 10):
			tramos.append(mundo.losTramos.instance())
			mundo.get_node("Tramos").add_child(tramos[-1])
			tramos[-1].scale = Vector2(esc, 1)
			tramos[-1].position = pos + direct * p
			tramos[-1].rotation = rot
			p += paso

func Proximo(dest):
	# busca la puerta desde la actual para llegar al destino
	var p = -1
	var minRec = -1
	for i in range(destino.size()):
		if destino[i] == dest:
			if conect[i] < 2:
				if costo[i] <= minRec or minRec == -1:
					minRec = costo[i]
					p = i
			elif conect[i] == 2:
				if PuertoAbierto():
					if costo[i] <= minRec or minRec == -1:
						minRec = costo[i]
						p = i
	if p != -1:
		var c = destino.find(next[p])
		if c != -1:
			if is_instance_valid(next[p]):
				return [next[p], conect[c]]
	return [null, 0]

func TieneDestino(dest):
	for d in destino:
		if d == dest:
			return true
	return false

func CostoDestino(dest):
	var minimo = -1
	for d in range(destino.size()):
		if destino[d] == dest:
			if minimo == -1 or costo[d] < minimo:
				minimo = costo[d]
	return minimo

func _on_Clk_timeout():
	get_node("Clk").start(rand_range(sClk[0], sClk[1]))
	RIP()
	if debug:
		get_node("Total").text = str(destino.size())

func PreSave(buffer):
	buffer.put_float(global_position.x)
	buffer.put_float(global_position.y)

func Save(buffer):
	PreSave(buffer)
	var tot = 0
	for i in range(destino.size()):
		if conect[i] != 0 and is_instance_valid(destino[i]):
			tot += 1
	buffer.put_u16(tot)
	for i in range(destino.size()):
		if conect[i] != 0 and is_instance_valid(destino[i]):
			buffer.put_u8(conect[i])
			buffer.put_float(destino[i].global_position.x)
			buffer.put_float(destino[i].global_position.y)

func Open(buffer, puertas=[]):
	if puertas.empty():
		puertas = get_tree().get_nodes_in_group("puerta")
	var tot = buffer.get_u16()
	var tipi
	var posD = Vector2(0, 0)
	for _r in range(tot):
		tipi = buffer.get_u8()
		posD.x = buffer.get_float()
		posD.y = buffer.get_float()
		for p in puertas:
			if p.global_position.x == posD.x and p.global_position.y == posD.y:
				Conectar(p, false, tipi)
				break

func _on_Puerta_tree_exiting():
	if romboy != null:
		romboy.queue_free()
	for t in tramos:
		t.queue_free()

func _on_Rombo_timeout():
	MyRomboy()

func _on_Verifica_timeout():
	get_node("Verifica").start(rand_range(sClk[0], sClk[1]) * 2.0)
	Verifique()
	Porton()

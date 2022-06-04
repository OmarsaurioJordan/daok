extends Panel

func _ready():
	get_node("Version").text = get_parent().version
	get_node("Minimapa/Mapa").frame = get_parent().mapa - 1
	# cargar ruta de archivos
	var path = ""
	var directory = Directory.new()
	if directory.file_exists("user://path.txt"):
		var file = File.new()
		if file.open("user://path.txt", File.READ) == OK:
			path = file.get_as_text()
			file.close()
	get_node("FileDialog").current_file = path.get_file()
	get_node("FileDialog").current_dir = path.get_base_dir()
	get_node("FileDialog").current_path = path
	get_node("Minimapa/Mapa").frame = randi() % 11

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func _on_BGodot_button_down():
	var _g = OS.shell_open("https://godotengine.org/")

func _on_BEditable_button_down():
	var _g = OS.shell_open("https://github.com/OmarsaurioJordan/Daok")

func _on_BOmwekiatl_button_down():
	var _g = OS.shell_open("https://omwekiatl.itch.io/")

func _on_BDEValen_button_down():
	var _g = OS.shell_open("https://www.youtube.com/c/DEValen")

func _on_BGuinxu_button_down():
	var _g = OS.shell_open("https://www.youtube.com/c/Guinxu")

func _on_BJasperDev_button_down():
	var _g = OS.shell_open("https://www.youtube.com/c/JasperDev")

func _on_BAlvaMajo_button_down():
	var _g = OS.shell_open("https://www.youtube.com/c/AlvaMajo")

func _on_BSDev_button_down():
	var _g = OS.shell_open("https://www.youtube.com/c/SDevYT")

func _on_BJLPM_button_down():
	var _g = OS.shell_open("https://www.youtube.com/c/JLPMGameDev")

func _on_BNueva_button_down():
	var aux = load("res://scenes/Mundo.tscn").instance()
	get_parent().add_child(aux)
	aux.NuevoMundo()
	queue_free()

func _on_BMapL_button_down():
	get_parent().CambiaMapa(false)
	get_node("Minimapa/Mapa").frame = get_parent().mapa - 1

func _on_BMapR_button_down():
	get_parent().CambiaMapa(true)
	get_node("Minimapa/Mapa").frame = get_parent().mapa - 1

func _on_BImportar_button_down():
	get_node("FileDialog").window_title = "Importar archivo de partida"
	get_node("FileDialog").mode = FileDialog.MODE_OPEN_FILE
	get_node("FileDialog").popup()

func _on_BExportar_button_down():
	var directory = Directory.new()
	if directory.file_exists("user://savegame.save"):
		get_node("FileDialog").window_title = "Exportar archivo de partida"
		get_node("FileDialog").mode = FileDialog.MODE_SAVE_FILE
		get_node("FileDialog").popup()

func _on_BAbrir_button_down():
	var directory = Directory.new()
	if directory.file_exists("user://savegame.save"):
		var aux = load("res://scenes/Mundo.tscn").instance()
		get_parent().add_child(aux)
		if aux.Abrir("user://savegame.save"):
			queue_free()
		else:
			aux.queue_free()

func _on_FileDialog_file_selected(path):
	# guardar el path general
	get_node("FileDialog").current_file = path.get_file()
	get_node("FileDialog").current_dir = path.get_base_dir()
	get_node("FileDialog").current_path = path
	var file = File.new()
	if file.open("user://path.txt", File.WRITE) == OK:
		file.store_string(path)
		file.close()
	# ahora si administrar seleccion
	var directory = Directory.new()
	if get_node("FileDialog").mode == FileDialog.MODE_OPEN_FILE:
		directory.remove("user://savegame.save")
		directory.copy(path, "user://savegame.save")
		_on_BAbrir_button_down()
	else:
		if directory.file_exists("user://savegame.save"):
			directory.copy("user://savegame.save", path)

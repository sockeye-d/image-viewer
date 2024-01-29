extends Control


@export var image: TextureRect
@export var path_str_from_clipboard: String
@export var meta_str: String


@onready var path_btn: Button = %PathButton
@onready var meta_btn: Button = %MetaButton
@onready var formats = ClassDB.class_get_enum_constants("Image", "Format")


var image_size: float = 1.0
var file_filter: PackedStringArray


func _ready() -> void:
	path_btn.pressed.connect(_on_clipboard_pressed.bind(path_btn))
	meta_btn.pressed.connect(_on_clipboard_pressed.bind(meta_btn))
	get_window().files_dropped.connect(_on_window_files_dropped)
	$MarginContainer/BottomMenuLeft.hide()
	
	file_filter = ($FileDialog.filters[0]
			.split(";")[0] # Remove the filter label 
			.replace(" ", "") # Remove all spaces between the types
			.replace("*.", "") # Convert "*.png" into just "png"
			.split(",")) # Split each type into an element
	
	for arg in OS.get_cmdline_args():
		if _verify_path(arg):
			set_image_from_file(arg)
			break


func _process(_delta: float) -> void:
	image.custom_minimum_size = image_size * get_rect().size
	$MarginContainer/BottomMenuRight/ZoomButton.text = str(roundf(image_size * 100)) + "%"
	if Input.is_action_just_released("ui_cancel"):
		get_window().queue_free()


func load_from_file() -> void:
	$FileDialog.show()
	# Flow continues in _on_file_dialog_file_selected


func set_image_from_file(file: String) -> void:
	$MarginContainer/BottomMenuLeft/PathButton.show()
	$MarginContainer/BottomMenuLeft/VSep.show()
	path_btn.text = file
	var img = Image.new()
	img.load(file)
	img.generate_mipmaps()
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	set_image(tex)


func load_from_clipboard() -> void:
	$MarginContainer/BottomMenuLeft/PathButton.hide()
	$MarginContainer/BottomMenuLeft/VSep.hide()
	if DisplayServer.clipboard_has_image():
		var img: Image = DisplayServer.clipboard_get_image()
		img.generate_mipmaps()
		set_image(ImageTexture.create_from_image(img))
		path_btn.text = path_str_from_clipboard


func set_image(img: ImageTexture) -> void:
	$MarginContainer/BottomMenuLeft.show()
	image.texture = img
	image.material.set_shader_parameter("tex", img)
	var img_size: Vector2 = img.get_size()
	meta_btn.text = meta_str.format({
			"w": img_size.x,
			"h": img_size.y,
			"f": format_to_str(img.get_format()),
			})
	
	#image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL if img_size.x < img_size.y else TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL


func format_to_str(f: Image.Format) -> String:
	var s: String = formats[f]
	return s.split("_")[1]


func _verify_path(path: String) -> bool:
	var ext = path.split(".")[-1]
	return ext in file_filter


func _on_file_index_pressed(index: int) -> void:
	match index:
		0:
			load_from_file()
		1:
			DisplayServer.clipboard_set(path_btn.text)
		2:
			load_from_clipboard()
		3:
			$MarginContainer/TopMenu/TopMenu/File.set_item_checked(2, not $MarginContainer/TopMenu/TopMenu/File.is_item_checked(2))
			get_window().always_on_top = $MarginContainer/TopMenu/TopMenu/File.is_item_checked(2)


func _on_texture_filter_options_item_selected(index: int) -> void:
	image.material.set_shader_parameter("filter", index)


func _on_scroll_container_gui_input(event: InputEvent) -> void:
	var m := event as InputEventMouseButton
	if not m == null:
		if m.ctrl_pressed:
			var axis = m.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP as float
			axis -= m.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN as float
			image_size += axis * 0.025
			image_size = max(image_size, 0.025)
			get_viewport().set_input_as_handled()


func _on_clipboard_pressed(btn: Button) -> void:
	DisplayServer.clipboard_set(btn.text)



func _on_zoom_button_pressed() -> void:
	image_size = 1.0



func _on_window_files_dropped(files: PackedStringArray) -> void:
	var file = files[0]
	var ext = file.split(".")[-1]
	if ext in file_filter:
		set_image_from_file(files[0])


func _on_file_dialog_file_selected(path: String) -> void:
	if path:
		set_image_from_file(path)

extends Control


@export var image: TextureRect
@export var path_str_from_clipboard: String
@export var meta_str: String

@onready var path_label: Label = %PathLabel
@onready var meta_label: Label = %MetaLabel


func _process(_delta: float) -> void:
	image.custom_minimum_size.y = image_size * get_rect().size.y


var image_size: float = 0.5
func _on_file_index_pressed(index: int) -> void:
	match index:
		0:
			load_from_clipboard()
		1:
			load_from_file()


func load_from_file() -> void:
	$FileDialog.show()
	var file: String = await $FileDialog.file_selected
	if file:
		path_label.text = file
		var img = Image.new()
		img.load(file)
		var tex: ImageTexture = ImageTexture.create_from_image(img)
		set_image(tex)


func load_from_clipboard() -> void:
	if DisplayServer.clipboard_has_image():
		set_image(ImageTexture.create_from_image(DisplayServer.clipboard_get_image()))
		path_label.text = path_str_from_clipboard


func set_image(img: ImageTexture) -> void:
	image.texture = img
	image.material.set_shader_parameter ("tex", img)
	meta_label.text = meta_str.format({
			"w": img.get_width(),
			"h": img.get_height(),
			"f": img.get_format(),
			})


func _on_texture_filter_options_item_selected(index: int) -> void:
	image.material.set_shader_parameter ("filter", index)


func _on_scroll_container_gui_input(event: InputEvent) -> void:
	var m := event as InputEventMouseButton
	if not m == null:
		if m.ctrl_pressed:
			var axis = m.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP as float
			axis -= m.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN as float
			image_size += axis * 0.01
			image_size = max(image_size, 0.01)
			get_viewport().set_input_as_handled()


func _on_clipboard_pressed() -> void:
	DisplayServer.clipboard_set(path_label.text)


func _on_always_on_top_toggle_toggled(toggled_on: bool) -> void:
	get_window().always_on_top = toggled_on

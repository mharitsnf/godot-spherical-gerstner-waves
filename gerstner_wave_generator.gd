@tool
class_name GersnterWaveGenerator extends Node


@export_tool_button("Generate", "Callable") var generate_action: Callable = _generate_wave_texture
@export var num_of_waves: int = 30
@export var filename: String


func _generate_wave_texture() -> void:
	var img: Image = Image.create(2, num_of_waves, false, Image.FORMAT_RGBAF)
	randomize()
	for i: int in num_of_waves:
		var data: Color = Color(randf(), randf(), randf(), randf())
		var direction: Color = Color(randf(), randf(), randf(), 1.0)
		img.set_pixel(0, i, data)
		img.set_pixel(1, i, direction)

	img.save_png("res://gerstner_waves/%s.png" % filename)
	print("Gerstner data texture generated! (res://gerstner_waves/%s.png)" % filename)
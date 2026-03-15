extends Node2D

@export var next_scene_path := "res://scenes/level_zero.tscn"

const SLIDES := [
	"Nanowirus przejął kontrolę nad każdym neuronem, zamieniając miliardy ludzi w bezmyślne zombie. To nie są już osoby – to organiczne procesory, armia „żywych serwerów” połączona w jedną, globalną sieć obliczeniową potężnej AI.",
	"Takashi. Samuraj z dawnej epoki, przebudzony z kriogenicznego snu. Jako jedyna istota wolna od cyfrowego skażenia, jest dla maszyn nieobliczalną anomalią.",
	"Wyposażony w katanę z antymonitu, Takashi musi fizycznie zniszczyć rdzeń procesowy AI, by odłączyć ludzkość od nieskończonej pętli kodu."
]

var _slide_index := 0
var _overlay: ColorRect
var _text_label: RichTextLabel
var _hint_label: Label
var _intro_active := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	_show_slide()

func _input(event: InputEvent) -> void:
	if !_intro_active:
		return
	var viewport = get_viewport()
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed:
			_next_slide()
			if viewport:
				viewport.set_input_as_handled()
			return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and !key_event.echo:
			_next_slide()
			if viewport:
				viewport.set_input_as_handled()
			return
	if event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		_next_slide()
		if viewport:
			viewport.set_input_as_handled()

func _build_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 1)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	canvas.add_child(_overlay)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = false
	_text_label.fit_content = false
	_text_label.scroll_active = false
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("normal_font_size", 38)
	_text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text_label.offset_left = 180.0
	_text_label.offset_top = 170.0
	_text_label.offset_right = -180.0
	_text_label.offset_bottom = -220.0
	_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_text_label)

	_hint_label = Label.new()
	_hint_label.text = "Kliknij lub naciśnij dowolny klawisz, aby kontynuować"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 24)
	_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hint_label.offset_top = -95.0
	_hint_label.offset_bottom = -35.0
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_hint_label)

func _show_slide() -> void:
	_text_label.text = SLIDES[_slide_index]

func _next_slide() -> void:
	_slide_index += 1
	if _slide_index >= SLIDES.size():
		_finish_intro()
		return
	_show_slide()

func _finish_intro() -> void:
	_intro_active = false
	if is_instance_valid(_overlay):
		_overlay.get_parent().queue_free()
	if get_tree() != null:
		get_tree().change_scene_to_file(next_scene_path)

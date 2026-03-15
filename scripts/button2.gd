extends Button
@export var main_menu_scene_path = "res://scenes/main_menu.tscn"

# Function that runs when the button is pressed
func _ready():
	# Connect the button's "pressed" signal to a custom function
	self.connect("pressed", Callable(self, "_on_restart_button_pressed"))

# Function to handle button press and go back to main menu
func _on_restart_button_pressed():
	get_tree().change_scene_to_file(main_menu_scene_path)

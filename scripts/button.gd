extends Button
# Define the path to your first scene (usually the main menu or initial gameplay scene)
@export var first_scene_path = "res://scenes/level_zero.tscn"

# Function that runs when the button is pressed
func _ready():
	# Connect the button's "pressed" signal to a custom function
	self.connect("pressed", Callable(self, "_on_restart_button_pressed"))

# Function to handle button press and go to the first scene
func _on_restart_button_pressed():
	var retry_scene = Pokoj.get_retry_scene_path()
	if retry_scene == "" or retry_scene == "start":
		retry_scene = first_scene_path
	get_tree().change_scene_to_file(retry_scene)

extends Button

# Function that runs when the button is pressed
func _ready():
	# Connect the button's "pressed" signal to a custom function
	self.connect("pressed", Callable(self, "_on_quit_button_pressed"))

# Function to handle button press and quit the game
func _on_quit_button_pressed():
	# Close the game
	get_tree().quit()

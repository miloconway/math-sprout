extends Control

# Use @onready to get buttons by their node names
@onready var button1: Button = $HBoxContainer1/Button
@onready var button2: Button = $HBoxContainer2/Button
@onready var button3: Button = $HBoxContainer3/Button
@onready var question_label: RichTextLabel = $QuizLabel  # Label to display the math question
@onready var treeSprite: AnimatedSprite2D = $TreeSprite  # Sprite to show progression
@onready var flash_overlay: ColorRect = $ColorRect

# Define custom signals
signal game_won
signal game_reset

# Game variables
var math_operations = []  # Store all generated operations
var correct_answer: int   # The answer to the displayed question
var displayed_operation: String  # The operation shown to the user
var is_won_state: bool = false  # Track if the game is in win state

# Structure to hold a math operation
class MathOperation:
	var num1: int
	var num2: int
	var operator: String
	var result: int
	var display_text: String
	
	func _init(n1: int, n2: int, op: String):
		num1 = n1
		num2 = n2
		operator = op
		result = calculate_result()
		display_text = str(num1) + " " + operator + " " + str(num2)
	
	func calculate_result() -> int:
		match operator:
			"+":
				return num1 + num2
			"-":
				return num1 - num2
			"×":
				return num1 * num2
			"÷":
				return num1 / num2
			_:
				return 0

func _ready():
	# Connect custom signals to their handlers
	game_won.connect(_on_game_won)
	game_reset.connect(_on_game_reset)
	
	generate_new_problem()
	connect_button_signals()
	setup_flash_overlay()

func generate_math_operation() -> MathOperation:
	var num1 = randi() % 9 + 1  # Random number 1-9
	var num2 = randi() % 9 + 1  # Random number 1-9
	var operations = ["+", "-", "×", "÷"]
	var operator = operations[randi() % operations.size()]
	
	# For division, ensure clean division (no remainder)
	if operator == "÷":
		# Make sure num1 is divisible by num2
		num1 = num2 * (randi() % 9 + 1)  # This ensures clean division
	
	# For subtraction, ensure positive result
	if operator == "-" and num2 > num1:
		var temp = num1
		num1 = num2
		num2 = temp
	
	return MathOperation.new(num1, num2, operator)

func generate_new_problem():
	# Don't generate new problems if game is won
	if is_won_state:
		return
		
	math_operations.clear()
	var used_results = []
	
	# Generate 3 math operations with unique results
	while math_operations.size() < 3:
		var operation = generate_math_operation()
		
		# Check if this result is already used
		if not used_results.has(operation.result):
			math_operations.append(operation)
			used_results.append(operation.result)
	
	# Populate buttons with results
	populate_button_answers()
	
	# Choose one operation to display as the question
	var question_index = randi() % math_operations.size()
	var question_operation = math_operations[question_index]
	
	displayed_operation = question_operation.display_text
	correct_answer = question_operation.result
	
	# Display the question
	question_label.text = displayed_operation + " = ?"

func connect_button_signals():
	# Connect button pressed signals to handler function
	if button1:
		button1.pressed.connect(_on_button_pressed.bind(button1))
	if button2:
		button2.pressed.connect(_on_button_pressed.bind(button2))
	if button3:
		button3.pressed.connect(_on_button_pressed.bind(button3))

func populate_button_answers():
	var buttons = [button1, button2, button3]
	
	for i in range(min(buttons.size(), math_operations.size())):
		if buttons[i]:
			buttons[i].text = str(math_operations[i].result)

func _on_button_pressed(button: Button):
	# Handle reset button press when game is won
	if is_won_state and button == button2 and button.text == "Yes":
		game_reset.emit()
		return
	
	# Normal game logic
	if not is_won_state:
		var selected_answer = int(button.text)
		
		if selected_answer == correct_answer:
			handle_correct_answer()
		else:
			handle_wrong_answer()

func handle_correct_answer():
	flash_green_screen()
	treeSprite.frame += 1
	
	# Check if we've reached the last frame and emit win signal
	var max_frames = treeSprite.sprite_frames.get_frame_count(treeSprite.animation)
	if treeSprite.frame >= max_frames - 1:
		game_won.emit()
		return
	
	generate_new_problem()

func handle_wrong_answer():
	flash_red_screen()
	# You could add lives/attempts system here

# Signal handler for game won
func _on_game_won():
	is_won_state = true
	
	# Display win message
	if question_label:
		question_label.text = "You win! Reset?"
	
	# Clear all buttons and show "Yes" only on button2
	if button1:
		button1.text = ""
		button1.visible = false
	if button2:
		button2.text = "Yes"
	if button3:
		button3.text = ""
		button3.visible = false

# Signal handler for game reset
func _on_game_reset():
	is_won_state = false
	
	# Make all buttons visible again
	if button1:
		button1.visible = true
	if button3:
		button3.visible = true
	
	# Reset tree sprite to first frame
	treeSprite.frame = 0
	
	# Generate a new problem
	generate_new_problem()

func setup_flash_overlay():
	flash_overlay.modulate.a = 0.0  # Start transparent
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse input
	flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Cover entire screen

func flash_red_screen():
	if not flash_overlay:
		return
		
	flash_overlay.color = Color.RED
	tween_flash_overlay()
	
func flash_green_screen():
	if not flash_overlay:
		return
		
	flash_overlay.color = Color.WEB_GREEN
	tween_flash_overlay()

func tween_flash_overlay():
	# Create a tween for the flash animation
	var tween = create_tween()
	
	# Flash red quickly then fade out
	tween.tween_property(flash_overlay, "modulate:a", 0.5, 0.1)  # Fade in red overlay
	tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.2)  # Fade out

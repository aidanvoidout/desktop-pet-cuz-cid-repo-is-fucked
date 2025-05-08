extends Node2D

@onready var sprite: AnimatedSprite2D = $sprite

const GRAVITY: int = 9.8

var velocity: Vector2 = Vector2.ZERO
var state: String = "idle"
var time_passed = 0
var target_move_pos_x: int = -1
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var default_y: int
var just_landed: bool = false

signal reached

func _ready() -> void:
	var screensize: Vector2 = get_window().size
	sprite.global_position = Vector2(1000, screensize.y) + Vector2(0, -16) * sprite.scale
	default_y = sprite.global_position.y
	set_passthrough(sprite)
	
	
func _process(delta: float) -> void:
	set_passthrough(sprite)
	
	var screensize: Vector2 = get_window().size
	time_passed += delta
	
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false
	
	sprite.global_position += delta * velocity
	
	if target_move_pos_x != -1 and state != "sitting":
		if (velocity.x < 0 and sprite.global_position.x <= target_move_pos_x) or \
		   (velocity.x > 0 and sprite.global_position.x >= target_move_pos_x):
			sprite.global_position.x = target_move_pos_x
			velocity = Vector2.ZERO
			target_move_pos_x = -1
			state = "idle"
			reached.emit()
	
	if time_passed > 5 and target_move_pos_x == -1 and not is_dragging and state != "falling" and state != "sitting":
		time_passed = 0
		var r = randi_range(1, 7)
		if r == 1:
			var target_position = randi_range(1, screensize.x)
			move_to(target_position)
			state = "walking"
		elif r == 2:
			var target_position = 300
			move_to(target_position)
			state = "walking"
			await reached
			state = "sitting"
			sprite.flip_h = false
			await get_tree().create_timer(randi_range(15, 30)).timeout
			state = "idle"
		else:
			state = "idle"
		
	if is_dragging and not just_landed and not state == "sitting":
		target_move_pos_x = -1
		state = "hanging"
		
	if not is_dragging and sprite.global_position.y < default_y and not just_landed:
		velocity += Vector2(0, GRAVITY)
		target_move_pos_x = -1
		state = "falling"
		
	if sprite.global_position.y >= default_y:
		velocity = Vector2(velocity.x, 0)
		sprite.global_position = Vector2(sprite.global_position.x, default_y)
		if not just_landed and state == "falling":
			just_landed = true
			target_move_pos_x = -1
			await get_tree().create_timer(0.05).timeout
			just_landed = false
	
	if just_landed:
		target_move_pos_x = -1
		state = "idle"
		
	if target_move_pos_x == -1:
		velocity = Vector2(0, velocity.y)
		
	handle_states()

func _input(event: InputEvent) -> void:
	# Check for mouse button events
	if event is InputEventMouseButton:
		# Only start dragging if mouse is within passthrough area
		if event.pressed and is_mouse_within_passthrough_area(event.position):
			is_dragging = true
			drag_offset = sprite.position - event.position
		elif not event.pressed:
			is_dragging = false
	# Handle mouse motion while dragging
	elif event is InputEventMouseMotion and is_dragging:
		sprite.position = event.position + drag_offset


# Function to check if the mouse is within the passthrough area of the sprite
func is_mouse_within_passthrough_area(mouse_pos: Vector2) -> bool:
	# Get the corners of the passthrough area (calculated in set_passthrough)
	var passthrough_area = get_passthrough_area()
	return passthrough_area.has_point(mouse_pos)

# Function to calculate the passthrough area (updated to match sprite's global position and scale)
func get_passthrough_area() -> Rect2:
	var texture_center: Vector2 = Vector2(16, 16) * sprite.scale
	var texture_corners: PackedVector2Array = [
		sprite.position + texture_center * Vector2(-1, -1), # Top left corner
		sprite.position + texture_center * Vector2(1, -1),  # Top right corner
		sprite.position + texture_center * Vector2(1, 1),   # Bottom right corner
		sprite.position + texture_center * Vector2(-1, 1)   # Bottom left corner
	]
	var min_x = texture_corners[0].x - 5
	var max_x = texture_corners[1].x + 5
	var min_y = texture_corners[0].y + 5
	var max_y = texture_corners[2].y - 5
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))



func move_to(x: int):
	# Set target position and velocity
	target_move_pos_x = x
	
	if sprite.global_position.x < target_move_pos_x:
		velocity = Vector2(400, 0)
	else:
		velocity = Vector2(-400, 0)

func set_passthrough(sprite: AnimatedSprite2D):
	var texture_center: Vector2 = Vector2(16, 16) * sprite.scale
	var texture_corners: PackedVector2Array = [
		sprite.global_position + texture_center * Vector2(-1, -1), # Top left
		sprite.global_position + texture_center * Vector2(1, -1), # Top right
		sprite.global_position + texture_center * Vector2(1, 1),  # Bottom right
		sprite.global_position + texture_center * Vector2(-1, 1)  # Bottom left
	]
  
	DisplayServer.window_set_mouse_passthrough(texture_corners)
	
	return texture_corners

func handle_states():
	match state:
		"idle":
			sprite.play("default")
		"walking":
			sprite.play("walk")
		"hanging":
			sprite.play("hang")
		"falling":
			sprite.play("fall")
		"sitting":
			sprite.play("sit")
			

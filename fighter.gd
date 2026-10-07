extends CharacterBody2D

@export var input_prefix: String = "p1"
@export var walk_speed: float = 300.0
@export var jump_velocity: float = -900.0
@export var gravity: float = 2400.0

const STAND_HEIGHT := 180.0
const CROUCH_HEIGHT := 110.0
const BODY_WIDTH := 80.0

@onready var body: ColorRect = $Body
@onready var shape_node: CollisionShape2D = $CollisionShape2D

var is_crouching := false


func _ready() -> void:
	# Setiap petarung memakai salinan bentuk tabrakan sendiri
	shape_node.shape = shape_node.shape.duplicate()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	_set_crouch(Input.is_action_pressed(input_prefix + "_crouch") and is_on_floor())

	if is_crouching:
		velocity.x = 0.0
	else:
		var dir := Input.get_axis(input_prefix + "_left", input_prefix + "_right")
		velocity.x = dir * walk_speed

	if Input.is_action_just_pressed(input_prefix + "_jump") and is_on_floor() and not is_crouching:
		velocity.y = jump_velocity

	move_and_slide()


func _set_crouch(value: bool) -> void:
	if value == is_crouching:
		return
	is_crouching = value
	var h := CROUCH_HEIGHT if value else STAND_HEIGHT
	body.size = Vector2(BODY_WIDTH, h)
	body.position = Vector2(-BODY_WIDTH / 2.0, -h)
	var rect := shape_node.shape as RectangleShape2D
	rect.size = Vector2(BODY_WIDTH, h)
	shape_node.position = Vector2(0, -h / 2.0)

# A behavior that turns an object into a movable character that can move along
# a plane. Great for top down characters, shoot-em-ups, and more!

# How to use
#
# To add a behavior to an object, drag the ".tscn" file from the main folder
# onto the object to add it as a child. That way, you can add multiple behaviors
# to the same object.


extends Node

# The fastest this object can move each second
export var max_speed = 10
# How fast (in units/s^2) the object should accelerate.
# Higher values feel more lighter, lower values feel heavier
export var acceleration = 100
# How fast (in units/s^2) the object should decelerate.
# Higher values feel like an RC car, lower values feel like a boat.
# Set to near zero for a space ship like effect.
export var deceleration = 150
# Which directions to allow movement in.
# Use 8 direction for most top-down movements, 4 direction for old-school games,
# left/right for shoot-em-ups or breakout, and up/down for pong-like things.
export(int, "Up/Down", "Left/Right", "4 direction", "8 direction") var directions = 3
# Which axes to move in.
export(int, "x/y", "x/z", "z/y") var axes = 1;
# Whether to set the angle when moving the object.
# Use continuous for realistic looking movement. Other values give a more
# old-school look and feel.
export(int, "Don't set angle", "Continuous", "45 degrees", "90 degrees") var angle_snap = 1
# Whether to enable the default arrow key controls. Useful for prototyping.
export(bool) var default_controls = true
# Set to false to disable this movement behavior.
export(bool) var enabled = true

# Set these from a separate script to set up your own input
var move_left = false
var move_right = false
var move_up = false
var move_down = false

var velocity = Vector2(0, 0)
# if velocity is below this, it will be zeroed so the object stops
var deadzone = 0.0001

var last_press = -1

enum Directions {UpDown, LeftRight, Four, Eight}
enum Axes {XY, XZ, ZY}
enum AngleSnap {NoSnap, Continuous, FortyFive, Ninety}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not enabled:
		return
	
	if default_controls:
		handle_default_input()
	
	compute_velocity(delta)
	move(delta)
	set_angle()
	reset_all_inputs()

func _input(event):
	if event is InputEventKey:
		last_press = event.scancode

func handle_default_input():
	move_left = Input.is_physical_key_pressed(KEY_LEFT)
	move_right = Input.is_physical_key_pressed(KEY_RIGHT)
	move_up = Input.is_physical_key_pressed(KEY_UP)
	move_down = Input.is_physical_key_pressed(KEY_DOWN)
	
	if directions == Directions.Four:
		if (move_left or move_right) and (last_press == KEY_LEFT or last_press == KEY_RIGHT):
			move_up = false
			move_down = false
		if (move_up or move_down) and (last_press == KEY_UP or last_press == KEY_DOWN):
			move_left = false
			move_right = false

func compute_axis_velocity(cur_velocity, move_negative, move_positive, delta):
	if move_positive and not move_negative:
		if cur_velocity > 0:
			return min(max_speed, cur_velocity + delta * acceleration)
		else:
			return min(max_speed, cur_velocity + delta * (acceleration + deceleration))
	elif move_negative and not move_positive:
		if cur_velocity < 0:
			return max(-max_speed, cur_velocity - delta * acceleration)
		else:
			return max(-max_speed, cur_velocity - delta * (acceleration + deceleration))
	else:
		if cur_velocity > deadzone:
			return max(0, cur_velocity - delta * deceleration)
		elif cur_velocity < deadzone:
			return min(0, cur_velocity + delta * deceleration)
		else:
			return 0

func compute_velocity(delta):
	if directions != Directions.UpDown:
		velocity.x = compute_axis_velocity(velocity.x, move_left, move_right, delta)
	if directions != Directions.LeftRight:
		velocity.y = compute_axis_velocity(velocity.y, move_down, move_up, delta)



func move(delta):
	match axes:
		Axes.XY:
			get_parent().translation.x += velocity.x * delta
			get_parent().translation.y += velocity.y * delta
		Axes.XZ:
			get_parent().translation.x += velocity.x * delta
			get_parent().translation.z -= velocity.y * delta
		Axes.ZY:
			get_parent().translation.z -= velocity.x * delta
			get_parent().translation.y += velocity.y * delta
			get_parent().translation.y += velocity.y * delta
			
func set_angle():
	if angle_snap == AngleSnap.NoSnap:
		return
	
	# Not exactly the deadzone, but a faster approximation
	var is_in_deadzone = velocity.length_squared() < deadzone
	if is_in_deadzone:
		return
	
	var snap_angle = 0.01
	match angle_snap:
		AngleSnap.FortyFive:
			snap_angle = PI / 4
		AngleSnap.Ninety:
			snap_angle = PI / 2
			
	var angle = Vector2(0, 1).angle_to(velocity)
	angle = round(angle / snap_angle) * snap_angle
	
	match axes:
		Axes.XY:
			get_parent().rotation.z = angle
		Axes.XZ:
			get_parent().rotation.y = angle
		Axes.ZY:
			get_parent().rotation.x = angle

func snap(angle, snap):
	angle = round(angle/snap) * snap
	

func reset_all_inputs():
	move_left = false
	move_right = false
	move_up = false
	move_down = false

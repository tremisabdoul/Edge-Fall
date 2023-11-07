extends CharacterBody3D


var speed = 5.0
var jump_velocity = 7
var sensibility: Vector2 = -Vector2(.01, .01)
var friction = 2
var is_wallriding = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 4

func _input(event):
	if event is InputEventMouseMotion:
		rotation.y += event.relative.x * sensibility.x
		$Head.rotation.x = clamp(-PI/2, $Head.rotation.x + event.relative.y * sensibility.y, PI/2)
		$Head.rotation.z += event.relative.x * sensibility.x / 10
		$Head.fov = min((120 + 1/friction + $Head.fov + abs(event.relative.x * sensibility.x * 5))/2, 160)

func _physics_process(delta):
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 4
	jump_velocity = 7*2
	var input = Input.get_vector("left", "right", "forward", "backward").normalized()
	var tickspeed = speed
	var was_wallriding = is_wallriding
	is_wallriding = (
		!is_on_floor()
		and
		($WallRide/Bot/Back.is_colliding() or $WallRide/Bot/Left.is_colliding() or $WallRide/Bot/Right.is_colliding())
		and
		($WallRide/Top/Back.is_colliding() or $WallRide/Top/Left.is_colliding() or $WallRide/Top/Right.is_colliding())
		and
		!Input.is_action_pressed("ui_accept")
	)
	#!Input.is_action_pressed("ui_accept")
	if was_wallriding and !is_wallriding and !is_on_floor():
		var direction = $Head.global_transform.basis.z * (input.y + 5*(-float($WallRide/Top/Back.is_colliding())))
		direction += $Head.global_transform.basis.x * (input.x + 5*(float($WallRide/Top/Left.is_colliding())-float($WallRide/Top/Right.is_colliding())))
		velocity.y = 7
		velocity += direction * tickspeed

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		tickspeed *= 2

	if is_wallriding:
		if Input.is_action_pressed("ui_accept"):
			velocity += $Head.global_transform.basis.x * (float($WallRide/Top/Left.is_colliding())-float($WallRide/Top/Right.is_colliding())) * tickspeed
		var direction = $Head.global_transform.basis.z * input.y
		direction += $Head.global_transform.basis.x * input.x
		friction += 1.2 * .1
		friction /= 1.1
		velocity.y = clamp(velocity.y, -6, 3)
		velocity.y -= gravity * delta
		velocity += direction * tickspeed / 2
		velocity.x /= friction
		velocity.y /= friction
		velocity.z /= friction
		var wallriding_dir = float($WallRide/Top/Left.is_colliding())-float($WallRide/Top/Right.is_colliding())
		$Head.rotation.z -= velocity.dot(transform.basis.x) / 1000
		$Head.rotation.z -= wallriding_dir * .15
		$Head.rotation.z /= 1.1
		$Head.rotation.z += wallriding_dir * .15
	elif is_on_floor():
		var direction = transform.basis * Vector3(input.x, 0, input.y)
		velocity += direction * tickspeed
		friction += 2 * .01
		friction /= 1.01
		velocity.x /= max(friction / 1.01, 1.5)
		velocity.z /= max(friction / 1.01, 1.5)
		$Head.rotation.z -= velocity.dot(transform.basis.x) / 1000
		$Head.rotation.z /= 1.1
	else:
		var direction = transform.basis * Vector3(input.x, 0, input.y)
		velocity += direction * tickspeed / 2
		friction += 1.001 * .01
		friction = min(friction / 1.01, 1.25)
		velocity.y -= gravity * delta
		velocity.x /= friction
		velocity.z /= friction
		$Head.rotation.z -= velocity.dot(transform.basis.x) / 1000
		$Head.rotation.z /= 1.1

	print(friction)
	print(int(velocity.length()))

	move_and_slide()

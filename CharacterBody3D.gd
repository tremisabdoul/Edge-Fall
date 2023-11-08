extends CharacterBody3D


var sensibility:    Vector2 = -Vector2(.01, .01)
var gravity:          float = ProjectSettings.get_setting("physics/3d/default_gravity") * 4
var speed:            float = 5.
var jump_velocity:    float = 14.
var is_wallriding:     bool = false
var wallride_stamina: float = 1.
var friction:         float = 2.

func _enter_tree():
	get_window().mode = Window.MODE_FULLSCREEN
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion:
		rotation.y += event.relative.x * sensibility.x
		$Head.rotation.x = clamp(-PI/2, $Head.rotation.x + event.relative.y * sensibility.y, PI/2)
		$Head.rotation.z += event.relative.x * sensibility.x / 10 * (Vector2(velocity.x, velocity.z).length() / 10)
		#$Head.fov = min((120 + 1/friction + $Head.fov + abs(event.relative.x * sensibility.x * 5))/2, 160)

func _physics_process(delta):
	var was_wallriding: bool = is_wallriding
	var current_speed: float = Vector2(velocity.x, velocity.z).length()
	var tickspeed:     float = speed
	var input:       Vector2 = Input.get_vector("left", "right", "forward", "backward").normalized()
	
	$Head.fov = ($Head.fov * 7 + 90 + (89*current_speed)/(current_speed+20))/8
	$Head.attributes.dof_blur_near_distance = current_speed/10 + 1
	$Head.attributes.dof_blur_amount = current_speed/1000 + .05
	$Head.attributes.auto_exposure_scale = exp(current_speed-100) + .3
	
	is_wallriding = (!is_on_floor() and (wallride_stamina > 0) and !Input.is_action_pressed("jump")
			and ($WallRide/Bot/Back.is_colliding() or $WallRide/Bot/Left.is_colliding() or $WallRide/Bot/Right.is_colliding())
			and ($WallRide/Top/Back.is_colliding() or $WallRide/Top/Left.is_colliding() or $WallRide/Top/Right.is_colliding()))
	
	if wallride_stamina < 0:
		is_wallriding = false
		wallride_stamina = 0

	#!Input.is_action_pressed("jump")
	if was_wallriding and !is_wallriding and !is_on_floor():
		var direction = $Head.global_transform.basis.z * (input.y + 5*(-float($WallRide/Top/Back.is_colliding())))
		direction += $Head.global_transform.basis.x * (input.x + 5*(float($WallRide/Top/Left.is_colliding())-float($WallRide/Top/Right.is_colliding())))
		velocity.y = 7
		velocity += direction * tickspeed
		wallride_stamina -= .2
	elif is_on_floor():
		wallride_stamina = (wallride_stamina + 1) / (delta*60*2)

	$Head/WallRideStaminaBar.set_size(Vector2(128 * wallride_stamina, 4))
	$Head/SpeedBar.set_size(Vector2(current_speed*4, 4))
	$Head/SpeedIndicator.set_text(str(round(current_speed*100)/100))

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		tickspeed *= 2

	if is_wallriding:
		var wallriding_dir = float($WallRide/Top/Left.is_colliding())-float($WallRide/Top/Right.is_colliding())
		var direction = $Head.global_transform.basis.z * input.y

		wallride_stamina -= delta

		direction += $Head.global_transform.basis.x * input.x
		direction.y *= current_speed/10

		velocity.y -= gravity * delta
		velocity.y = clamp(velocity.y, -6, 3)

		velocity += direction * tickspeed / 2

		velocity /= friction
		
		$Head.rotation.z -= velocity.dot(transform.basis.x) / 1000
		$Head.rotation.z += wallriding_dir * .02
		$Head.rotation.z /= 1.1
	elif is_on_floor():
		var direction = transform.basis * Vector3(input.x, 0, input.y)

		friction += 2 * .01
		friction /= 1.01

		velocity += direction * tickspeed

		velocity.x /= max(friction / 1.01, 1.5)
		velocity.z /= max(friction / 1.01, 1.5)

		$Head.rotation.z -= velocity.dot(transform.basis.x) / 1000
		$Head.rotation.z /= 1.1
	else:
		var direction = transform.basis * Vector3(input.x, 0, input.y)
		friction += 1.0000001 * .01
		friction = min(friction / 1.01, 1.25)

		velocity += direction * tickspeed / 3

		velocity.y -= gravity * delta

		velocity.x /= friction
		velocity.z /= friction

		$Head.rotation.z -= velocity.dot(transform.basis.x) / 1000
		$Head.rotation.z /= 1.1

	#print(friction)
	#print(int(velocity.length()))

	move_and_slide()

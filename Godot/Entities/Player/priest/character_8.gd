extends CharacterBody2D 

@onready var animated_sprite = $AnimatedSprite2D
@onready var healthbar = $"../UI_manager/HealthBar"
@onready var maker_2d = $Marker2D
@onready var shoot_speed_timer = $shootSpeedTimer
@export var shootSpeed = 1.0

const BULLET = preload("res://Entities/Player/send_attack/throw_damage.tscn")

var speed = 250.0
const jump_power = -300.0
var jump_count = 0
var jump_max = 2
var gravity = 900
var health = 100
var player_alive = true
var enemy_inattack_range = false
var attack_cooldown_stopped = false
var anyMovement = false
var combo = 0
var damage_ = 15
var bulletDirection = Vector2(1, 0)

func _ready():
	shoot_speed_timer.wait_time = 1.0 / shootSpeed
	healthbar.init_health(health)

func _physics_process(delta):
	#is_death()
	var direction = Input.get_axis("left", "right")
	det_dir(direction)
	gravity_and_jump(delta)
	attack()
	player_controller(direction)
	move_and_slide()

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func det_dir(dir):
	if dir != 0:
		bulletDirection = Vector2(dir, 0)
		animated_sprite.flip_h = dir == -1

func gravity_and_jump(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		jump_count = 0

func player_controller(dir):
	if dir:
		velocity.x = dir * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	if !anyMovement:
		if is_on_floor():
			speed = 250
			if velocity.x == 0:
				animated_sprite.play("idle")
			else:
				animated_sprite.play("run")
				det_dir(dir)
		else:
			speed = 100

	if Input.is_action_just_pressed("up") and jump_count < jump_max:
		speed = 100
		velocity.y = jump_power
		jump_count += 1 

func attack():
	if Input.is_action_just_pressed("attack") and !anyMovement:
		anyMovement = true
		speed = 20
		
		if $AttackTimer.is_stopped():
			$AttackTimer.start()
			await wait_for_animation("attack_1", 0.7)
			combo
			shoot()
			
		anyMovement = false

func wait_for_animation(anim: String, duration: float) -> void:
	animated_sprite.play(anim)
	await get_tree().create_timer(duration).timeout
	
func player():
	pass

func take_damage(damage_amount):
	health -= damage_amount
	anyMovement = true
	await wait_for_animation("damaged", 0.8)
	is_death()
	anyMovement = false

func shoot():
	var Bullet_node = BULLET.instantiate()
	Bullet_node.set_direction(bulletDirection, self , damage_)
	get_tree().root.add_child(Bullet_node)
	Bullet_node.global_position = maker_2d.global_position


func is_death():
	if health <= 0:
		player_alive = false
		health = 0
		await wait_for_animation("death", 0.8)
		self.queue_free()
	else:
		healthbar.health = health


extends EnemyEntity

@onready var player : Node = get_tree().get_first_node_in_group("player")
@export var nav: NavigationAgent2D
@export var hitbox_shape : Shape2D
var hurtbox : HurtBox

var player_in_range : bool = false
@export var speed : float = 100.0

enum State { ARISING, IDLE, MOVING, ATTACKING, DAMAGED, DYING }
var state : State = State.IDLE
signal state_changed


func set_state(new_state : State) -> void:
	state = new_state
	state_changed.emit()
	
	match state:
		State.ARISING:
			velocity = Vector2.ZERO
			sprite_base.play("arise")
			
		State.IDLE:
			hurtbox.set_deferred("monitorable", false)
			velocity = Vector2.ZERO
			sprite_base.play("idle")
			
			await get_tree().create_timer(1.8).timeout
			reduce_to_gold()
		
		State.MOVING:
			handle_move()

		State.ATTACKING:
			handle_attack()

		State.DAMAGED:
			velocity = Vector2.ZERO
			sprite_base.play("damage")

		State.DYING:
			velocity = Vector2.ZERO
			sprite_base.play("death")

func _ready() -> void:
	super._ready()
	
	hurtbox = get_node("AnimatedSprite2D/hurtBox")
	set_state(State.ARISING)

func _physics_process(delta: float) -> void:
	if !is_instance_valid(player) and state != State.IDLE:
		set_state(State.IDLE)
		
	match state:
		State.ARISING:
			return
			
		State.IDLE:
			return
		
		State.MOVING:
			if player_in_range:
				set_state(State.ATTACKING)
			handle_follow()

		State.ATTACKING:
			handle_follow()

		State.DAMAGED:
			pass

		State.DYING:
			pass

func handle_follow() -> void:
	nav.target_position = player.global_position	
	var next : Vector2 = nav.get_next_path_position()
	velocity = global_position.direction_to(next) * speed	
	if velocity.x > 0:
		sprite_base.flip_h = false
	elif velocity.x < 0:
		sprite_base.flip_h = true
	move_and_slide()

func handle_move() -> void:	
	sprite_base.play("move")
	
func handle_attack() -> void:
	var hitbox = hitBox.new(self, damage, "None", 0.1, hitbox_shape)
	
	hitbox.scale = Vector2(1.4,1.4);
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)
	
	var vector_to_player : Vector2 = player.global_position - global_position
	hitbox.rotation = vector_to_player.angle()
	hitbox.position = vector_to_player.normalized() * 20
	
	if vector_to_player.y < 0:
		sprite_base.play("attack_up")
	else:
		sprite_base.play("attack_down")

func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		print("player is in range")

func _on_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		print("player is no longer in range")
		
	
func _on_damaged(_amount, _type) -> void:
	super._on_damaged(_amount, _type)
	set_state(State.DAMAGED)

func _on_death() -> void:
	hurtbox.set_deferred("monitorable", false)
	set_state(State.DYING)
	

func _on_boss_death() -> void:
	hurtbox.set_deferred("monitorable", false)
	set_state(State.IDLE)
	fade_out(0.8)

func fade_out(duration: float) -> void:
	var tween : Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(reduce_to_gold)
	

func _on_animated_sprite_2d_animation_finished() -> void:
	match sprite_base.animation:
		"arise": set_state(State.MOVING)
		"damage": set_state(State.MOVING)
		"death": reduce_to_gold()
		"attack_up", "attack_down":
			set_state(State.MOVING)
			print("enemy finished attack")

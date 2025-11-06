extends Node
@export var max_hp = 100
@export var initial_hp = 100
@export var invincible = false
@export var invincible_time = 1.0

var hp = 0

var _invincible_timer : Timer

signal on_damage(amount : int)
signal on_death()
signal on_heal(amount : int)

func _ready():
	hp = initial_hp
	_init_invincibility_timer()

func damage(damage : int):
	if invincible:
		return

	hp -= damage
	on_damage.emit(damage)
	if hp <= 0:
		on_death.emit()

func heal(amount : int):
	hp = min(hp + amount, max_hp)
	on_heal.emit(amount)

func set_invincibility(time : float = invincible_time):
	invincible = true
	invincible_time = time
	_invincible_timer.start()

func disable_invincibility():
	invincible = false
	_invincible_timer.stop()



func _init_invincibility_timer():
	_invincible_timer = Timer.new()
	_invincible_timer.set_wait_time(invincible_time)
	_invincible_timer.one_shot = true
	_invincible_timer.timeout.connect(disable_invincibility)
	add_child(_invincible_timer)
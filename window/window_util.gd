class_name WindowUtil
extends Node

enum Quarter {
	TOPLEFT, TOPRIGHT, BOTLEFT, BOTRIGHT
}

static var QUARTER_TOPLEFT = Quarter.TOPLEFT
static var QUARTER_TOPRIGHT = Quarter.TOPRIGHT
static var QUARTER_BOTLEFT = Quarter.BOTLEFT
static var QUARTER_BOTRIGHT = Quarter.BOTRIGHT

static func dock_window_to_quarter(quarter: Quarter, window: Window):
	var usable_rect = DisplayServer.screen_get_usable_rect()
	var quarter_size = usable_rect.size / 2
	var decoration_size = window.get_size_with_decorations() - window.size
	usable_rect.position += decoration_size
	window.size = quarter_size - decoration_size
	
	match quarter:
		Quarter.TOPLEFT:
			window.position = usable_rect.position
		Quarter.TOPRIGHT:
			window.position = usable_rect.position + Vector2i(quarter_size.x, 0)
		Quarter.BOTLEFT:
			window.position = usable_rect.position + Vector2i(0, quarter_size.y)
		Quarter.BOTRIGHT:
			window.position = usable_rect.position + quarter_size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

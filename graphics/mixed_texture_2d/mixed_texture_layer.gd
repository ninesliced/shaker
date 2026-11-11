@tool
class_name MixedTextureLayer2D
extends Resource
## A single layer of a [MixedTexture2D]: a texture plus how it is placed and blended.

enum BlendMode { NORMAL, MULTIPLY, ADD, SUBTRACT, SCREEN, OVERLAY, DARKEN, LIGHTEN, DIFFERENCE }
enum WrapMode { REPEAT, CLAMP, MIRROR }

@export var texture: Texture2D:
	set(v):
		# Forward the source's `changed` signal so async textures (e.g.
		# NoiseTexture2D) trigger a rebake once their image is ready.
		if texture and texture.changed.is_connected(emit_changed):
			texture.changed.disconnect(emit_changed)
		texture = v
		if texture and not texture.changed.is_connected(emit_changed):
			texture.changed.connect(emit_changed)
		emit_changed()
@export var blend_mode: BlendMode = BlendMode.NORMAL:
	set(v):
		blend_mode = v
		emit_changed()
@export_range(0.0, 1.0) var opacity := 1.0:
	set(v):
		opacity = v
		emit_changed()
@export var enabled := true:
	set(v):
		enabled = v
		emit_changed()
@export var scale := Vector2.ONE:
	set(v):
		scale = v
		emit_changed()
@export var offset := Vector2i.ZERO:
	set(v):
		offset = v
		emit_changed()
@export var wrap_mode: WrapMode = WrapMode.REPEAT:
	set(v):
		wrap_mode = v
		emit_changed()

@tool
@icon("res://addons/godot-mixed-texture-2d/icon.svg")
class_name MixedTexture2D
extends Texture2D
## A [Texture2D] baked from an array of [MixedTextureLayer2D]s composited bottom-to-top.
## Each layer is scaled, wrapped and blended into an output image of [member size].

## How the output alpha is produced. [code]KEEP[/code] uses the composited alpha.
## [code]PREMULTIPLIED[/code] treats the baked RGB as premultiplied alpha.
enum AlphaMode { KEEP, PREMULTIPLIED }

@export var alpha_mode := AlphaMode.KEEP:
	set(v):
		alpha_mode = v
		_queue_rebake()
@export var size := Vector2i(256, 256):
	set(v):
		size = Vector2i(maxi(1, v.x), maxi(1, v.y))
		_queue_rebake()
@export var layers: Array[MixedTextureLayer2D] = []:
	set(v):
		for l in layers:
			if l and l.changed.is_connected(_queue_rebake):
				l.changed.disconnect(_queue_rebake)
		layers = v
		for l in layers:
			if l and not l.changed.is_connected(_queue_rebake):
				l.changed.connect(_queue_rebake)
		_queue_rebake()

var _tex: ImageTexture
var _scheduled := false
var _baking := false
var _again := false
var _task_id := -1


# Block destruction until an in-flight worker task finishes, so it never
# dereferences this resource after it has been freed.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _task_id != -1:
		WorkerThreadPool.wait_for_task_completion(_task_id)


# Baking runs on a worker thread (like NoiseTexture2D) so editing parameters
# never stalls the main thread. Rapid changes are coalesced into one rebake.
func _queue_rebake() -> void:
	if _baking:
		_again = true
		return
	if _scheduled:
		return
	_scheduled = true
	_start_bake.call_deferred()


func _start_bake() -> void:
	_scheduled = false
	_baking = true
	# Snapshot everything the worker reads (size, jobs, alpha_mode) and pass it in;
	# the worker must not read live members that the main thread may change.
	_task_id = WorkerThreadPool.add_task(_bake.bind(size, _collect_jobs(), alpha_mode))


# Snapshot the layers' source images on the main thread; textures must not be
# read from the worker thread. Each job is [image, blend_mode, opacity, scale, offset, wrap].
func _collect_jobs() -> Array:
	var jobs: Array = []
	for layer in layers:
		if layer == null or not layer.enabled or layer.texture == null:
			continue
		var src := layer.texture.get_image()
		if src == null or src.is_empty():
			continue
		# get_pixel() can't read compressed formats (imported PNGs, etc.).
		if src.is_compressed():
			src = src.duplicate()
			src.decompress()
		jobs.append([src, layer.blend_mode, layer.opacity, layer.scale, layer.offset, layer.wrap_mode])
	return jobs


func _bake(sz: Vector2i, jobs: Array, amode: AlphaMode) -> void:
	var img := Image.create_empty(sz.x, sz.y, false, Image.FORMAT_RGBA8)
	for j in jobs:
		_composite(img, sz, j[0], j[1], j[2], j[3], j[4], j[5])
	_apply_alpha_mode(img, amode)
	_apply.call_deferred(img)


# Treat the composite as premultiplied alpha: recover coverage (the brightest
# channel) as alpha, then un-premultiply the color back to straight alpha.
func _apply_alpha_mode(img: Image, amode: AlphaMode) -> void:
	if amode == AlphaMode.KEEP:
		return
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var a := maxf(c.r, maxf(c.g, c.b))
			if a > 0.0:
				img.set_pixel(x, y, Color(c.r / a, c.g / a, c.b / a, a))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))


# Runs back on the main thread: touching ImageTexture / RenderingServer must not
# happen from the worker thread.
func _apply(img: Image) -> void:
	if _task_id != -1:
		WorkerThreadPool.wait_for_task_completion(_task_id)
		_task_id = -1
	if _tex == null:
		_tex = ImageTexture.create_from_image(img)
	else:
		_tex.set_image(img)
	_baking = false
	emit_changed()
	if _again:
		_again = false
		_queue_rebake()


func _composite(dst: Image, sz: Vector2i, src: Image, mode: int, opacity: float, scale: Vector2, offset: Vector2i, wrap_mode: int) -> void:
	if scale.x == 0.0 or scale.y == 0.0:
		return
	var sw := src.get_width()
	var sh := src.get_height()
	for y in sz.y:
		var v := _wrap(int(floor((y - offset.y) / scale.y)), sh, wrap_mode)
		if v < 0:
			continue
		for x in sz.x:
			var u := _wrap(int(floor((x - offset.x) / scale.x)), sw, wrap_mode)
			if u < 0:
				continue
			var s := src.get_pixel(u, v)
			s.a *= opacity
			dst.set_pixel(x, y, _blend(dst.get_pixel(x, y), s, mode))


func _wrap(i: int, n: int, mode: int) -> int:
	if n <= 0:
		return -1
	match mode:
		MixedTextureLayer2D.WrapMode.REPEAT:
			return posmod(i, n)
		MixedTextureLayer2D.WrapMode.MIRROR:
			var p := posmod(i, n * 2)
			return p if p < n else n * 2 - 1 - p
		_:  # CLAMP
			return clampi(i, 0, n - 1)


func _blend(d: Color, s: Color, mode: int) -> Color:
	var b := s
	match mode:
		MixedTextureLayer2D.BlendMode.MULTIPLY:
			b = Color(d.r * s.r, d.g * s.g, d.b * s.b, s.a)
		MixedTextureLayer2D.BlendMode.ADD:
			b = Color(d.r + s.r, d.g + s.g, d.b + s.b, s.a)
		MixedTextureLayer2D.BlendMode.SUBTRACT:
			b = Color(d.r - s.r, d.g - s.g, d.b - s.b, s.a)
		MixedTextureLayer2D.BlendMode.SCREEN:
			b = Color(1.0 - (1.0 - d.r) * (1.0 - s.r), 1.0 - (1.0 - d.g) * (1.0 - s.g), 1.0 - (1.0 - d.b) * (1.0 - s.b), s.a)
		MixedTextureLayer2D.BlendMode.OVERLAY:
			b = Color(_overlay(d.r, s.r), _overlay(d.g, s.g), _overlay(d.b, s.b), s.a)
		MixedTextureLayer2D.BlendMode.DARKEN:
			b = Color(minf(d.r, s.r), minf(d.g, s.g), minf(d.b, s.b), s.a)
		MixedTextureLayer2D.BlendMode.LIGHTEN:
			b = Color(maxf(d.r, s.r), maxf(d.g, s.g), maxf(d.b, s.b), s.a)
		MixedTextureLayer2D.BlendMode.DIFFERENCE:
			b = Color(absf(d.r - s.r), absf(d.g - s.g), absf(d.b - s.b), s.a)
	# Alpha-composite the blended color "over" the accumulator.
	var a := b.a
	return Color(
		b.r * a + d.r * (1.0 - a),
		b.g * a + d.g * (1.0 - a),
		b.b * a + d.b * (1.0 - a),
		a + d.a * (1.0 - a),
	).clamp()


func _overlay(d: float, s: float) -> float:
	return 2.0 * d * s if d < 0.5 else 1.0 - 2.0 * (1.0 - d) * (1.0 - s)


# Texture2D plumbing: the rendering server uses our RID, so drawing,
# materials and export all "just work" once we point them at the baked image.

func _get_width() -> int:
	return size.x


func _get_height() -> int:
	return size.y


func _has_alpha() -> bool:
	return true


func _get_rid() -> RID:
	_ensure_baked()
	return _tex.get_rid() if _tex else RID()


func _get_image() -> Image:
	_ensure_baked()
	return _tex.get_image() if _tex else null


# Synchronous fallback for when the texture is queried before the threaded bake
# has produced a result (first load, export, get_image() from code).
func _ensure_baked() -> void:
	if _tex != null:
		return
	var img := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	for j in _collect_jobs():
		_composite(img, size, j[0], j[1], j[2], j[3], j[4], j[5])
	_apply_alpha_mode(img, alpha_mode)
	_tex = ImageTexture.create_from_image(img)

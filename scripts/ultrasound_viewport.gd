class_name UltrasoundViewport
extends Control

enum TransducerType { CONVEX, PHASED, LINEAR, ENDO }
enum ScanMode { B_MODE, COLOR_DOPPLER, PW_DOPPLER, M_MODE }
enum CaliperType { DISTANCE, ANGLE, HEART_RATE, OB_METRICS }
enum DragState { NONE, MOVE_COLOR_BOX, RESIZE_TL, RESIZE_TR, RESIZE_BL, RESIZE_BR, DRAG_ANNOTATION }

@export var transducer: TransducerType = TransducerType.CONVEX
@export var mode: ScanMode = ScanMode.B_MODE
@export var is_frozen: bool = false
@export var gain: float = 1.0 # 0.2 to 2.0
@export var depth_cm: float = 8.9 # 4.0 to 24.0 cm
@export var show_centerline: bool = true
@export var show_focus: bool = true
@export var active_preset: String = "Abdominal"
@export var flip_horizontal: bool = false

# TGC 6-band controls (0.2 to 1.8)
var tgc_bands: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

# Cine loop frame buffer
var cine_frames: Array[float] = []
var cine_max_frames: int = 60
var cine_index: int = 59

# Caliper & Measurement
var active_caliper_type: CaliperType = CaliperType.DISTANCE
var caliper_points: Array[Vector2] = []
var is_placing_caliper: bool = false
var measurements_list: Array[Dictionary] = []

# Annotations
var annotations_list: Array[Dictionary] = []
var active_annotation_label: String = ""
var selected_annotation_idx: int = -1

# Interactive Color Doppler ROI Box
var color_box_rect: Rect2 = Rect2(Vector2(200, 140), Vector2(180, 140))
var handle_radius: float = 14.0
var active_drag_state: DragState = DragState.NONE
var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var drag_start_box_rect: Rect2 = Rect2()
var is_roi_initialized: bool = false

# Internal simulation variables
var time_passed: float = 0.0
var noise: FastNoiseLite

# Spectral & M-Mode buffers
var pw_spectral_history: Array[float] = []
var m_mode_history: Array[Array] = []
var max_history_pts: int = 200

func _ready() -> void:
	noise = FastNoiseLite.new()
	noise.seed = 54321
	noise.frequency = 0.04
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	for i in range(max_history_pts):
		pw_spectral_history.append(_generate_pw_sample(float(i) * 0.05))
		m_mode_history.append(_generate_m_sample(float(i) * 0.05))

func _process(delta: float) -> void:
	if not is_frozen:
		time_passed += delta * 3.0
		
		cine_frames.append(time_passed)
		if cine_frames.size() > cine_max_frames:
			cine_frames.pop_front()
		cine_index = cine_frames.size() - 1
		
		pw_spectral_history.append(_generate_pw_sample(time_passed))
		if pw_spectral_history.size() > max_history_pts:
			pw_spectral_history.pop_front()
			
		m_mode_history.append(_generate_m_sample(time_passed))
		if m_mode_history.size() > max_history_pts:
			m_mode_history.pop_front()
			
		queue_redraw()

func _ensure_roi_centered() -> void:
	var rect = get_rect()
	if rect.size.x > 0 and not is_roi_initialized:
		var center_x = rect.size.x * 0.5
		var center_y = 60.0 + (rect.size.y - 130.0) * 0.45
		color_box_rect = Rect2(Vector2(center_x - 90, center_y - 70), Vector2(180, 140))
		is_roi_initialized = true

func _generate_pw_sample(t: float) -> float:
	var period = fmod(t * 1.2, 1.0)
	if period < 0.25:
		return sin(period / 0.25 * PI) * 88.0 + randf() * 4.0
	elif period < 0.45:
		return (1.0 - (period - 0.25) / 0.2) * 45.0 + 20.0 + randf() * 4.0
	else:
		return 22.0 + sin((period - 0.45) * 4.0) * 4.0 + randf() * 3.0

func _generate_m_sample(t: float) -> Array[float]:
	var line: Array[float] = []
	var pts = 45
	for i in range(pts):
		var base_y = float(i) / float(pts)
		var val = noise.get_noise_2d(base_y * 100.0, t * 10.0)
		if i > 12 and i < 26:
			val += (sin(t * 5.0 + float(i)) * 0.45 + 0.5)
		line.append(val)
	return line

func _gui_input(event: InputEvent) -> void:
	_ensure_roi_centered()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mpos = event.position
			
			if mode == ScanMode.COLOR_DOPPLER and not is_frozen:
				var vertices = _get_roi_vertices()
				var tl = vertices[0]
				var tr = vertices[1]
				var br = vertices[2]
				var bl = vertices[3]
				
				if mpos.distance_to(tl) <= handle_radius:
					active_drag_state = DragState.RESIZE_TL
				elif mpos.distance_to(tr) <= handle_radius:
					active_drag_state = DragState.RESIZE_TR
				elif mpos.distance_to(bl) <= handle_radius:
					active_drag_state = DragState.RESIZE_BL
				elif mpos.distance_to(br) <= handle_radius:
					active_drag_state = DragState.RESIZE_BR
				elif color_box_rect.has_point(mpos):
					active_drag_state = DragState.MOVE_COLOR_BOX
				else:
					active_drag_state = DragState.NONE
					
				if active_drag_state != DragState.NONE:
					drag_start_mouse_pos = mpos
					drag_start_box_rect = color_box_rect
					queue_redraw()
					return
					
			if is_frozen:
				selected_annotation_idx = -1
				for idx in range(annotations_list.size()):
					var ann = annotations_list[idx]
					var ann_pos: Vector2 = ann["pos"]
					var ann_rect = Rect2(ann_pos + Vector2(-10, -20), Vector2(ann["text"].length() * 12 + 20, 30))
					if ann_rect.has_point(mpos):
						selected_annotation_idx = idx
						active_drag_state = DragState.DRAG_ANNOTATION
						drag_start_mouse_pos = mpos
						queue_redraw()
						return
						
				if active_annotation_label != "":
					annotations_list.append({
						"pos": mpos,
						"text": active_annotation_label
					})
					active_annotation_label = ""
					queue_redraw()
					return
					
				if not is_placing_caliper:
					caliper_points.clear()
					caliper_points.append(mpos)
					caliper_points.append(mpos)
					is_placing_caliper = true
				else:
					caliper_points[1] = mpos
					is_placing_caliper = false
					_finalize_measurement()
					queue_redraw()
		else:
			active_drag_state = DragState.NONE
			if is_placing_caliper and caliper_points.size() >= 2:
				caliper_points[1] = event.position
				is_placing_caliper = false
				_finalize_measurement()
				queue_redraw()
				
	elif event is InputEventMouseMotion:
		var mpos = event.position
		if active_drag_state == DragState.MOVE_COLOR_BOX:
			var delta = mpos - drag_start_mouse_pos
			color_box_rect.position = drag_start_box_rect.position + delta
			queue_redraw()
		elif active_drag_state == DragState.RESIZE_BR:
			var delta = mpos - drag_start_mouse_pos
			var new_w = max(60.0, drag_start_box_rect.size.x + delta.x)
			var new_h = max(60.0, drag_start_box_rect.size.y + delta.y)
			color_box_rect.size = Vector2(new_w, new_h)
			queue_redraw()
		elif active_drag_state == DragState.RESIZE_TL:
			var delta = mpos - drag_start_mouse_pos
			var new_w = max(60.0, drag_start_box_rect.size.x - delta.x)
			var new_h = max(60.0, drag_start_box_rect.size.y - delta.y)
			color_box_rect.position = drag_start_box_rect.position + (drag_start_box_rect.size - Vector2(new_w, new_h))
			color_box_rect.size = Vector2(new_w, new_h)
			queue_redraw()
		elif active_drag_state == DragState.DRAG_ANNOTATION and selected_annotation_idx >= 0 and selected_annotation_idx < annotations_list.size():
			annotations_list[selected_annotation_idx]["pos"] = mpos
			queue_redraw()
		elif is_placing_caliper and caliper_points.size() >= 2:
			caliper_points[1] = mpos
			queue_redraw()

func _get_roi_vertices() -> PackedVector2Array:
	return PackedVector2Array([
		color_box_rect.position,
		color_box_rect.position + Vector2(color_box_rect.size.x, 0),
		color_box_rect.position + color_box_rect.size,
		color_box_rect.position + Vector2(0, color_box_rect.size.y)
	])

func _finalize_measurement() -> void:
	if caliper_points.size() < 2:
		return
	var p1 = caliper_points[0]
	var p2 = caliper_points[1]
	var px_dist = p1.distance_to(p2)
	var scan_height = get_rect().size.y * 0.7
	var cm_dist = (px_dist / scan_height) * depth_cm
	
	var label = ""
	match active_caliper_type:
		CaliperType.DISTANCE:
			label = "D" + str(measurements_list.size() + 1) + ": " + str(snapped(cm_dist, 0.01)) + " cm"
		CaliperType.ANGLE:
			label = "Ang: " + str(snapped(randf_range(35.0, 75.0), 0.1)) + "°"
		CaliperType.HEART_RATE:
			var bpm = int(clamp(60.0 / (cm_dist * 0.15 + 0.4), 48, 175))
			label = "HR: " + str(bpm) + " BPM"
		CaliperType.OB_METRICS:
			var ga_weeks = snapped(cm_dist * 1.8 + 4.0, 0.1)
			label = "BPD: " + str(snapped(cm_dist, 0.01)) + "cm (" + str(ga_weeks) + "w)"
			
	measurements_list.append({
		"p1": p1,
		"p2": p2,
		"text": label
	})

func clear_calipers() -> void:
	caliper_points.clear()
	measurements_list.clear()
	is_placing_caliper = false
	queue_redraw()

func clear_annotations() -> void:
	annotations_list.clear()
	selected_annotation_idx = -1
	queue_redraw()

func _draw() -> void:
	_ensure_roi_centered()
	var rect = get_rect()
	draw_rect(Rect2(Vector2.ZERO, rect.size), Color(0.0, 0.0, 0.0))
	
	var cur_time = cine_frames[cine_index] if (is_frozen and cine_frames.size() > 0) else time_passed
	
	match mode:
		ScanMode.B_MODE:
			_draw_b_mode(rect, cur_time)
		ScanMode.COLOR_DOPPLER:
			_draw_b_mode(rect, cur_time)
			_draw_color_doppler_overlay(rect, cur_time)
		ScanMode.PW_DOPPLER:
			_draw_split_pw_mode(rect, cur_time)
		ScanMode.M_MODE:
			_draw_split_m_mode(rect, cur_time)
			
	_draw_depth_ruler(rect)
	_draw_left_2d_parameter_block()
	_draw_overlays(rect)
	
	if is_frozen:
		_draw_calipers_and_annotations()

func _draw_b_mode(rect: Rect2, t: float) -> void:
	var center_x = rect.size.x * 0.5
	var top_y = 60.0
	var scan_h = rect.size.y - 130.0
	
	match transducer:
		TransducerType.CONVEX:
			_draw_convex_b_mode(center_x, top_y, scan_h, rect.size, t)
		TransducerType.PHASED:
			_draw_phased_b_mode(center_x, top_y, scan_h, rect.size, t)
		TransducerType.LINEAR:
			_draw_linear_b_mode(center_x, top_y, scan_h, rect.size, t)
		TransducerType.ENDO:
			_draw_endo_b_mode(center_x, top_y, scan_h, rect.size, t)

func _draw_convex_b_mode(center_x: float, top_y: float, scan_h: float, view_size: Vector2, t: float) -> void:
	# Convex Sector Fan Arc (Curved top & bottom)
	var angle_span = 64.0
	var top_r = 75.0
	var bottom_r = top_r + scan_h * 0.95
	var apex_center = Vector2(center_x, top_y - top_r)
	
	var points = PackedVector2Array()
	var steps = 36
	for i in range(steps + 1):
		var frac = 1.0 - float(i) / float(steps)
		var a = deg_to_rad(-angle_span * 0.5 + angle_span * frac + 90.0)
		points.append(apex_center + Vector2(cos(a), sin(a)) * bottom_r)
	for i in range(steps + 1):
		var frac = float(i) / float(steps)
		var a = deg_to_rad(-angle_span * 0.5 + angle_span * frac + 90.0)
		points.append(apex_center + Vector2(cos(a), sin(a)) * top_r)
		
	draw_polygon(points, PackedColorArray([Color(0.06, 0.08, 0.1, 0.96)]))
	_draw_convex_speckle(apex_center, top_r, bottom_r, angle_span, t)

func _draw_dotted_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var steps = 60
	for i in range(steps):
		if i % 2 == 0:
			var a1 = deg_to_rad((float(i) / float(steps)) * 360.0)
			var a2 = deg_to_rad((float(i + 1) / float(steps)) * 360.0)
			var p1 = center + Vector2(cos(a1) * rx, sin(a1) * ry)
			var p2 = center + Vector2(cos(a2) * rx, sin(a2) * ry)
			draw_line(p1, p2, color, 2.0)

func _draw_caliper_crosshair(pos: Vector2, color: Color) -> void:
	draw_rect(Rect2(pos - Vector2(5, 5), Vector2(10, 10)), color, false, 1.5)
	draw_line(pos - Vector2(7, 0), pos + Vector2(7, 0), color, 2.0)
	draw_line(pos - Vector2(0, 7), pos + Vector2(0, 7), color, 2.0)

func _draw_phased_b_mode(center_x: float, top_y: float, scan_h: float, view_size: Vector2, t: float) -> void:
	var angle_span = 80.0
	var radius = scan_h
	var apex = Vector2(center_x, top_y + 5)
	var points = PackedVector2Array([apex])
	var steps = 36
	for i in range(steps + 1):
		var a = deg_to_rad(-angle_span * 0.5 + angle_span * (float(i)/float(steps)) + 90.0)
		points.append(apex + Vector2(cos(a), sin(a)) * radius)
	draw_polygon(points, PackedColorArray([Color(0.05, 0.08, 0.11, 0.95)]))
	
	_draw_cone_speckle(center_x, top_y + 5, radius, angle_span, t)

func _draw_linear_b_mode(center_x: float, top_y: float, scan_h: float, view_size: Vector2, t: float) -> void:
	var width = view_size.x * 0.72
	var left_x = center_x - width * 0.5
	var beam_rect = Rect2(Vector2(left_x, top_y), Vector2(width, scan_h))
	draw_rect(beam_rect, Color(0.06, 0.09, 0.11, 0.95))
	
	_draw_speckle_field(left_x, top_y, width, scan_h, t)

func _draw_endo_b_mode(center_x: float, top_y: float, scan_h: float, view_size: Vector2, t: float) -> void:
	var angle_span = 160.0
	var radius = scan_h * 0.95
	var apex = Vector2(center_x, top_y + 10)
	var points = PackedVector2Array([apex])
	var steps = 48
	for i in range(steps + 1):
		var a = deg_to_rad(-angle_span * 0.5 + angle_span * (float(i)/float(steps)) + 90.0)
		points.append(apex + Vector2(cos(a), sin(a)) * radius)
	draw_polygon(points, PackedColorArray([Color(0.06, 0.09, 0.11, 0.95)]))
	
	_draw_cone_speckle(center_x, top_y + 10, radius, angle_span, t)

func _draw_left_2d_parameter_block() -> void:
	# 2D Scan Parameters overlay on left top (Matching image 139645_66778_4746.jpg)
	var font = ThemeDB.fallback_font
	var start_pos = Vector2(16, 80)
	var text_col = Color(0.9, 0.92, 0.95)
	var blue_col = Color(0.2, 0.65, 0.95)
	
	draw_string(font, start_pos, "[2D]", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, text_col)
	draw_string(font, start_pos + Vector2(0, 18), "Frq  Gen.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, text_col)
	draw_string(font, start_pos + Vector2(0, 34), "GN   47", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, text_col)
	draw_string(font, start_pos + Vector2(0, 50), "DR   46", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, text_col)
	draw_string(font, start_pos + Vector2(0, 66), "FA   7", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, text_col)
	draw_string(font, start_pos + Vector2(0, 82), "P    90", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, text_col)
	draw_string(font, start_pos + Vector2(0, 98), "PG  -3", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, blue_col)
	draw_string(font, start_pos + Vector2(0, 114), "PD  -4", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, blue_col)

func _draw_right_bottom_ob_report_box(rect: Rect2) -> void:
	# OB Measurement Table overlay on bottom right (Matching image 139645_66778_4746.jpg)
	var font = ThemeDB.fallback_font
	var box_w = 210.0
	var box_h = 240.0
	var box_pos = Vector2(rect.size.x - box_w - 20, rect.size.y - box_h - 110)
	
	draw_rect(Rect2(box_pos, Vector2(box_w, box_h)), Color(0.0, 0.0, 0.0, 0.75), true)
	draw_rect(Rect2(box_pos, Vector2(box_w, box_h)), Color(0.3, 0.35, 0.4, 0.6), false, 1.0)
	
	var key_col = Color(0.95, 0.85, 0.15)
	var val_col = Color(1.0, 1.0, 1.0)
	
	var rows = [
		["BPD", "5.20 cm"],
		["GA", "21w5d ± 12d"],
		["EDD", "09-09-2021"],
		["EFW1", "419g"],
		["GA", "21w2d"],
		["EDD", "09-12-2021"],
		["FL/BPD", "65.95 %"],
		["HC", "18.83 cm"],
		["GA", "21w1d ± 10d"],
		["EDD", "09-13-2021"],
		["HC/AC", "1.13"],
		["FL/HC", "18.20 %"]
	]
	
	for i in range(rows.size()):
		var ry = box_pos.y + 18 + i * 19
		var k = rows[i][0]
		var v = rows[i][1]
		draw_string(font, Vector2(box_pos.x + 10, ry), k, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, key_col)
		draw_string(font, Vector2(box_pos.x + box_w - 10, ry), v, HORIZONTAL_ALIGNMENT_RIGHT, -1, 12, val_col)

func _draw_convex_speckle(apex: Vector2, top_r: float, bottom_r: float, angle_span: float, t: float) -> void:
	for i in range(200):
		var r = top_r + randf() * (bottom_r - top_r)
		var frac = randf()
		var a = deg_to_rad(-angle_span * 0.5 + angle_span * frac + 90.0)
		var pt = apex + Vector2(cos(a), sin(a)) * r
		
		var zone = clamp(int(((r - top_r) / (bottom_r - top_r)) * 6.0), 0, 5)
		var zone_gain = tgc_bands[zone]
		
		var n_val = noise.get_noise_2d(pt.x * 2.0 + t * 5.0, pt.y * 2.0)
		if n_val > 0.02:
			var alpha = clamp((n_val * gain * zone_gain) * 0.75, 0.0, 0.9)
			draw_circle(pt, 1.2 + n_val * 2.5, Color(0.75, 0.85, 0.85, alpha))

func _draw_speckle_field(left_x: float, top_y: float, width: float, height: float, t: float) -> void:
	for i in range(180):
		var rx = left_x + randf() * width
		var ry = top_y + randf() * height
		var zone = clamp(int(((ry - top_y) / height) * 6.0), 0, 5)
		var zone_gain = tgc_bands[zone]
		
		var n_val = noise.get_noise_2d(rx * 2.0 + t * 5.0, ry * 2.0)
		if n_val > 0.02:
			var alpha = clamp((n_val * gain * zone_gain) * 0.75, 0.0, 0.9)
			draw_circle(Vector2(rx, ry), 1.2 + n_val * 2.5, Color(0.75, 0.85, 0.85, alpha))

func _draw_cone_speckle(center_x: float, top_y: float, radius: float, angle_span: float, t: float) -> void:
	var apex = Vector2(center_x, top_y)
	for i in range(200):
		var r = randf() * radius
		var frac = randf()
		var a = deg_to_rad(-angle_span * 0.5 + angle_span * frac + 90.0)
		var pt = apex + Vector2(cos(a), sin(a)) * r
		
		var zone = clamp(int((r / radius) * 6.0), 0, 5)
		var zone_gain = tgc_bands[zone]
		
		var n_val = noise.get_noise_2d(pt.x * 2.0 + t * 5.0, pt.y * 2.0)
		if n_val > 0.02:
			var alpha = clamp((n_val * gain * zone_gain) * 0.75, 0.0, 0.9)
			draw_circle(pt, 1.2 + n_val * 2.5, Color(0.75, 0.85, 0.85, alpha))

func _draw_color_doppler_overlay(rect: Rect2, t: float) -> void:
	var vertices = _get_roi_vertices()
	draw_rect(color_box_rect, Color(0.95, 0.65, 0.1, 0.85), false, 2.5)
		
	var handle_col = Color(0.95, 0.85, 0.15, 0.95)
	for v in vertices:
		draw_circle(v, 8.0, handle_col)
		
	for i in range(40):
		var fx = color_box_rect.position.x + randf() * color_box_rect.size.x
		var fy = color_box_rect.position.y + randf() * color_box_rect.size.y
		var pt = Vector2(fx, fy)
		
		if Geometry2D.is_point_in_polygon(pt, vertices):
			var flow = sin(t * 5.0 + fy * 0.08)
			var col = Color(0.95, 0.25, 0.15, 0.8) if flow > 0 else Color(0.15, 0.55, 0.95, 0.8)
			draw_circle(pt, 3.2, col)
			
	var bar_x = rect.size.x - 60.0
	var bar_y = 80.0
	var bar_h = 140.0
	draw_rect(Rect2(Vector2(bar_x, bar_y), Vector2(16, bar_h * 0.5)), Color(0.95, 0.25, 0.15))
	draw_rect(Rect2(Vector2(bar_x, bar_y + bar_h * 0.5), Vector2(16, bar_h * 0.5)), Color(0.15, 0.55, 0.95))
	
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(bar_x - 36, bar_y + 12), "+60", HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, Color(0.95, 0.3, 0.2))
	draw_string(font, Vector2(bar_x - 36, bar_y + bar_h), "-60", HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, Color(0.2, 0.6, 0.95))
	draw_string(font, Vector2(bar_x - 42, bar_y + bar_h * 0.5 + 4), "cm/s", HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, Color.WHITE)

func _draw_split_pw_mode(rect: Rect2, t: float) -> void:
	var split_y = rect.size.y * 0.42
	
	var top_rect = Rect2(Vector2.ZERO, Vector2(rect.size.x, split_y))
	_draw_b_mode(top_rect, t)
	
	var center_x = rect.size.x * 0.5
	draw_dashed_line(Vector2(center_x, 60), Vector2(center_x, split_y - 10), Color(0.9, 0.8, 0.1, 0.7), 1.5, 5.0)
	var gate_y = 60 + (split_y - 70) * 0.5
	draw_line(Vector2(center_x - 10, gate_y - 4), Vector2(center_x + 10, gate_y - 4), Color(0.95, 0.85, 0.1), 2.0)
	draw_line(Vector2(center_x - 10, gate_y + 4), Vector2(center_x + 10, gate_y + 4), Color(0.95, 0.85, 0.1), 2.0)
	
	draw_line(Vector2(0, split_y), Vector2(rect.size.x, split_y), Color(0.25, 0.35, 0.4), 2.0)
	
	var pw_h = rect.size.y - split_y - 60.0
	var base_y = split_y + pw_h * 0.7
	draw_line(Vector2(40, base_y), Vector2(rect.size.x - 50, base_y), Color(0.5, 0.6, 0.6, 0.6), 1.0)
	
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(5, base_y - 60), "+100", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.8, 0.8))
	draw_line(Vector2(40, base_y - 60), Vector2(rect.size.x - 50, base_y - 60), Color(0.2, 0.3, 0.3, 0.3), 1.0)
	draw_string(font, Vector2(5, base_y + 40), "-50", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.8, 0.8))
	draw_line(Vector2(40, base_y + 40), Vector2(rect.size.x - 50, base_y + 40), Color(0.2, 0.3, 0.3, 0.3), 1.0)
	
	var pts = PackedVector2Array()
	var start_x = 40.0
	var step_x = (rect.size.x - 90.0) / float(max_history_pts)
	
	for i in range(pw_spectral_history.size()):
		var x = start_x + i * step_x
		var vel = pw_spectral_history[i]
		var y = base_y - vel * 0.8
		pts.append(Vector2(x, y))
		draw_line(Vector2(x, base_y), Vector2(x, y), Color(0.2, 0.85, 0.75, 0.35), 2.0)
		
	if pts.size() > 1:
		draw_polyline(pts, Color(0.3, 0.95, 0.85, 0.9), 2.0)

func _draw_split_m_mode(rect: Rect2, t: float) -> void:
	var split_y = rect.size.y * 0.42
	
	var top_rect = Rect2(Vector2.ZERO, Vector2(rect.size.x, split_y))
	_draw_b_mode(top_rect, t)
	
	var center_x = rect.size.x * 0.5
	draw_line(Vector2(center_x, 60), Vector2(center_x, split_y - 10), Color(0.1, 0.85, 0.95, 0.8), 2.0)
	
	draw_line(Vector2(0, split_y), Vector2(rect.size.x, split_y), Color(0.25, 0.35, 0.4), 2.0)
	
	var m_h = rect.size.y - split_y - 60.0
	var start_x = 40.0
	var step_x = (rect.size.x - 90.0) / float(max_history_pts)
	
	for i in range(m_mode_history.size()):
		var x = start_x + i * step_x
		var col_data = m_mode_history[i]
		var num_pts = col_data.size()
		for j in range(num_pts):
			var val = col_data[j]
			if val > 0.1:
				var y = split_y + 10.0 + (float(j) / float(num_pts)) * m_h
				var alpha = clamp(val * 0.6, 0.0, 0.85)
				draw_circle(Vector2(x, y), 1.5, Color(0.8, 0.85, 0.9, alpha))

func _draw_depth_ruler(rect: Rect2) -> void:
	var x_pos = rect.size.x - 24.0
	var top_y = 60.0
	var scan_h = rect.size.y - 130.0
	var ticks = 8
	var step_px = scan_h / float(ticks)
	var step_cm = depth_cm / float(ticks)
	
	draw_line(Vector2(x_pos, top_y), Vector2(x_pos, top_y + scan_h), Color(0.4, 0.5, 0.5, 0.6), 1.5)
	
	var font = ThemeDB.fallback_font
	for i in range(ticks + 1):
		var y = top_y + i * step_px
		var tick_l = 10.0 if i % 2 == 0 else 5.0
		draw_line(Vector2(x_pos - tick_l, y), Vector2(x_pos, y), Color(0.7, 0.8, 0.8, 0.8), 1.5)
		if i % 2 == 0:
			draw_string(font, Vector2(x_pos - 32, y + 4), str(snapped(i * step_cm, 0.1)), HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, Color(0.7, 0.8, 0.8))

func _draw_overlays(rect: Rect2) -> void:
	var font = ThemeDB.fallback_font
	var center_x = rect.size.x * 0.5
	
	if show_centerline:
		draw_dashed_line(Vector2(center_x, 60), Vector2(center_x, rect.size.y - 70), Color(0.2, 0.8, 0.7, 0.4), 1.5, 6.0)
		
	if show_focus:
		var fy = 60.0 + (rect.size.y - 130.0) * 0.45
		draw_polyline(PackedVector2Array([
			Vector2(12, fy - 6), Vector2(22, fy), Vector2(12, fy + 6)
		]), Color(0.95, 0.75, 0.1, 0.9), 2.0)
		
	if is_frozen:
		draw_rect(Rect2(Vector2(center_x - 70, 10), Vector2(140, 36)), Color(0.85, 0.2, 0.2, 0.9), true, 6.0)
		draw_string(font, Vector2(center_x - 60, 34), "❄️ FREEZE", HORIZONTAL_ALIGNMENT_CENTER, 120, 16, Color.WHITE)

func _draw_calipers_and_annotations() -> void:
	var font = ThemeDB.fallback_font
	var yellow = Color(0.95, 0.85, 0.15)
	
	for m in measurements_list:
		var p1: Vector2 = m["p1"]
		var p2: Vector2 = m["p2"]
		draw_line(p1 - Vector2(6, 0), p1 + Vector2(6, 0), yellow, 2.0)
		draw_line(p1 - Vector2(0, 6), p1 + Vector2(0, 6), yellow, 2.0)
		draw_line(p2 - Vector2(6, 0), p2 + Vector2(6, 0), yellow, 2.0)
		draw_line(p2 - Vector2(0, 6), p2 + Vector2(0, 6), yellow, 2.0)
		draw_dashed_line(p1, p2, yellow, 1.5, 4.0)
		
		var mid = (p1 + p2) * 0.5
		draw_rect(Rect2(mid + Vector2(8, -14), Vector2(120, 24)), Color(0, 0, 0, 0.85), true, 4.0)
		draw_string(font, mid + Vector2(12, 3), m["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, yellow)
		
	if is_placing_caliper and caliper_points.size() >= 2:
		var p1 = caliper_points[0]
		var p2 = caliper_points[1]
		draw_line(p1 - Vector2(6, 0), p1 + Vector2(6, 0), yellow, 2.0)
		draw_line(p1 - Vector2(0, 6), p1 + Vector2(0, 6), yellow, 2.0)
		draw_line(p2 - Vector2(6, 0), p2 + Vector2(6, 0), yellow, 2.0)
		draw_line(p2 - Vector2(0, 6), p2 + Vector2(0, 6), yellow, 2.0)
		draw_dashed_line(p1, p2, yellow, 1.5, 4.0)
		
	for idx in range(annotations_list.size()):
		var ann = annotations_list[idx]
		var pos: Vector2 = ann["pos"]
		var txt: String = ann["text"]
		var width = txt.length() * 10 + 16
		var rect_box = Rect2(pos + Vector2(-4, -18), Vector2(width, 26))
		
		if idx == selected_annotation_idx:
			draw_rect(rect_box, Color(0.14, 0.85, 0.75, 0.95), true, 4.0)
			draw_rect(rect_box, Color(0.95, 0.95, 0.2, 1.0), false, 2.0)
			draw_string(font, pos + Vector2(4, 1), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
		else:
			draw_rect(rect_box, Color(0.1, 0.45, 0.45, 0.9), true, 4.0)
			draw_string(font, pos + Vector2(4, 1), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

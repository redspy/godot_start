class_name UIManager
extends Control

@onready var ultrasound_view: UltrasoundViewport = $ViewportContainer/UltrasoundViewport
@onready var viewport_container: MarginContainer = $ViewportContainer
@onready var left_panel: PanelContainer = $LeftPanel
@onready var right_panel: PanelContainer = $RightPanel
@onready var exam_manager: ExamManager = $ExamManager

# Top Bar
@onready var top_bar: PanelContainer = $TopBar
@onready var brand_label: Label = $TopBar/VBox/Row1/BrandLabel
@onready var probe_menu_btn: Button = $TopBar/VBox/Row1/ProbeMenuBtn
@onready var exams_btn: Button = $TopBar/VBox/Row1/ExamsBtn
@onready var rotate_btn: Button = $TopBar/VBox/Row1/RotateBtn
@onready var mode_badge: Label = $TopBar/VBox/Row1/ModeBadge
@onready var timi_label: Label = $TopBar/VBox/Row1/TIMILabel
@onready var sub_header_label: Label = $TopBar/VBox/Row2/SubHeaderLabel

# Bottom Controls
@onready var bottom_bar: PanelContainer = $BottomBar
@onready var freeze_btn: Button = $BottomBar/HBox/FreezeBtn
@onready var store_btn: Button = $BottomBar/HBox/StoreBtn
@onready var mode_btn: Button = $BottomBar/HBox/ModeBtn
@onready var cine_container: HBoxContainer = $BottomBar/HBox/CineContainer
@onready var cine_slider: HSlider = $BottomBar/HBox/CineContainer/CineSlider

# Left Panel Controls
@onready var preset_option: OptionButton = $LeftPanel/VBox/PresetOption
@onready var transducer_option: OptionButton = $LeftPanel/VBox/TransducerOption
@onready var gain_slider: HSlider = $LeftPanel/VBox/GainSlider
@onready var depth_slider: HSlider = $LeftPanel/VBox/DepthSlider

# TGC Sliders
@onready var tgc_1: VSlider = $LeftPanel/VBox/TGCBox/TGC1
@onready var tgc_2: VSlider = $LeftPanel/VBox/TGCBox/TGC2
@onready var tgc_3: VSlider = $LeftPanel/VBox/TGCBox/TGC3
@onready var tgc_4: VSlider = $LeftPanel/VBox/TGCBox/TGC4
@onready var tgc_5: VSlider = $LeftPanel/VBox/TGCBox/TGC5
@onready var tgc_6: VSlider = $LeftPanel/VBox/TGCBox/TGC6

# Additional Toggles
@onready var centerline_check: CheckBox = $LeftPanel/VBox/CenterlineCheck
@onready var focus_check: CheckBox = $LeftPanel/VBox/FocusCheck
@onready var flip_check: CheckBox = $LeftPanel/VBox/FlipCheck

# Right Panel Controls
@onready var exam_id_label: Label = $RightPanel/VBox/ExamIdLabel
@onready var patient_name_input: LineEdit = $RightPanel/VBox/PatientNameInput
@onready var gallery_grid: GridContainer = $RightPanel/VBox/Scroll/GalleryGrid

# Dialog Modals & Popups
@onready var export_dialog: AcceptDialog = $ExportDialog
@onready var viewer_dialog: AcceptDialog = $ViewerDialog
@onready var viewer_texture: TextureRect = $ViewerDialog/VBox/ViewerTexture
@onready var probe_popup: PopupMenu = $ProbePopup
@onready var caliper_popup: PopupMenu = $CaliperPopup
@onready var annotation_popup: PopupMenu = $AnnotationPopup

var is_left_panel_open: bool = false
var is_right_panel_open: bool = false
var panel_width: float = 380.0
var last_view_size: Vector2 = Vector2.ZERO
var current_orientation_mode: int = 0 # 0: Sensor, 1: Portrait, 2: Landscape

# Touch / Gesture Swipe
var touch_start_pos: Vector2 = Vector2.ZERO
var is_swiping: bool = false

func _ready() -> void:
	# Enable DisplayServer Sensor auto-rotation (6 = Sensor mode)
	DisplayServer.screen_set_orientation(6 as DisplayServer.ScreenOrientation)
	get_window().size_changed.connect(_on_window_resized)
	
	_setup_ui_signals()
	_update_top_bar_indicators()
	_populate_presets()
	_setup_popups()
	_update_orientation_layout()
	
	left_panel.position.x = -panel_width
	right_panel.position.x = get_viewport_rect().size.x
	cine_container.visible = false

func _on_window_resized() -> void:
	_update_orientation_layout()

func _process(_delta: float) -> void:
	var cur_size = get_viewport().get_visible_rect().size
	if cur_size != last_view_size:
		last_view_size = cur_size
		_update_orientation_layout()
		
	if ultrasound_view and gain_slider:
		if int(gain_slider.value) != ultrasound_view.gn_value:
			gain_slider.set_value_no_signal(ultrasound_view.gn_value)

func _update_orientation_layout() -> void:
	var vis_rect = get_viewport().get_visible_rect().size
	var win_size = DisplayServer.window_get_size()
	
	if vis_rect.x <= 0 or vis_rect.y <= 0:
		return
		
	var is_portrait = (win_size.y > win_size.x) or (vis_rect.y > vis_rect.x)
	
	if is_portrait:
		panel_width = vis_rect.x * 0.92
		top_bar.custom_minimum_size.y = 150
		bottom_bar.custom_minimum_size.y = 140
		viewport_container.add_theme_constant_override("margin_top", 150)
		viewport_container.add_theme_constant_override("margin_bottom", 140)
		
		# Scaled UP Font Sizes for Portrait Mode
		brand_label.add_theme_font_size_override("font_size", 25)
		probe_menu_btn.add_theme_font_size_override("font_size", 20)
		mode_badge.add_theme_font_size_override("font_size", 22)
		exams_btn.add_theme_font_size_override("font_size", 20)
		rotate_btn.add_theme_font_size_override("font_size", 20)
		timi_label.add_theme_font_size_override("font_size", 18)
		sub_header_label.add_theme_font_size_override("font_size", 18)
		
		mode_btn.add_theme_font_size_override("font_size", 22)
		freeze_btn.add_theme_font_size_override("font_size", 24)
		$BottomBar/HBox/CaliperBtn.add_theme_font_size_override("font_size", 22)
		$BottomBar/HBox/AnnotationBtn.add_theme_font_size_override("font_size", 22)
		$BottomBar/HBox/ClearToolsBtn.add_theme_font_size_override("font_size", 20)
		store_btn.add_theme_font_size_override("font_size", 22)
		
		# Scaled UP Touch Button Minimum Sizes
		probe_menu_btn.custom_minimum_size = Vector2(160, 56)
		exams_btn.custom_minimum_size = Vector2(140, 56)
		rotate_btn.custom_minimum_size = Vector2(140, 56)
		freeze_btn.custom_minimum_size = Vector2(180, 76)
		mode_btn.custom_minimum_size = Vector2(150, 72)
		$BottomBar/HBox/CaliperBtn.custom_minimum_size = Vector2(140, 72)
		$BottomBar/HBox/AnnotationBtn.custom_minimum_size = Vector2(140, 72)
		$BottomBar/HBox/ClearToolsBtn.custom_minimum_size = Vector2(110, 72)
		store_btn.custom_minimum_size = Vector2(150, 72)
	else:
		panel_width = 380.0
		top_bar.custom_minimum_size.y = 96
		bottom_bar.custom_minimum_size.y = 96
		viewport_container.add_theme_constant_override("margin_top", 96)
		viewport_container.add_theme_constant_override("margin_bottom", 96)
		
		# Standard Font Sizes for Landscape Mode
		brand_label.add_theme_font_size_override("font_size", 19)
		probe_menu_btn.add_theme_font_size_override("font_size", 15)
		mode_badge.add_theme_font_size_override("font_size", 17)
		exams_btn.add_theme_font_size_override("font_size", 15)
		rotate_btn.add_theme_font_size_override("font_size", 15)
		timi_label.add_theme_font_size_override("font_size", 15)
		sub_header_label.add_theme_font_size_override("font_size", 14)
		
		mode_btn.add_theme_font_size_override("font_size", 16)
		freeze_btn.add_theme_font_size_override("font_size", 19)
		$BottomBar/HBox/CaliperBtn.add_theme_font_size_override("font_size", 16)
		$BottomBar/HBox/AnnotationBtn.add_theme_font_size_override("font_size", 16)
		$BottomBar/HBox/ClearToolsBtn.add_theme_font_size_override("font_size", 15)
		store_btn.add_theme_font_size_override("font_size", 16)
		
		probe_menu_btn.custom_minimum_size = Vector2(130, 44)
		exams_btn.custom_minimum_size = Vector2(120, 44)
		rotate_btn.custom_minimum_size = Vector2(110, 44)
		freeze_btn.custom_minimum_size = Vector2(170, 64)
		mode_btn.custom_minimum_size = Vector2(140, 60)
		$BottomBar/HBox/CaliperBtn.custom_minimum_size = Vector2(130, 60)
		$BottomBar/HBox/AnnotationBtn.custom_minimum_size = Vector2(130, 60)
		$BottomBar/HBox/ClearToolsBtn.custom_minimum_size = Vector2(100, 60)
		store_btn.custom_minimum_size = Vector2(140, 60)
		
	left_panel.custom_minimum_size.x = panel_width
	left_panel.size.x = panel_width
	right_panel.custom_minimum_size.x = panel_width
	right_panel.size.x = panel_width
	
	if not is_left_panel_open:
		left_panel.position.x = -panel_width
	else:
		left_panel.position.x = 0.0
		
	if not is_right_panel_open:
		right_panel.position.x = vis_rect.x
	else:
		right_panel.position.x = vis_rect.x - panel_width

func _on_rotate_btn_pressed() -> void:
	current_orientation_mode = (current_orientation_mode + 1) % 3
	match current_orientation_mode:
		0:
			rotate_btn.text = " 🔄 ROTATE "
			DisplayServer.screen_set_orientation(6 as DisplayServer.ScreenOrientation)
		1:
			rotate_btn.text = " 📱 PORTRAIT "
			DisplayServer.screen_set_orientation(1 as DisplayServer.ScreenOrientation)
		2:
			rotate_btn.text = " 💻 LANDSCAPE "
			DisplayServer.screen_set_orientation(0 as DisplayServer.ScreenOrientation)
			
	_update_orientation_layout()

func _setup_ui_signals() -> void:
	freeze_btn.pressed.connect(_on_freeze_toggled)
	store_btn.pressed.connect(_on_store_pressed)
	mode_btn.pressed.connect(_on_mode_switched)
	rotate_btn.pressed.connect(_on_rotate_btn_pressed)
	
	preset_option.item_selected.connect(_on_preset_changed)
	transducer_option.item_selected.connect(_on_transducer_changed)
	
	gain_slider.min_value = 0
	gain_slider.max_value = 100
	gain_slider.step = 1
	gain_slider.value = 50
	gain_slider.value_changed.connect(_on_gain_changed)
	depth_slider.value_changed.connect(_on_depth_changed)
	
	var tgc_sliders = [tgc_1, tgc_2, tgc_3, tgc_4, tgc_5, tgc_6]
	for idx in range(tgc_sliders.size()):
		var s = tgc_sliders[idx]
		s.value_changed.connect(func(v): _on_tgc_changed(idx, v))
		
	centerline_check.toggled.connect(func(b): ultrasound_view.show_centerline = b; ultrasound_view.queue_redraw())
	focus_check.toggled.connect(func(b): ultrasound_view.show_focus = b; ultrasound_view.queue_redraw())
	flip_check.toggled.connect(func(b): ultrasound_view.flip_horizontal = b; ultrasound_view.queue_redraw())
	
	exam_manager.exam_started.connect(_on_exam_started)
	exam_manager.media_stored.connect(_on_media_stored)
	
	probe_menu_btn.pressed.connect(_on_probe_menu_pressed)
	exams_btn.pressed.connect(toggle_right_panel)
	$LeftPanel/VBox/MenuTitle/ProbeIconBtn.pressed.connect(toggle_left_panel)
	$RightPanel/VBox/EndExamBtn.pressed.connect(_on_end_exam_pressed)
	
	$BottomBar/HBox/CaliperBtn.pressed.connect(_show_caliper_menu)
	$BottomBar/HBox/AnnotationBtn.pressed.connect(_show_annotation_menu)
	$BottomBar/HBox/ClearToolsBtn.pressed.connect(_clear_tools)
	
	cine_slider.value_changed.connect(func(v): ultrasound_view.cine_index = int(v); ultrasound_view.queue_redraw())

func _setup_popups() -> void:
	probe_popup.clear()
	probe_popup.add_item("🔍 Convex Probe (2-5 MHz Abdominal)", 0)
	probe_popup.add_item("❤️ Phased Array (1.6-3.7 MHz Cardiac)", 1)
	probe_popup.add_item("🩸 Linear Probe (3-12 MHz Vascular)", 2)
	probe_popup.add_item("🧬 Endo Probe (5-9 MHz 160° OB-GYN)", 3)
	probe_popup.id_pressed.connect(_on_probe_selected)
	
	caliper_popup.clear()
	caliper_popup.add_item("Distance (D1/D2 cm)", 0)
	caliper_popup.add_item("Angle (°)", 1)
	caliper_popup.add_item("Heart Rate (HR BPM)", 2)
	caliper_popup.add_item("OB Metrics (BPD/GA)", 3)
	caliper_popup.id_pressed.connect(_on_caliper_selected)
	
	annotation_popup.clear()
	var labels = ["LIVER", "KIDNEY", "GALLBLADDER", "CARDIAC - AP4", "CARDIAC - PLAX", "CAROTID ARTERY", "THYROID", "BLADDER"]
	for i in range(labels.size()):
		annotation_popup.add_item(labels[i], i)
	annotation_popup.id_pressed.connect(_on_annotation_selected)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event.pressed:
			touch_start_pos = event.position
			is_swiping = true
		else:
			if is_swiping:
				var swipe_vec = event.position - touch_start_pos
				if swipe_vec.length() > 60.0 and abs(swipe_vec.x) > abs(swipe_vec.y):
					if swipe_vec.x > 0:
						open_left_panel()
					else:
						open_right_panel()
				is_swiping = false

func toggle_left_panel() -> void:
	if is_left_panel_open:
		close_left_panel()
	else:
		open_left_panel()

func open_left_panel() -> void:
	is_left_panel_open = true
	is_right_panel_open = false
	ultrasound_view.is_frozen = true
	_animate_panel(left_panel, 0.0)
	_animate_panel(right_panel, get_viewport().get_visible_rect().size.x)
	_update_freeze_state()

func close_left_panel() -> void:
	is_left_panel_open = false
	_animate_panel(left_panel, -panel_width)

func toggle_right_panel() -> void:
	if is_right_panel_open:
		close_right_panel()
	else:
		open_right_panel()

func open_right_panel() -> void:
	is_right_panel_open = true
	is_left_panel_open = false
	ultrasound_view.is_frozen = true
	_animate_panel(right_panel, get_viewport().get_visible_rect().size.x - panel_width)
	_animate_panel(left_panel, -panel_width)
	_update_freeze_state()

func close_right_panel() -> void:
	is_right_panel_open = false
	_animate_panel(right_panel, get_viewport().get_visible_rect().size.x)

func _animate_panel(panel: Control, target_x: float) -> void:
	var tween = create_tween()
	tween.tween_property(panel, "position:x", target_x, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_freeze_toggled() -> void:
	ultrasound_view.is_frozen = not ultrasound_view.is_frozen
	if not ultrasound_view.is_frozen:
		close_left_panel()
		close_right_panel()
	_update_freeze_state()

func _update_freeze_state() -> void:
	if ultrasound_view.is_frozen:
		freeze_btn.text = "🔴 LIVE"
		freeze_btn.modulate = Color(0.2, 0.9, 0.4)
		cine_container.visible = true
		cine_slider.max_value = max(0, ultrasound_view.cine_frames.size() - 1)
		cine_slider.value = ultrasound_view.cine_index
	else:
		freeze_btn.text = "❄️ FREEZE"
		freeze_btn.modulate = Color.WHITE
		cine_container.visible = false

func _on_store_pressed() -> void:
	var img = get_viewport().get_texture().get_image()
	var item = exam_manager.store_capture(img, mode_badge.text, ultrasound_view.active_preset)
	
	_play_flying_thumbnail_effect(img)

func _play_flying_thumbnail_effect(img: Image) -> void:
	var fly_thumb = TextureRect.new()
	fly_thumb.custom_minimum_size = Vector2(160, 110)
	fly_thumb.size = Vector2(160, 110)
	fly_thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fly_thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fly_thumb.texture = ImageTexture.create_from_image(img)
	
	var start_pos = store_btn.global_position + Vector2(0, -60)
	var target_pos = exams_btn.global_position + Vector2(20, 10)
	fly_thumb.global_position = start_pos
	fly_thumb.scale = Vector2(0.3, 0.3)
	fly_thumb.pivot_offset = Vector2(80, 55)
	
	add_child(fly_thumb)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(fly_thumb, "global_position", target_pos, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fly_thumb, "scale", Vector2(0.15, 0.15), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(fly_thumb, "modulate:a", 0.0, 0.55)
	
	tween.finished.connect(func():
		fly_thumb.queue_free()
		_pulse_exams_button()
	)

func _pulse_exams_button() -> void:
	var tween = create_tween()
	tween.tween_property(exams_btn, "scale", Vector2(1.25, 1.25), 0.12)
	tween.tween_property(exams_btn, "scale", Vector2(1.0, 1.0), 0.15)
	exams_btn.modulate = Color(0.2, 0.9, 0.75)
	var reset_tween = create_tween()
	reset_tween.tween_property(exams_btn, "modulate", Color.WHITE, 0.3)

func _on_mode_switched() -> void:
	var next_mode = (int(ultrasound_view.mode) + 1) % 4
	ultrasound_view.mode = next_mode as UltrasoundViewport.ScanMode
	
	match ultrasound_view.mode:
		UltrasoundViewport.ScanMode.B_MODE:
			mode_badge.text = "B-MODE"
		UltrasoundViewport.ScanMode.COLOR_DOPPLER:
			mode_badge.text = "COLOR DOPPLER"
		UltrasoundViewport.ScanMode.PW_DOPPLER:
			mode_badge.text = "PW DOPPLER"
		UltrasoundViewport.ScanMode.M_MODE:
			mode_badge.text = "M-MODE"
	ultrasound_view.queue_redraw()

func _on_probe_menu_pressed() -> void:
	probe_popup.position = Vector2i(probe_menu_btn.global_position) + Vector2i(0, 50)
	probe_popup.popup()

func _on_probe_selected(id: int) -> void:
	ultrasound_view.transducer = id as UltrasoundViewport.TransducerType
	transducer_option.select(id)
	
	match ultrasound_view.transducer:
		UltrasoundViewport.TransducerType.CONVEX:
			probe_menu_btn.text = " 🔍 Convex "
			preset_option.select(0)
		UltrasoundViewport.TransducerType.PHASED:
			probe_menu_btn.text = " ❤️ Phased "
			preset_option.select(1)
		UltrasoundViewport.TransducerType.LINEAR:
			probe_menu_btn.text = " 🩸 Linear "
			preset_option.select(4)
		UltrasoundViewport.TransducerType.ENDO:
			probe_menu_btn.text = " 🧬 Endo "
			preset_option.select(3)
			
	_update_sub_header_metadata()
	ultrasound_view.queue_redraw()

func _on_preset_changed(idx: int) -> void:
	var preset_name = preset_option.get_item_text(idx)
	ultrasound_view.active_preset = preset_name
	
	if preset_name == "Cardiac":
		transducer_option.select(1)
		ultrasound_view.transducer = UltrasoundViewport.TransducerType.PHASED
		probe_menu_btn.text = " ❤️ Phased "
		depth_slider.value = 18.0
	elif preset_name == "Vascular" or preset_name == "MSK":
		transducer_option.select(2)
		ultrasound_view.transducer = UltrasoundViewport.TransducerType.LINEAR
		probe_menu_btn.text = " 🩸 Linear "
		depth_slider.value = 8.0
	elif preset_name == "OB-GYN":
		transducer_option.select(3)
		ultrasound_view.transducer = UltrasoundViewport.TransducerType.ENDO
		probe_menu_btn.text = " 🧬 Endo "
		depth_slider.value = 12.0
	else:
		transducer_option.select(0)
		ultrasound_view.transducer = UltrasoundViewport.TransducerType.CONVEX
		probe_menu_btn.text = " 🔍 Convex "
		depth_slider.value = 8.9
		
	_update_sub_header_metadata()
	ultrasound_view.queue_redraw()

func _update_sub_header_metadata() -> void:
	var probe_str = "CA1-7A"
	match ultrasound_view.transducer:
		UltrasoundViewport.TransducerType.CONVEX: probe_str = "CA1-7A"
		UltrasoundViewport.TransducerType.PHASED: probe_str = "PA2-4"
		UltrasoundViewport.TransducerType.LINEAR: probe_str = "L3-12"
		UltrasoundViewport.TransducerType.ENDO: probe_str = "EV5-9"
		
	var preset_str = ultrasound_view.active_preset
	if preset_str == "OB-GYN" or preset_str == "Abdominal":
		preset_str = "OB / 2nd Trimester"
		
	sub_header_label.text = preset_str + " / " + probe_str + " / FR28Hz / " + str(snapped(ultrasound_view.depth_cm, 0.1)) + "cm"

func _on_transducer_changed(idx: int) -> void:
	_on_probe_selected(idx)

func _on_gain_changed(v: float) -> void:
	ultrasound_view.gn_value = int(v)
	ultrasound_view.gain = v / 50.0
	ultrasound_view.queue_redraw()

func _on_depth_changed(v: float) -> void:
	ultrasound_view.depth_cm = v
	_update_sub_header_metadata()
	ultrasound_view.queue_redraw()

func _on_tgc_changed(idx: int, val: float) -> void:
	ultrasound_view.tgc_bands[idx] = val / 50.0
	ultrasound_view.queue_redraw()

func _show_caliper_menu() -> void:
	caliper_popup.position = Vector2i($BottomBar/HBox/CaliperBtn.global_position) + Vector2i(0, -170)
	caliper_popup.popup()

func _on_caliper_selected(id: int) -> void:
	ultrasound_view.active_caliper_type = id as UltrasoundViewport.CaliperType
	ultrasound_view.is_frozen = true
	_update_freeze_state()

func _show_annotation_menu() -> void:
	annotation_popup.position = Vector2i($BottomBar/HBox/AnnotationBtn.global_position) + Vector2i(0, -230)
	annotation_popup.popup()

func _on_annotation_selected(id: int) -> void:
	var label_txt = annotation_popup.get_item_text(id)
	ultrasound_view.active_annotation_label = label_txt
	ultrasound_view.is_frozen = true
	_update_freeze_state()

func _clear_tools() -> void:
	ultrasound_view.clear_calipers()
	ultrasound_view.clear_annotations()

func _populate_presets() -> void:
	preset_option.clear()
	var presets = ["Abdominal", "Cardiac", "MSK", "OB-GYN", "Vascular", "Lung", "Small Parts"]
	for p in presets:
		preset_option.add_item(p)
		
	transducer_option.clear()
	transducer_option.add_item("Convex (CA1-7A)")
	transducer_option.add_item("Phased (PA2-4)")
	transducer_option.add_item("Linear (L3-12)")
	transducer_option.add_item("Endo (EV5-9)")

func _update_top_bar_indicators() -> void:
	timi_label.text = "MI 1.0   TIb 0.3  TIs 0.3"
	mode_badge.text = "B-MODE"
	_update_sub_header_metadata()

func _on_exam_started(exam_id: String, p_name: String) -> void:
	exam_id_label.text = "Exam ID: " + exam_id
	patient_name_input.text = p_name
	_clear_gallery()

func _on_media_stored(item: Dictionary) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(150, 110)
	
	var tex_rect = TextureRect.new()
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if item.image:
		tex_rect.texture = ImageTexture.create_from_image(item.image)
	btn.add_child(tex_rect)
	
	btn.pressed.connect(func(): _open_viewer(item))
	gallery_grid.add_child(btn)

func _open_viewer(item: Dictionary) -> void:
	if item.image:
		viewer_texture.texture = ImageTexture.create_from_image(item.image)
	viewer_dialog.title = "Captured Media - " + item.id + " (" + item.mode + ")"
	viewer_dialog.popup_centered(Vector2i(620, 440))

func _clear_gallery() -> void:
	for child in gallery_grid.get_children():
		child.queue_free()

func _on_end_exam_pressed() -> void:
	export_dialog.dialog_text = "Exam " + exam_manager.current_exam_id + " Concluded.\n\n" + \
		"Total Captures: " + str(exam_manager.stored_items.size()) + " items\n" + \
		"Export Protocols:\n" + \
		" ✅ DICOM Server (PACS): Transmitted\n" + \
		" ✅ DICOMweb API Cloud (MyImageCloud): Synced\n" + \
		" ✅ Local Storage: Archived"
	export_dialog.popup_centered(Vector2i(480, 240))
	
	exam_manager.end_current_exam()
	exam_manager.start_new_exam(patient_name_input.text if patient_name_input.text != "" else "Anonymous Patient")

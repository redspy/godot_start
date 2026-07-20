class_name ExamManager
extends Node

signal exam_started(exam_id: String, patient_name: String)
signal media_stored(item: Dictionary)
signal exam_ended(exam_id: String)

var current_exam_id: String = ""
var patient_name: String = "Anonymous Patient"
var exam_start_time: String = ""
var stored_items: Array = []
var past_exams: Array = []

func _ready() -> void:
	start_new_exam("Anonymous Patient")

func start_new_exam(p_name: String = "Anonymous Patient") -> void:
	if current_exam_id != "":
		end_current_exam()
	
	current_exam_id = "EXAM-" + str(Time.get_unix_time_from_system()).left(10)
	patient_name = p_name
	exam_start_time = Time.get_time_string_from_system()
	stored_items.clear()
	emit_signal("exam_started", current_exam_id, patient_name)

func store_capture(texture_data: Image, mode_name: String, preset_name: String) -> Dictionary:
	var timestamp = Time.get_time_string_from_system()
	var item = {
		"id": "CAP-" + str(stored_items.size() + 1),
		"time": timestamp,
		"mode": mode_name,
		"preset": preset_name,
		"image": texture_data
	}
	stored_items.append(item)
	emit_signal("media_stored", item)
	return item

func end_current_exam() -> void:
	if current_exam_id == "":
		return
	
	var exam_record = {
		"exam_id": current_exam_id,
		"patient_name": patient_name,
		"start_time": exam_start_time,
		"count": stored_items.size(),
		"items": stored_items.duplicate()
	}
	past_exams.append(exam_record)
	var ended_id = current_exam_id
	current_exam_id = ""
	emit_signal("exam_ended", ended_id)

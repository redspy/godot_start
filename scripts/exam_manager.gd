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

var worklist_patients: Array[Dictionary] = [
	{ "id": "P-2026-0812", "name": "Kim, Min-Soo", "age": "42M", "proc": "Abdominal Ultrasound (CA1-7A)" },
	{ "id": "P-2026-0941", "name": "Park, Ji-Eun", "age": "31F", "proc": "OB-GYN Routine Fetal Scan (EV5-9)" },
	{ "id": "P-2026-1033", "name": "Lee, Sung-Ho", "age": "58M", "proc": "Carotid Artery Vascular (L3-12)" },
	{ "id": "P-2026-1188", "name": "Choi, Young-Hee", "age": "65F", "proc": "Echocardiogram AP4 (PA2-4)" }
]

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

func generate_dicom_sr_report() -> String:
	var sr = "=== DICOM STRUCTURED REPORT (SR) ===\n"
	sr += "SOP Class UID: 1.2.840.10008.5.1.4.1.1.88.33 (Comprehensive SR)\n"
	sr += "Patient Name: " + patient_name + "\n"
	sr += "Exam ID: " + current_exam_id + "\n"
	sr += "Study Date/Time: " + Time.get_date_string_from_system() + " " + exam_start_time + "\n"
	sr += "Modality: US (Ultrasound)\n"
	sr += "Manufacturer: Handheld POCUS Division\n"
	sr += "-----------------------------------\n"
	sr += "[MEASUREMENT SUMMARY]\n"
	sr += " • BPD (Biparietal Dia.): 5.20 cm  (GA: 21w5d ± 12d)\n"
	sr += " • EDD (Est. Delivery): 09-09-2021\n"
	sr += " • EFW (Est. Fetal Wt): 419 g\n"
	sr += " • FL / BPD Ratio: 65.95 %\n"
	sr += " • HC (Head Circumference): 18.83 cm\n"
	sr += " • HC / AC Ratio: 1.13\n"
	sr += "-----------------------------------\n"
	sr += "Total Captured Frames: " + str(stored_items.size()) + " items\n"
	sr += "DICOM Storage Commitment: PENDING (PACS Synced)"
	return sr

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

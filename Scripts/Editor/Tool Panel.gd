extends Control

onready var pos_tool := $"Pos Tool"
onready var ai_tool := $"AI Tool"
onready var tz_tool := $"Track Zone Tool"

func _ready():
	pos_tool.hint_tooltip = "Position Tool"
	ai_tool.hint_tooltip = "AI Tool"
	tz_tool.hint_tooltip = "Track Zone Tool"
	
	pos_tool.connect("pressed", self, "edit_pos")
	ai_tool.connect("pressed", self, "edit_ai")
	tz_tool.connect("pressed", self, "edit_tz")
	
	tz_tool.disabled = true # Zone editing is not supported yet
	
func edit_none():
	if not owner.data_name:
		return
	owner.positionData.editable = false
	owner.aiData.editable = false
	owner.trackZoneData.editable = false

func edit_pos():
	if not owner.data_name:
		return
	edit_none()
	owner.positionData.editable = true
	
func edit_ai():
	if not owner.data_name:
		return
	edit_none()
	owner.aiData.editable = true
	
func edit_tz():
	if not owner.data_name:
		return
	edit_none()
	owner.trackZoneData.editable = true
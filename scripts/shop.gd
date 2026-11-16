extends Control

const QUIPS: Array[String] = [
	"TOOK YOU LONG ENOUGH, PONCHO, WHERES THE POWER?!",
	"TAKE IT AND LEAVE, DONT YOU DARE COME BACK WITHOUT MORE OF THIS STUFF!",
	"NO REFUNDS! NO REFUNDS, NOOOOO REFUNDS!",
	"WITH THIS, YOU WONT NEED YOUR HANDS!",
	"I MADE THAT MYSELF!"
]

@onready var quip_label: Label = $%Quip
@onready var energy_label: Label = $%EnergyLabel
@onready var list: VBoxContainer = $%List
@onready var leave_button: Button = $%Leave

func _ready() -> void:
	leave_button.pressed.connect(_on_leave)
	quip_label.text = QUIPS[0]
	_rebuild()

func _rebuild() -> void:
	energy_label.text = "ENERGY: %d" % Progress.energy
	
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	
	for def in UpgradeCatalog.ALL:
		list.add_child(_make_row(def))

func _make_row(def: Dictionary) -> Control:
	var id: String = def["id"]
	var owned: int = Progress.upgrade_level(id)
	var cost: int = UpgradeCatalog.next_cost(id, owned)
	var unlocked: bool = UpgradeCatalog.is_unlocked(id)
	
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	
	var info := Label.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if unlocked:
		info.text = "%s [%d/%d]\n%s" % [def["name"], owned, UpgradeCatalog.max_level(id), def["description"]]
	else:
		info.text = "???\nClear more of the campaign to unlock!"
	row.add_child(info)
	
	var buy := Button.new()
	buy.custom_minimum_size = Vector2(130.0, 44.0)
	buy.focus_mode = Control.FOCUS_NONE
	
	if not unlocked:
		buy.text = "LOCKED"
		buy.disabled = true
	elif cost < 0:
		buy.text = "MAXED"
		buy.disabled = true
	else:
		buy.text = "BUY (%d)" % cost
		buy.disabled = Progress.energy < cost
		buy.pressed.connect(_on_buy.bind(id))
	row.add_child(buy)
	return row

func _on_buy(id: String) -> void:
	if Progress.buy_upgrade(id):
		quip_label.text = QUIPS[1 + randi() %  (QUIPS.size() - 1)]
		_rebuild.call_deferred()

func  _on_leave() -> void:
	get_tree().change_scene_to_file(Progress.shop_return_scene)

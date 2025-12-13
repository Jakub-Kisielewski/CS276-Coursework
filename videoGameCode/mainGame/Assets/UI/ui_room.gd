extends Control

@onready var health_bar: ProgressBar = %HealthBar
@onready var currency_label: Label = %CurrencyLabel
@onready var weapon_container: HBoxContainer = %WeaponContainer

# Preload a small scene or texture for the weapon icon if needed
# For simplicity, we will create TextureRect nodes via code
@export var weapon_icon_size: Vector2 = Vector2(64, 64)

func _ready():
	# Connect to GameData signals
	GameData.player_stats_changed.connect(_on_stats_changed)
	GameData.currency_updated.connect(_on_currency_updated)
	GameData.weapon_list_changed.connect(_update_weapon_carousel)
	GameData.active_weapon_changed.connect(_highlight_active_weapon)
	
	# Initial UI Setup
	_on_stats_changed()
	_on_currency_updated(GameData.currency)
	_update_weapon_carousel()
	

func _on_stats_changed():
	health_bar.max_value = GameData.max_health
	health_bar.value = GameData.current_health
	
	# Optional: Change color based on health status
	if health_bar.value < health_bar.max_value * 0.3:
		health_bar.modulate = Color.RED
	else:
		health_bar.modulate = Color.WHITE

func _on_currency_updated(amount: int):
	currency_label.text = "Gold: " + str(amount)

func _update_weapon_carousel():
	# 1. Clear existing children properly
	for child in weapon_container.get_children():
		weapon_container.remove_child(child) # <--- ADD THIS (Removes from list immediately)
		child.queue_free() # (Deletes from memory later)
		
	# 2. Create icons for each unlocked weapon
	for i in range(GameData.current_weapons.size()):
		var weapon = GameData.current_weapons[i]
		
		# Null safety check
		if weapon == null:
			continue
			
		var icon = TextureRect.new()
		
		if "icon" in weapon and weapon.icon != null:
			icon.texture = weapon.icon
		else:
			var placeholder = PlaceholderTexture2D.new()
			placeholder.size = weapon_icon_size
			icon.texture = placeholder
			
		icon.custom_minimum_size = weapon_icon_size
		
		# Use EXPAND mode so it scales nicely within the box
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Set pivot to center so it scales from the middle, not top-left
		icon.pivot_offset = weapon_icon_size / 2
		
		icon.name = "WeaponIcon_" + str(i)
		weapon_container.add_child(icon)
		
	# 3. Highlight the correct one
	_highlight_active_weapon(GameData.active_weapon_index)

func _highlight_active_weapon(index: int):
	var children = weapon_container.get_children()
	for i in range(children.size()):
		var icon = children[i]
		if i == index:
			icon.modulate = Color(1, 1, 1, 1) # Normal brightness
			icon.scale = Vector2(1.2, 1.2) # Slightly larger
		else:
			icon.modulate = Color(0.5, 0.5, 0.5, 0.8) # Dimmed
			icon.scale = Vector2(1, 1)

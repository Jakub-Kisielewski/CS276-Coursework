extends Control

var cost_rarity_upgrade: int = 50.0
var cost_type_upgrade : int = 50.0
var cost_special_attack: int = 50.0
var cost_heal : int = 50.0
var cost_defense_upgrade: int = 50.0
var cost_damage_upgrade: int = 50.0
var cost_dash_charge: int = 50.0
var cost_dash_transparency: int = 50.0 #dash through enemies
var cost_decoy : int = 50.0
#currency_updated updates the UI for money

func ready():
	#button press connect to appropriate function, 
	pass

func buy_rarity_upgrade():
	if GameData.currency >= cost_rarity_upgrade:
		if GameData.upgrade_active_weapon_rarity():
			GameData.currency -= cost_rarity_upgrade
			GameData.currency_updated.emit(GameData.currency)
			
func buy_type_upgrade():
	if GameData.currency >= cost_type_upgrade:
		if GameData.upgrade_active_weapon_type():
			GameData.currency -= cost_type_upgrade
			GameData.currency_updated.emit(GameData.currency)

func buy_special_attack():
	if GameData.currency >= cost_special_attack:
			if GameData.unlock_active_weapon_special():
				GameData.currency -= cost_special_attack
				GameData.currency_updated.emit(GameData.currency)
				
func buy_heal():
	if GameData.currency >= cost_heal:
		GameData.currency =- cost_heal
		GameData.update_health(250)
		
func buy_defense_upgrade():
	if GameData.currency >= cost_defense_upgrade:
		GameData.currency =- cost_defense_upgrade
		GameData.upgrade_defense()
		
		
func buy_damage_upgrade():
	if GameData.currency >= cost_damage_upgrade:
		GameData.currency =- cost_damage_upgrade
		GameData.upgrade_damage(5)
		
		
func buy_dash_charge():
	if GameData.currency >= cost_dash_charge:
		if GameData.upgrade_dash_charges():
			GameData.currency -= cost_dash_charge
			GameData.currency_updated.emit(GameData.currency)
			
func buy_dash_transparency():
	if GameData.currency >= cost_dash_transparency:
		if GameData.unlock_dash_through_enemies():
			GameData.currency -= cost_dash_transparency
			GameData.currency_updated.emit(GameData.currency)
			
func buy_decoy():
	if GameData.currency >= cost_decoy:
		if GameData.unlock_decoy():
			GameData.currency -= cost_decoy
			GameData.currency_updated.emit(GameData.currency)

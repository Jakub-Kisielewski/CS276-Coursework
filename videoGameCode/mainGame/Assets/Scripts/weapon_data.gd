class_name WeaponData extends Resource

enum Rarity {DULL, SHINY, PRISMATIC}
enum WeaponType {SWORD, SPEAR, BOW}

@export var display_name: String
@export var rarity: Rarity = Rarity.PRISMATIC
@export var weapon_type: WeaponType = WeaponType.SWORD


@export var base_attack: float = 10.0
@export var weapon_mult : float = 1.0

func get_rarity_mult() -> float:
	match rarity:
		Rarity.DULL:
			return 1.0
		Rarity.SHINY:
			return 1.5
		Rarity.PRISMATIC:
			return 2.5
	print("null rarity error")
	return 1.0
	
func get_attack_value(base_stat_damage: float, attack_mult: float) -> float:
	var atk : float = base_attack * get_rarity_mult() * get_type_mult() * attack_mult
	return atk
	
func get_type_mult() -> float:
	return weapon_mult


#Use this for when player chooses to upgrade their weapon to a better rarity in the shop
func upgrade_rarity() -> void:
	match rarity:
		Rarity.DULL:
			rarity = Rarity.SHINY
		Rarity.SHINY:
			rarity = Rarity.PRISMATIC
		Rarity.PRISMATIC:
			print("already max rarity")
			
#use this for when the player chooses to upgrade their weapon proficiency in the shop. Eg. Ranged weapon attack up"
func upgrade_type():
	if weapon_mult >= 2.0: #200% max damage increase
		print("attack mult is at max")
	else:
		weapon_mult += 0.1 #10% damage increase for that weapon

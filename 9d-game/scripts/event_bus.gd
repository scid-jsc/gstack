extends Node

signal player_damaged(amount: int)
signal player_healed(amount: int)
signal player_died
signal player_respawned
signal player_leveled_up(new_level: int)
signal monster_damaged(monster: Node, amount: int)
signal monster_killed(monster: Node)
signal item_picked_up(item_name: String, count: int)
signal gold_picked_up(amount: int)
signal skill_used(skill_index: int, skill_name: String)
signal skill_cooldown_started(skill_index: int, cooldown: float)
signal target_changed(target: Node)
signal zone_changed(zone_name: String)
signal chat_message(text: String, color: Color)
signal npc_interact(npc_name: String)
signal quest_updated(quest_name: String)
signal inventory_changed
signal equipment_changed
signal show_damage_number(position: Vector3, amount: int, is_crit: bool)
signal show_notification(text: String)

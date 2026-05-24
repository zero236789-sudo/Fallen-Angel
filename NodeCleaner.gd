extends Node

# Tiempo máximo que un nodo puede existir antes de ser limpiado (en segundos)
@export var max_lifetime: float = 10.0

# Grupos que quieres limpiar automáticamente
@export var groups_to_clean := ["player_bullet", "enemy_bullet", "fx", "garbage"]

var tracked_nodes := {}

func _process(delta):
	for node in tracked_nodes.keys():
		if not is_instance_valid(node):
			tracked_nodes.erase(node)
			continue

		tracked_nodes[node] += delta

		if tracked_nodes[node] >= max_lifetime:
			node.queue_free()
			tracked_nodes.erase(node)

func track(node: Node):
	for g in groups_to_clean:
		if node.is_in_group(g):
			tracked_nodes[node] = 0.0
			return
func _ready():
	print("✅ NodeCleaner activo y listo")

extends Node

# Store all configuration data
var data: Dictionary = {}

# Default config file (you can change this)
const DEFAULT_CONFIG_PATH := "res://game_config.json"

func _ready():
    load_config(DEFAULT_CONFIG_PATH)


# --------------------------
# Load configuration JSON
# --------------------------
func load_config(path: String) -> void:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("ConfigManager: cannot open %s" % path)
        return

    var json := JSON.new()
    var err := json.parse(file.get_as_text())
    if err != OK:
        push_error("ConfigManager: JSON parse error at line %d: %s"
            % [json.get_error_line(), json.get_error_message()])
        return

    data = json.data


# --------------------------
# Save configuration to user://
# --------------------------
func save_config(path: String = "user://game_config.json") -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("ConfigManager: cannot write to %s" % path)
        return

    file.store_string(JSON.stringify(data, "\t"))


# --------------------------
# Get configuration: supports "a.b.c" path
# --------------------------
func get_value(path: String, default_value = null):
    var current = data
    var keys = path.split(".")
    for k in keys:
        if current.has(k):
            current = current[k]
        else:
            return default_value
    return current


# --------------------------
# Set configuration: supports "a.b.c" path
# --------------------------
func set_value(path: String, value) -> void:
    var keys = path.split(".")
    var current = data

    for i in range(keys.size()):
        var key = keys[i]

        if i == keys.size() - 1:
            current[key] = value
        else:
            if not current.has(key) or typeof(current[key]) != TYPE_DICTIONARY:
                current[key] = {}
            current = current[key]

extends Node
# Loading Manager - Manages resource preloading and progress tracking

class_name LoadingManager

signal loading_progress(current: int, total: int, percent: float)
signal loading_complete()
signal loading_failed(error: String)

# List of all resources to preload
var resources_to_load: Dictionary = {}
var loaded_count: int = 0
var failed_count: int = 0
var total_count: int = 0

# Path to asset pack JSON files
var asset_pack_path: String = "res://assets/asset-pack.json"
var animations_path: String = "res://assets/animations.json"

# Reference to the network resource loader (autoload singleton)
var _loader: Node


func _ready() -> void:
    # Use the autoload singleton directly
    _loader = NetworkResourceLoader
    print("[LoadingManager] ✓ Initialized")
    
    # Load resources from both JSONs
    _load_resources_from_json()
    _load_animation_frames_from_json()
    print("[LoadingManager] ✓ Ready to load resources")

func _load_resources_from_json() -> void:
    """Load resource list from asset-pack.json file"""
    resources_to_load.clear()
    
    # Load and parse the JSON file
    var file = FileAccess.open(asset_pack_path, FileAccess.READ)
    if file == null:
        print("Asset pack file not found at: " + asset_pack_path + " - proceeding without preloaded resources")
        return
    
    var json = JSON.new()
    var json_string = file.get_as_text()
    var error = json.parse(json_string)
    
    if error != OK:
        print("Failed to parse asset pack JSON at: " + asset_pack_path + " - proceeding without preloaded resources")
        return
    
    var asset_pack = json.data
    if asset_pack is not Dictionary:
        print("Asset pack is not a valid dictionary - proceeding without preloaded resources")
        return
    
    # Iterate through all resource categories
    for category in asset_pack:
        if category == "meta":
            continue
        
        var category_data = asset_pack[category]
        if not category_data is Dictionary:
            continue
        
        if not "files" in category_data:
            continue
        
        var files = category_data["files"]
        if files is not Array:
            continue
        
        # Add each file to the resource list
        for file_info in files:
            if file_info is Dictionary:
                # Build resource entry with key and url
                var resource_entry: Dictionary = {
                    "url": file_info.get("url", ""),
                    "type": file_info.get("type", "auto"),
                    "key": file_info.get("key", ""),
                    "category": category
                }
                
                if resource_entry["url"] != "" and resource_entry["key"] != "":
                    if not resources_to_load.has(resource_entry["url"]):
                        resources_to_load[resource_entry["url"]] = resource_entry
    
    total_count = resources_to_load.size()
    if total_count > 0:
        print("Loaded %d resources from asset pack" % total_count)
    else:
        print("No resources defined in asset pack")

func start_loading() -> void:
    """Start loading all resources"""
    if resources_to_load.is_empty():
        _load_resources_from_json()
        _load_animation_frames_from_json()
    
    if resources_to_load.is_empty():
        # No resources to load - this is valid, just complete loading
        print("No resources to load in asset pack")
        loading_complete.emit()
        return
    
    loaded_count = 0
    failed_count = 0
    
    print("[LoadingManager] Starting to load %d resources..." % resources_to_load.size())
    
    # Connect to signals
    if not _loader.resource_loaded.is_connected(_on_resource_loaded):
        _loader.resource_loaded.connect(_on_resource_loaded)
    if not _loader.resource_load_failed.is_connected(_on_resource_failed):
        _loader.resource_load_failed.connect(_on_resource_failed)
    
    # Start loading all resources
    for dk in resources_to_load:
        var resource_info = resources_to_load[dk]
        var url: String = resource_info["url"]
        var type: String = resource_info["type"]
        var key: String = resource_info["key"]
        
        # Check if already cached
        if _loader.is_cached(key):
            _on_resource_loaded(key, _loader.get_cached_resource(key))
        else:
            print("[LoadingManager] 🔄 Starting to load: key=%s, type=%s, url=%s" % [key, type, url])
            _loader.load_resource(url, type, key)
    
    # Add a safety timeout - if loading takes more than 60 seconds, force complete
    _start_timeout_check()

func _on_resource_loaded(_key: String, _resource) -> void:
    loaded_count += 1
    print("[LoadingManager] Resource loaded: ", _key)
    _update_progress()

func _on_resource_failed(key: String, error: String) -> void:
    failed_count += 1
    print("[LoadingManager] ❌ Resource failed: ", key, " - Error: ", error)
    push_warning("Failed to load resource: " + key + " - " + error)
    _update_progress()

func _start_timeout_check() -> void:
    """Check if loading completes within 60 seconds, otherwise force complete"""
    await get_tree().create_timer(60.0).timeout
    
    var completed = loaded_count + failed_count
    if completed < total_count:
        print("[LoadingManager] ⚠️ Loading timeout! Forcing completion with %d/%d resources (%d failed)" % [completed, total_count, failed_count])
        loading_complete.emit()

func _update_progress() -> void:
    var completed = loaded_count + failed_count
    var percent = (float(completed) / float(total_count)) * 100.0
    
    loading_progress.emit(completed, total_count, percent)
    print("[LoadingManager] Progress: %d / %d (%.1f%%) - Loaded: %d, Failed: %d, Pending: %d" % [completed, total_count, percent, loaded_count, failed_count, total_count - completed])
    
    # Check if all resources are loaded
    if completed >= total_count:
        if failed_count > 0:
            push_warning("Loading completed with %d failed resources" % failed_count)
            print("[LoadingManager] ⚠️ Loading completed with %d failures" % failed_count)
        else:
            print("[LoadingManager] ✅ All resources loaded successfully!")
        
        # Wait a bit before completing to show 100%
        await get_tree().create_timer(0.5).timeout
        loading_complete.emit()

func get_progress() -> float:
    if total_count == 0:
        return 0.0
    return (float(loaded_count + failed_count) / float(total_count)) * 100.0

func _load_animation_frames_from_json() -> void:
    """Load animation frame resources from animations.json file"""
    
    # Load and parse the JSON file
    var file = FileAccess.open(animations_path, FileAccess.READ)
    if file == null:
        print("Animations file not found at: " + animations_path + " - no animation frames to load")
        return
    
    var json = JSON.new()
    var json_string = file.get_as_text()
    var error = json.parse(json_string)
    
    if error != OK:
        print("Failed to parse animations JSON at: " + animations_path)
        return
    
    var animations_data = json.data
    if animations_data is not Dictionary:
        print("Animations data is not a valid dictionary")
        return
    
    var frames_added = 0
    
    # Iterate through all characters/entities
    for character_name in animations_data:
        var character_data = animations_data[character_name]
        
        if not character_data is Dictionary:
            continue
        
        if not "anims" in character_data:
            continue
        
        var anims = character_data["anims"]
        if anims is not Array:
            continue
        
        # Iterate through all animations
        for anim in anims:
            if not anim is Dictionary:
                continue
            
            if not "frames" in anim:
                continue
            
            var frames = anim["frames"]
            if frames is not Array:
                continue
            
            # Add each frame to the resource list
            for frame in frames:
                if frame is Dictionary:
                    var frame_url = frame.get("url", "")
                    var frame_key = frame.get("key", "")
                    
                    if frame_url != "" and frame_key != "":
                        var resource_entry: Dictionary = {
                            "url": frame_url,
                            "type": "image",
                            "key": frame_key,
                            "category": "animations"
                        }
                        
                        if not resources_to_load.has(frame_url):
                            resources_to_load[frame_url] = resource_entry

                        frames_added += 1
    
    # Update total count
    total_count = resources_to_load.size()
    
    if frames_added > 0:
        print("Added %d animation frames from animations.json" % frames_added)
        print("Total resources to load: %d" % total_count)
    else:
        print("No animation frames found in animations.json")


extends Node
# Network Resource Loader - Load remote assets from URLs
# Access via autoload: NetworkResourceLoader

signal resource_loaded(key: String, resource)
signal resource_load_failed(key: String, error: String)
# Reserved for future use: track download progress
# signal download_progress(key: String, bytes_received: int, bytes_total: int)

# Cache for loaded resources - using key as identifier
var _resource_cache: Dictionary = {}
# Active download requests - mapping key to HTTPRequest
var _active_requests: Dictionary = {}
# Retry counter - mapping key to retry count
var _retry_counts: Dictionary = {}
# Maximum retry attempts
const MAX_RETRIES: int = 3

func _ready() -> void:
    print("[NetworkResourceLoader] ✓ Initialized and ready!")

# Load a resource from URL (image, audio, etc.)
func load_resource(url: String, resource_type: String = "auto", key: String = "") -> void:
    print("[NetworkResourceLoader] key: %s" % key)
    
    # Validate URL
    if url == "" or url.is_empty():
        _on_request_failed(key, url, resource_type, "Empty URL")
        return
    
    # Check if already cached
    if _resource_cache.has(key):
        print("[NetworkResourceLoader] ✓ Already cached: %s" % key)
        resource_loaded.emit(key, _resource_cache[key])
        return
    
    # Check if already downloading
    if _active_requests.has(key):
        print("[NetworkResourceLoader] ⚠️  Already downloading: %s (request is in progress)" % key)
        resource_load_failed.emit(key, "Failed to start request: Already downloading resource")
        return
    
    # Initialize retry count if not exists
    if not _retry_counts.has(key):
        _retry_counts[key] = 0
    
    # Create HTTP request
    var http_request := HTTPRequest.new()
    add_child(http_request)
    
    # Connect signals
    http_request.request_completed.connect(_on_request_completed.bind(url, resource_type, key))
    
    # Store request
    _active_requests[key] = http_request
    
    # Start download
    var retry_info = ""
    if _retry_counts[key] > 0:
        retry_info = " (Retry %d/%d)" % [_retry_counts[key], MAX_RETRIES]
    print("[NetworkResourceLoader] 🔄 Starting load: key=%s, url=%s%s" % [key, url, retry_info])
    
    var error = http_request.request(url)
    if error != OK:
        _on_request_failed(key, url, resource_type, "Failed to start request: " + str(error))
        print("[NetworkResourceLoader] ❌ Failed to start: %s - Error: %s" % [key, error])
    

# Load multiple resources at once
func load_resources(urls: Array[String], resource_type: String = "auto") -> void:
    for url in urls:
        load_resource(url, resource_type)

# Get cached resource
func get_cached_resource(key: String):
    return _resource_cache.get(key)

# Check if resource is cached
func is_cached(key: String) -> bool:
    return _resource_cache.has(key)

# Clear cache
func clear_cache() -> void:
    _resource_cache.clear()
    _retry_counts.clear()
    _clear_font_cache()

# Clear specific resource from cache
func clear_resource(key: String) -> void:
    _resource_cache.erase(key)
    _retry_counts.erase(key)

# Clear all cached font files from user:// directory
func _clear_font_cache() -> void:
    var dir = DirAccess.open("user://")
    if dir:
        dir.list_dir_begin()
        var filename = dir.get_next()
        while filename != "":
            if filename.begins_with("font_cache_"):
                dir.remove(filename)
                print("[NetworkResourceLoader] Cleared font cache: %s" % filename)
            filename = dir.get_next()
        dir.list_dir_end()

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, url: String, resource_type: String, key: String) -> void:
    # Remove from active requests
    var http_request = _active_requests.get(key)
    _active_requests.erase(key)
    
    print("[NetworkResourceLoader] Response: key=%s, result=%d, code=%d, size=%d bytes" % [key, result, response_code, body.size()])
    
    if result != HTTPRequest.RESULT_SUCCESS:
        print("[NetworkResourceLoader] ❌ Request failed (result=%d): %s from %s" % [result, key, url])
        _on_request_failed(key, url, resource_type, "Request failed with result: " + str(result))
        if http_request:
            http_request.queue_free()
        return
    
    if response_code != 200:
        print("[NetworkResourceLoader] ❌ HTTP error (%d): %s from %s" % [response_code, key, url])
        _on_request_failed(key, url, resource_type, "HTTP error: " + str(response_code))
        if http_request:
            http_request.queue_free()
        return
    
    # Process the downloaded data based on resource type
    var resource = _process_downloaded_data(body, url, resource_type, headers)
    
    if resource:
        # Cache the resource using key
        _resource_cache[key] = resource
        # Reset retry count on success
        _retry_counts.erase(key)
        print("[NetworkResourceLoader] ✅ Successfully loaded: %s from %s" % [key, url])
        resource_loaded.emit(key, resource)
    else:
        print("[NetworkResourceLoader] ❌ Failed to process data: %s from %s" % [key, url])
        _on_request_failed(key, url, resource_type, "Failed to process downloaded data")
    
    if http_request:
        http_request.queue_free()

func _process_downloaded_data(data: PackedByteArray, url: String, resource_type: String, headers: PackedStringArray):
    # Auto-detect type from URL or content-type header
    if resource_type == "auto":
        resource_type = _detect_resource_type(url, headers)
    
    match resource_type:
        "image":
            return _load_image(data, url)
        "audio":
            return _load_audio(data, url)
        "font":
            return _load_font(data, url)
        "json", "tilemapTiledJSON":
            return _load_json(data)
        _:
            push_error("Unknown resource type: " + resource_type)
            return null

func _detect_resource_type(url: String, headers: PackedStringArray) -> String:
    # Check URL extension
    var url_lower = url.to_lower()
    if url_lower.ends_with(".png") or url_lower.ends_with(".jpg") or url_lower.ends_with(".jpeg") or url_lower.ends_with(".webp"):
        return "image"
    elif url_lower.ends_with(".mp3") or url_lower.ends_with(".ogg") or url_lower.ends_with(".wav"):
        return "audio"
    elif url_lower.ends_with(".json"):
        return "json"
    elif url_lower.ends_with(".ttf") or url_lower.ends_with(".otf") or url_lower.ends_with(".woff") or url_lower.ends_with(".woff2"):
        return "font"
    
    # Check content-type header
    for header in headers:
        if header.to_lower().begins_with("content-type:"):
            var content_type = header.split(":")[1].strip_edges().to_lower()
            if content_type.begins_with("image/"):
                return "image"
            elif content_type.begins_with("audio/"):
                return "audio"
            elif content_type.contains("json"):
                return "json"
            elif content_type.contains("font"):
                return "font"
    
    return "unknown"

func _load_image(data: PackedByteArray, url: String) -> Texture2D:
    var image := Image.new()
    var error: int
    
    # Try to load based on format
    var url_lower = url.to_lower()
    if url_lower.ends_with(".png"):
        error = image.load_png_from_buffer(data)
    elif url_lower.ends_with(".jpg") or url_lower.ends_with(".jpeg"):
        error = image.load_jpg_from_buffer(data)
    elif url_lower.ends_with(".webp"):
        error = image.load_webp_from_buffer(data)
    else:
        # Try all formats
        error = image.load_png_from_buffer(data)
        if error != OK:
            error = image.load_jpg_from_buffer(data)
        if error != OK:
            error = image.load_webp_from_buffer(data)
    
    if error != OK:
        push_error("Failed to load image from URL: " + url)
        return null
    
    return ImageTexture.create_from_image(image)

func _load_audio(data: PackedByteArray, url: String) -> AudioStream:
    var url_lower = url.to_lower()
    
    if url_lower.ends_with(".ogg"):
        var stream := AudioStreamOggVorbis.new()
        stream.packet_sequence = OggPacketSequence.new()
        stream.packet_sequence.packet_data = data
        return stream
    elif url_lower.ends_with(".mp3"):
        var stream := AudioStreamMP3.new()
        stream.data = data
        return stream
    elif url_lower.ends_with(".wav"):
        # WAV loading is more complex, need to parse the format
        return _load_wav(data)
    
    push_error("Unsupported audio format: " + url)
    return null

func _load_wav(data: PackedByteArray) -> AudioStreamWAV:
    # Basic WAV parser
    var stream := AudioStreamWAV.new()
    stream.data = data
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = 44100
    stream.stereo = true
    return stream

func _load_json(data: PackedByteArray) -> String:
    # Return JSON as string for flexible parsing
    var json_string = data.get_string_from_utf8()
    return json_string

func _load_font(data: PackedByteArray, url: String) -> FontFile:
    # Godot 4.x requires fonts to be loaded from file system
    # We write to user:// virtual file system first, then load
    
    # Extract font filename from URL
    var url_parts = url.split("/")
    var filename = url_parts[url_parts.size() - 1]
    
    # Ensure we have a valid extension
    if not (filename.ends_with(".ttf") or filename.ends_with(".otf") or \
            filename.ends_with(".woff") or filename.ends_with(".woff2")):
        filename = filename + ".ttf"
    
    # Create cache path in user:// directory
    var cache_path = "user://font_cache_%s" % filename
    
    # Write font data to virtual file system
    var file = FileAccess.open(cache_path, FileAccess.WRITE)
    if file == null:
        push_error("Failed to write font file to: " + cache_path)
        return null
    
    file.store_buffer(data)
    file.close()
    
    # Load font from the cached file
    var font := FontFile.new()
    var error = font.load_dynamic_font(cache_path)
    
    if error != OK:
        # Fallback: try setting data directly (works in some Godot versions)
        font.data = data
    
    # Set antialiasing for better rendering
    font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
    font.generate_mipmaps = true
    
    print("[NetworkResourceLoader] ✓ Font loaded successfully from: %s (cached at: %s)" % [url, cache_path])
    return font

func _on_request_failed(key: String, url: String, resource_type: String, error_msg: String) -> void:
    # Increment retry count
    if not _retry_counts.has(key):
        _retry_counts[key] = 0
    _retry_counts[key] += 1
    
    # Check if we should retry
    if _retry_counts[key] <= MAX_RETRIES:
        print("[NetworkResourceLoader] ⚠️  Load failed for %s: %s - Retrying (%d/%d)..." % [key, error_msg, _retry_counts[key], MAX_RETRIES])
        
        # Clean up request if it exists
        if _active_requests.has(key):
            var request = _active_requests[key]
            _active_requests.erase(key)
            request.queue_free()
        
        # Wait a bit before retrying (exponential backoff)
        var wait_time = 0.5 * pow(2, _retry_counts[key] - 1)  # 0.5s, 1s, 2s
        await get_tree().create_timer(wait_time).timeout
        
        # Retry the request
        load_resource(url, resource_type, key)
    else:
        # Max retries reached, emit failure signal
        print("[NetworkResourceLoader] ❌ Failed to load resource %s after %d attempts: %s" % [key, MAX_RETRIES, error_msg])
        push_error("Failed to load resource " + key + " after " + str(MAX_RETRIES) + " retries: " + error_msg)
        resource_load_failed.emit(key, error_msg)
        
        # Clean up
        _retry_counts.erase(key)
        if _active_requests.has(key):
            var request = _active_requests[key]
            _active_requests.erase(key)
            request.queue_free()


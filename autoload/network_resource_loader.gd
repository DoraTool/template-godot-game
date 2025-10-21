extends Node
# Network Resource Loader - Load remote assets from URLs
# Access via autoload: NetworkResourceLoader

signal resource_loaded(key: String, resource)
signal resource_load_failed(key: String, error: String)
signal download_progress(key: String, bytes_received: int, bytes_total: int)

# Cache for loaded resources - using key as identifier
var _resource_cache: Dictionary = {}
# Active download requests - mapping key to HTTPRequest
var _active_requests: Dictionary = {}
# Temporary storage path
var _cache_dir: String = "user://cache/"
# Request timeout in seconds
var _request_timeout: float = 10.0
# Track request start times for timeout checking
var _request_start_times: Dictionary = {}

func _ready() -> void:
	# Create cache directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(_cache_dir):
		DirAccess.make_dir_recursive_absolute(_cache_dir)
	
	print("[NetworkResourceLoader] ✓ Initialized and ready!")

# Process to check for timeouts
func _process(_delta: float) -> void:
	var current_time = Time.get_ticks_msec()
	var timeout_ms = int(_request_timeout * 1000)
	var timed_out_keys = []
	
	# Check for timed out requests
	for key in _request_start_times.keys():
		if _active_requests.has(key):
			var elapsed = current_time - _request_start_times[key]
			if elapsed > timeout_ms:
				timed_out_keys.append(key)
	
	# Handle timed out requests
	for key in timed_out_keys:
		print("[NetworkResourceLoader] ⏱️ Request timeout: %s" % key)
		_on_request_failed(key, "Request timeout after %.1f seconds" % _request_timeout)
		var http_request = _active_requests.get(key)
		if http_request:
			http_request.queue_free()
		_active_requests.erase(key)
		_request_start_times.erase(key)

# Load a resource from URL (image, audio, etc.)
func load_resource(url: String, resource_type: String = "auto", key: String = "") -> void:
	# Use URL as key if no key provided
	if key == "":
		key = url
	
	# Validate URL
	if url == "" or url.is_empty():
		_on_request_failed(key, "Empty URL")
		return
	
	# Check if already cached
	if _resource_cache.has(key):
		print("[NetworkResourceLoader] ✓ Already cached: %s" % key)
		resource_loaded.emit(key, _resource_cache[key])
		return
	
	# Check if already downloading
	if _active_requests.has(key):
		print("[NetworkResourceLoader] ⚠️  Already downloading: %s (request is in progress)" % key)
		return
	
	# Create HTTP request
	var http_request := HTTPRequest.new()
	add_child(http_request)
	
	# Connect signals
	http_request.request_completed.connect(_on_request_completed.bind(url, resource_type, key))
	
	# Store request
	_active_requests[key] = http_request
	
	# Start download
	print("[NetworkResourceLoader] 🔄 Starting load: key=%s, url=%s" % [key, url])
	var error = http_request.request(url)
	if error != OK:
		_on_request_failed(key, "Failed to start request: " + str(error))
		print("[NetworkResourceLoader] ❌ Failed to start: %s - Error: %s" % [key, error])
	
	# Track request start time for timeout checking
	_request_start_times[key] = Time.get_ticks_msec()

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

# Clear specific resource from cache
func clear_resource(key: String) -> void:
	_resource_cache.erase(key)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, url: String, resource_type: String, key: String) -> void:
	# Remove from active requests
	var http_request = _active_requests.get(key)
	_active_requests.erase(key)
	_request_start_times.erase(key)
	
	print("[NetworkResourceLoader] Response: key=%s, result=%d, code=%d, size=%d bytes" % [key, result, response_code, body.size()])
	
	if result != HTTPRequest.RESULT_SUCCESS:
		print("[NetworkResourceLoader] ❌ Request failed (result=%d): %s from %s" % [result, key, url])
		_on_request_failed(key, "Request failed with result: " + str(result))
		if http_request:
			http_request.queue_free()
		return
	
	if response_code != 200:
		print("[NetworkResourceLoader] ❌ HTTP error (%d): %s from %s" % [response_code, key, url])
		_on_request_failed(key, "HTTP error: " + str(response_code))
		if http_request:
			http_request.queue_free()
		return
	
	# Process the downloaded data based on resource type
	var resource = _process_downloaded_data(body, url, resource_type, headers)
	
	if resource:
		# Cache the resource using key
		_resource_cache[key] = resource
		print("[NetworkResourceLoader] ✅ Successfully loaded: %s from %s" % [key, url])
		resource_loaded.emit(key, resource)
	else:
		print("[NetworkResourceLoader] ❌ Failed to process data: %s from %s" % [key, url])
		_on_request_failed(key, "Failed to process downloaded data")
	
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
			# Fonts are typically handled by Godot's built-in system
			# Return the raw data for now
			return data
		"json":
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

func _load_json(data: PackedByteArray) -> Dictionary:
	var json_string = data.get_string_from_utf8()
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		push_error("Failed to parse JSON")
		return {}
	
	return json.data

func _on_request_failed(key: String, error_msg: String) -> void:
	push_error("Failed to load resource " + key + ": " + error_msg)
	resource_load_failed.emit(key, error_msg)
	
	# Clean up request if it exists
	if _active_requests.has(key):
		var request = _active_requests[key]
		_active_requests.erase(key)
		request.queue_free()
	_request_start_times.erase(key)


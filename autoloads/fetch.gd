extends Node

#-------------------------------------------------#

const circle_mask = preload("res://textures/avatar_mask.png")

#-------------------------------------------------#

signal got_image_result(result)

#-------------------------------------------------#

var current_request = null
var pending_requests = []

#-------------------------------------------------#

func _ready():
	pass

func request(url, method = HTTPClient.METHOD_GET):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	pending_requests.append(http_request)
	#if (current_request != null):
		#while (pending_requests.front() != http_request):
				#await current_request.request_completed
	
	http_request.request(url)
	current_request = http_request
	
	var res = await http_request.request_completed
	pending_requests.pop_front()
	if (pending_requests.size() == 0): current_request = null
	
	return {
		"result": res[0],
		"response_code": res[1],
		"headers": res[2],
		"body": res[3],
	}

var FORMAT_ROTATION = {
	"png": "jpg",
	"jpg": "webp",
	"webp": "png"
}

func request_image(url: String):
	#print("Fetching Image: ", url)
	var mime = url.split("?")[0].split(".")[-1]
	if (not FORMAT_ROTATION.keys().has(mime) and mime != "gif"): mime = "png"
	
	var res = await request(url)
	var result = {}
	
	var rot_count = 0
	var image = Image.new()
	var anim_text = null
	
	if (mime == "gif"):
		anim_text = GifManager.animated_texture_from_buffer(res.body, 1000)
		result = {"image": anim_text, "mime": "gif", "texture": anim_text}
	else:
		while (image.is_empty() and rot_count < 3):
			match mime:
				"jpg":
					image.load_jpg_from_buffer(res.body)
				"png":
					image.load_png_from_buffer(res.body)
				"webp":
					image.load_webp_from_buffer(res.body)
			
			rot_count += 1
			mime = FORMAT_ROTATION[mime]
		var image_text = ImageTexture.create_from_image(image)
		result = {"image": image, "mime": mime, "texture": image_text}
	
	got_image_result.emit(result)
	return result

func request_sound(url):
	var res = await request(url)
	var audio_stream = AudioStreamMP3.new()
	audio_stream.data = res.body
	return audio_stream

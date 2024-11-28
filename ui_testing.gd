extends Control

const URLs = [
	"https://i.imgur.com/Uc4i3uA.png",
	"https://file.garden/ZMStwW5nmTe-x3P5/itch-cover.gif",
	"https://s3.ezgif.com/tmp/ezgif-3-5c53325401.gif",
	"https://file.garden/ZMStwW5nmTe-x3P5/lolBATBATBATBATB.gif",
	"https://file.garden/ZMStwW5nmTe-x3P5/fred.png",
	"https://file.garden/ZMStwW5nmTe-x3P5/blutoidle_outline.gif",
	"https://file.garden/ZMStwW5nmTe-x3P5/bro%20is%20scared.gif",
	"https://file.garden/ZMStwW5nmTe-x3P5/Day35%20-%20NES%20Controller%20-%20%F0%9F%8E%AE.gif",
	"https://file.garden/ZMStwW5nmTe-x3P5/GET%20THAT%20NIGGA.gif",
]

func _ready():
	Fetch.got_image_result.connect(_got_result)
	for url in URLs:
		print("requesting...")
		Fetch.request_image(url)

func _got_result(result):
		print(result)
		var texture
		
		if (result.mime == "gif"):
			texture = result.image
		else:
			texture = ImageTexture.create_from_image(result.image)
		
		var texture_rect = TextureRect.new()
		texture_rect.texture = texture
		$ScrollContainer/HBoxContainer.add_child(texture_rect)

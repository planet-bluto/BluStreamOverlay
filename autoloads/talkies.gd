extends Node

#-------------------------------------------------#

const CUSTOMS = {
	"334039742205132800": "blu", # blu
	"1092635593332248586": "blu", # blu_2
	#"108259144611397632": "log", # sareth
	"497844474043432961": "salty", # salty
	"194955469897334784": "maidmage", # maidmage
	"412836292163010572": "subi", # subi
	"141323186259230721": "log", # log
	"383851442341019658": "karma", # karma
	# "754188427699945592": "log", # amy
	"148471246680621057": "debi", # devious
	"150398769651777538": "ans", # ans
	"284418122042310678": "soap", # soap
	"279777552858349579": "orko", # soap
	"312939153002332160": "pablo", # pablo
	"292487528177598464": "chubbs", # chubbs
	"165257526185689089": "merp", # merp
	"556520902020431872": "niko", # delta
	"334082720651149312": "makoni", # makoni
	"675902623836274709": "neithan", # neithan
	"168179594392764427": "nobody", # nobody
}

const RIFFS = {
	"1092635593332248586": "blu", # blu 2
	"141323186259230721": "log", # log
	"148471246680621057": "debi", # devious
	"383851442341019658": "karma", # karma
	"497844474043432961": "salty", # salty
	"150398769651777538": "ans", # ans
}

const TRANSFORMS = {
	"blu": {"scale": 1.2},
	"log": {"scale": 1.5},
	"ans": {"scale": 0.9},
	"subi": {"scale": 1.25},
	"pablo": {"scale": 1.8},
	"neithan": {"scale": 1.8},
	"makoni": {"scale": 2},
	"orko": {"scale": 1.2},
}

#-------------------------------------------------#

var TEXTURES = {}
var SOUNDS = {}

#-------------------------------------------------#

func _ready():
	for talky_name in CUSTOMS.values():
		TEXTURES[talky_name] = {
			"open": load("res://talking_indicators/%s_open.png" % talky_name),
			"closed": load("res://talking_indicators/%s_closed.png" % talky_name),
		}
	
	for riff in RIFFS.values():
		SOUNDS[riff] = load("res://sfx/riffs/%s.wav" % riff)

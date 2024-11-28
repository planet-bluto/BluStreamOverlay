extends Node

#-------------------------------------------------#

signal disconnected()

signal blubot_sentences(sentences)

signal current_ad_request( REQUEST_IND )
signal ad_request( REQUEST_IND, AD_ID )

signal voice_event(type, speaker)
signal voice_join_event(speakers)
signal voice_left_event()

signal omni_now_playing(event)
signal omni_progress(event)
signal omni_status(event)

signal spark_event(type, spark, timestamp, extras)

signal chat(author, text, platform, author_style, flags, icons)

signal shoutout(friend)

signal active_chat(chatters)

signal hourglass_start(state, duration, timestamp)
signal hourglass_end(oldState, newState)
signal hourglass_pause(remaining)

signal popup( req_id, popup_id)
signal get_popups( req_id )

signal end_screen_start( payload )

#-------------------------------------------------#

var _socket_peer = WebSocketPeer.new()
var connected = false

#-------------------------------------------------#

func _ready():
	_socket_peer.connect_to_url(Globals.WS_SERVER)

var tracked_omni_events = {}
func _track_omni_event(eventName, timestamp):
	if (not tracked_omni_events.has(eventName)): tracked_omni_events[eventName] = []
	tracked_omni_events[eventName].append(timestamp)
	
func _is_omni_event_tracked(eventName, timestamp):
	return (tracked_omni_events.has(eventName) and tracked_omni_events[eventName].has(timestamp))

var connect_timer = 0
func _process(delta):
	_socket_peer.poll()
	var state = _socket_peer.get_ready_state()
	
	match state:
		WebSocketPeer.STATE_CLOSING:
			connected = false
		WebSocketPeer.STATE_CLOSED:
			connected = false
			_socket_peer.connect_to_url(Globals.WS_SERVER)
		WebSocketPeer.STATE_OPEN:
			if (!connected):
				connected = true
				#print("Connected!")
			while _socket_peer.get_available_packet_count():
				var msg = _socket_peer.get_packet().get_string_from_utf8()
				var data: Dictionary = JSON.parse_string(msg)
				
				match data.type:
					"blubot_sentences":
						blubot_sentences.emit(data.args[0])
					"current_ad_request":
						current_ad_request.emit(data.args[0])
					"ad_request":
						ad_request.emit(data.args[0], data.args[1])
					"voice_event":
						voice_event.emit(data.args[0], data.args[1])
					"voice_join_event":
						voice_join_event.emit(data.args[0])
					"voice_left_event":
						voice_left_event.emit()
					"omni_event":
						if (not _is_omni_event_tracked(data.args[0], data.args[1].timestamp)):
							_track_omni_event(data.args[0], data.args[1].timestamp)
							match data.args[0]:
								"nowplaying":
									omni_now_playing.emit(data.args[1])
								"progress":
									omni_progress.emit(data.args[1])
								"status":
									omni_status.emit(data.args[1])
					"spark_event":
						var arg1 = data.args.pop_front()
						var arg2 = data.args.pop_front()
						var timestamp = round(Time.get_unix_time_from_system() * 1000.0)
						spark_event.emit(arg1, arg2, timestamp, data.args)
					"chat":
						chat.emit(data.args[0], data.args[1], data.args[2], data.args[3], data.args[4], data.args[5])
					"shoutout":
						shoutout.emit(data.args[0])
					"active_chat":
						active_chat.emit(data.args[0])
					"hourglass_start":
						hourglass_start.emit(data.args[0], data.args[1], data.args[2])
					"hourglass_ended":
						hourglass_end.emit(data.args[0], data.args[1])
					"hourglass_pause":
						hourglass_pause.emit(data.args[0])
					"spawn_popup":
						popup.emit(data.args[0], data.args[1])
					"get_popups":
						get_popups.emit(data.args[0])
					"end_screen_start":
						end_screen_start.emit(data.args[0])
	
	if (connected):
		if (connect_timer < 0):
			connect_timer = 1
			print("Connected!")
		else: 
			connect_timer += 1
	else:
		if (connect_timer > 0):
			connect_timer = -1
			print("Disconnected!")
			disconnected.emit()
		else: 
			connect_timer -= 1
	

func send(type, args):
	var msg = JSON.stringify({
		"type": type,
		"args": args,
	})
	
	_socket_peer.send_text(msg)

func send_debug(data):
	send("debug", [data])

func send_ad_response(req_ind, ad):
	send("ad_response", [req_ind, ad])

func send_popup_response(req_ind, success):
	send("popup_response", [req_ind, success])

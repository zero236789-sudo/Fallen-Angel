extends AudioStreamPlayer

func play_song(song: AudioStream) -> void:
	if stream == song and playing:
		return  # ya está sonando, no interrumpas
	stream = song
	play()

func stop_song() -> void:
	stop()

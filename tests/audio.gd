extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 print(("PASS: " if ok else "FAIL: ")+message)
 if not ok:failures+=1
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var audio=GameAudio.new();root.add_child(audio);await process_frame
 audio.play_music("menu")
 check(audio.music.stream is AudioStreamMP3,"provided MP3 is used in menu")
 check(absf(audio.music.stream.get_length()-169.344)<0.2,"complete uploaded song is decoded")
 check(audio.music.stream.loop and audio.music.stream.loop_offset==0,"background song loops")
 var stream=audio.music.stream
 audio.music.seek(22.0)
 var playback=audio.music.get_stream_playback()
 audio.play_music("battle")
 check(audio.music.stream==stream and audio.music.get_stream_playback()==playback,"battle continues existing background playback")
 audio.play_music("boss")
 check(audio.music.stream==stream and audio.music.get_stream_playback()==playback,"boss does not restart song")
 var sfx=audio.effects_volume
 audio.music_volume=0
 audio.play_music("boss")
 check(audio.music.stream_paused and audio.effects_volume==sfx,"music mute is complete and independent of SFX")
 audio.music_volume=0.7
 audio.play_music("menu")
 check(not audio.music.stream_paused and audio.music.get_stream_playback()==playback,"unmute and settings preserve playback")
 check(absf(audio.music.volume_db-linear_to_db(0.7*0.35))<0.01,"music volume follows dedicated slider")
 audio.play_music("victory")
 check(audio.music.stream is AudioStreamWAV,"victory music retained")
 audio.play_music("defeat")
 check(audio.music.stream is AudioStreamWAV,"defeat music retained")
 audio.play_music("menu")
 check(audio.music.stream is AudioStreamMP3,"background song restored when returning to menu")
 audio.queue_free();await process_frame;OS.delay_msec(150);await process_frame
 print("AUDIO RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)

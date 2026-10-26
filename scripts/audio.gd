class_name GameAudio
extends Node
var effects: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var track := ""
var current_music_path := ""
const SURVIVAL_MUSIC = "res://assets/audio/endless_survival.mp3"
var music_volume := 0.45
var effects_volume := 0.65
func _ready() -> void:
 for i in range(10):
  var player := AudioStreamPlayer.new()
  add_child(player)
  effects.append(player)
 music=AudioStreamPlayer.new()
 add_child(music)
 music.finished.connect(func(): music.play())
func play_effect(name: String,pitch: float=1.0) -> void:
 if effects_volume<=0:
  return
 for player in effects:
  if not player.playing:
   player.stream=load("res://assets/audio/"+name+".wav")
   player.pitch_scale=pitch
   player.volume_db=linear_to_db(effects_volume*0.45)
   player.play()
   return
func play_music(name: String) -> void:
 var path=SURVIVAL_MUSIC if name in ["menu","battle","boss"] else "res://assets/audio/"+name+".wav"
 track=name
 if current_music_path!=path:
  current_music_path=path
  var stream=load(path)
  if stream is AudioStreamMP3:
   stream.loop=true
   stream.loop_offset=0.0
  music.stream=stream
  music.play()
 # Context and volume changes must not restart the same background song.
 music.stream_paused=music_volume<=0
 music.volume_db=-80.0 if music_volume<=0 else linear_to_db(music_volume*0.35)

func _exit_tree() -> void:
 if is_instance_valid(music):
  music.stop()
  music.stream=null
 for player in effects:
  player.stop()
  player.stream=null

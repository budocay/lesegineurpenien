extends SceneTree
## Outil : écrit chaque son généré de src/core/sfx.gd en .wav dans le dossier donné (pour mesurer
## durée et niveau avant de remplacer un son par un fichier).
##   Godot --headless --path . -s tests/_dump_sfx.gd -- <dossier>
var _done := false

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	var out := OS.get_cmdline_user_args()[0]
	var sfx: Node = root.get_node("Sfx")
	for id: String in sfx._streams:
		(sfx._streams[id] as AudioStreamWAV).save_to_wav("%s/%s.wav" % [out, id])
	print("SONS OK : %d" % sfx._streams.size())
	return true

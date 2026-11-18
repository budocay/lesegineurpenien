extends SceneTree
## Outil : calcule chaque morceau de data/music.json et l'écrit en .wav dans le dossier
## donné, pour l'écouter sans lancer le jeu. Affiche la durée et le temps de calcul.
##   Godot --headless --path . -s tests/_dump_music.gd -- <dossier>
var _done := false

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	var out := OS.get_cmdline_user_args()[0]
	var db: Node = root.get_node("Database")
	var music: Node = root.get_node("Music")
	for id: String in db.music:
		var t0 := Time.get_ticks_msec()
		var bytes: PackedByteArray = music.render(db.music[id])
		var ms := Time.get_ticks_msec() - t0
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = music.RATE
		wav.data = bytes
		wav.save_to_wav("%s/%s.wav" % [out, id])
		# part du temps passée près du maximum : un son saturé ou écrasé se voit ici
		var loud := 0
		var sum := 0.0
		var count := 0
		for i in range(0, bytes.size() - 1, 20):
			var v := absi(bytes.decode_s16(i))
			sum += float(v) * float(v)
			count += 1
			if v > 26000:
				loud += 1
		print("%s : %.1f s, calcul %d ms, niveau moyen %d, crêtes %.2f %%" % [id, bytes.size() / 2.0 / music.RATE, ms, int(sqrt(sum / maxi(1, count))), 100.0 * loud / maxi(1, count)])
	print("MUSIQUES OK")
	return true

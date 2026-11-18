extends RefCounted
## Mesure, sur la vraie caméra et les vrais pixels, la part de chaque combattant qui reste
## visible malgré ceux qui se tiennent devant lui. Sert au test automatique et aux réglages.

const STEP := 1
const CELL := 3.0   # taille d'une cellule de comparaison, en pixels d'écran


## Renvoie {clé du combattant: part visible entre 0 et 1}.
static func fractions(scene: Node3D) -> Dictionary:
	var cam: Camera3D = scene.camera
	var layers: Array = []
	for key: Variant in scene.actors:
		var a: Node3D = scene.actors[key]
		if a.down or not a.visible:
			continue
		layers.append(_layer(a, cam, str(key)))
	# du plus loin au plus près de la caméra
	layers.sort_custom(func(p: Dictionary, q: Dictionary) -> bool: return p["dist"] > q["dist"])
	var out := {}
	for i in layers.size():
		var mine: Dictionary = layers[i]
		var cells: Dictionary = mine["cells"]
		var seen := 0
		for cell: Vector2i in cells:
			var hidden := false
			for j in range(i + 1, layers.size()):
				if (layers[j]["cells"] as Dictionary).has(cell):
					hidden = true
					break
			if not hidden:
				seen += 1
		out[mine["key"]] = float(seen) / maxf(1.0, float(cells.size()))
	return out


static func _layer(a: Node3D, cam: Camera3D, key: String) -> Dictionary:
	var quad: MeshInstance3D = a._quad
	var size: Vector2 = (quad.mesh as QuadMesh).size
	var xf: Transform3D = quad.global_transform
	var tl := cam.unproject_position(xf * Vector3(-size.x * 0.5, size.y * 0.5, 0.0))
	var tr := cam.unproject_position(xf * Vector3(size.x * 0.5, size.y * 0.5, 0.0))
	var bl := cam.unproject_position(xf * Vector3(-size.x * 0.5, -size.y * 0.5, 0.0))
	var img: Image
	var rect := Vector4(0.0, 0.0, 1.0, 1.0)
	var tex: Texture2D = (quad.material_override as ShaderMaterial).get_shader_parameter("albedo_tex") if quad.material_override is ShaderMaterial else null
	var sheet: Dictionary = a._char.sheet if a._char != null else a._sheet
	img = sheet["image"]
	var fr: Variant = quad.get_instance_shader_parameter("frame_rect")
	if fr is Vector4:
		rect = fr
	var cells := {}
	var iw := img.get_width()
	var ih := img.get_height()
	var u0 := rect.x
	var du := rect.z
	var v0 := rect.y
	var dv := rect.w
	var fw := int(absf(du) * iw)
	var fh := int(absf(dv) * ih)
	for py in range(0, fh, STEP):
		for px in range(0, fw, STEP):
			# pixel (px, py) de la case affichée ; case retournée si du < 0
			var sx := int(u0 * iw) + (px if du > 0.0 else -px - 1)
			var sy := int(v0 * ih) + py
			if sx < 0 or sx >= iw or sy < 0 or sy >= ih:
				continue
			if img.get_pixel(sx, sy).a < 0.5:
				continue
			var p := tl + (tr - tl) * ((float(px) + 0.5) / float(fw)) + (bl - tl) * ((float(py) + 0.5) / float(fh))
			var hw := absf(tr.x - tl.x) / float(fw) * 0.5
			var hh := absf(bl.y - tl.y) / float(fh) * 0.5
			for cy in range(int((p.y - hh) / CELL), int((p.y + hh) / CELL) + 1):
				for cx in range(int((p.x - hw) / CELL), int((p.x + hw) / CELL) + 1):
					cells[Vector2i(cx, cy)] = true
	return {"key": key, "dist": cam.global_position.distance_to(a.global_position), "cells": cells}

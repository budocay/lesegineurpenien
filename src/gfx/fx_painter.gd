extends RefCounted
## Petits sprites d'effets de combat (16 x 16 px), peints par code : projectiles,
## armes, symboles d'états, fumées. On y accède par Sprites.fx(nom), qui préfère un
## fichier assets/sprites/fx/<nom>.png s'il existe.

const PA = preload("res://src/gfx/pixel_art.gd")

const SIZE := 16

const KINDS := [
	"spark", "flame", "star", "bolt", "leaf", "zzz", "note", "pan", "ladle", "knife", "sickle",
	"sword", "arrow", "axe", "staff", "bottle", "mug", "smoke", "bubble", "drop", "ring", "slash",
	"impact", "plus", "shield", "skull", "coin", "pillow", "feather", "rocket", "eye", "bang",
	"bowl", "bread", "cloud", "root", "stinger", "tusk", "tongue", "fork", "pot", "lid", "scroll",
	"crown", "heart", "up", "down", "dizzy", "slime", "spore", "fang", "hoof", "wave", "finger",
	"band", "mouth", "dust", "petard", "hand", "straw", "web", "pix",
]

const WHITE := Color("#ffffff")
const STEEL := Color("#cfd8ea")
const STEEL_D := Color("#8a94ac")
const WOOD := Color("#8a5a34")
const WOOD_D := Color("#5a3a24")
const IRON := Color("#3a3a46")
const IRON_L := Color("#6a6a7a")
const GOLD := Color("#f2c84a")
const GOLD_D := Color("#b8862a")
const FIRE := Color("#ff8a2a")
const FIRE_L := Color("#ffe27a")
const FIRE_D := Color("#d8402a")
const GREEN := Color("#7ac85a")
const GREEN_D := Color("#3f7a3a")
const PURPLE := Color("#b89cf0")
const PURPLE_D := Color("#6a4aa8")
const RED := Color("#e04a4a")
const PINK := Color("#f08aa0")
const CREAM := Color("#f4ecd8")
const BROWN := Color("#b0733a")
const BLUE := Color("#8ab8ff")
const SLIME := Color("#a6d85a")
const GREY := Color("#c8c8d2")
const GREY_D := Color("#8a8a98")


static func has(kind: String) -> bool:
	return KINDS.has(kind)


static func paint(kind: String) -> Image:
	var img := PA.new_image(SIZE, SIZE)
	var edge := true
	match kind:
		"pix":
			PA.rect(img, 6, 6, 4, 4, WHITE)
			edge = false
		"spark":
			# étoile pleine à quatre branches (des traits fins deviennent un damier, agrandis)
			for d in 7:
				var half := maxi(1, 3 - d / 2)
				PA.rect(img, 8 - half, 1 + d, half * 2, 1, FIRE)
				PA.rect(img, 8 - half, 14 - d, half * 2, 1, FIRE)
				PA.rect(img, 1 + d, 8 - half, 1, half * 2, FIRE)
				PA.rect(img, 14 - d, 8 - half, 1, half * 2, FIRE)
			PA.rect(img, 5, 5, 6, 6, FIRE_L)
			PA.rect(img, 6, 6, 4, 4, WHITE)
			edge = false
		"flame":
			PA.ellipse(img, 8.0, 10.0, 4.5, 4.5, FIRE_D)
			PA.ellipse(img, 8.0, 10.5, 3.2, 3.5, FIRE)
			PA.ellipse(img, 8.0, 11.5, 1.8, 2.2, FIRE_L)
			for y in range(2, 7):
				PA.rect(img, 8 - (y - 1) / 2, y, maxi(1, y - 1), 1, FIRE_D if y < 4 else FIRE)
			PA.px(img, 5, 5, FIRE_D)
			PA.px(img, 11, 4, FIRE)
		"star":
			PA.line(img, 8, 1, 8, 14, GOLD)
			PA.line(img, 1, 7, 14, 7, GOLD)
			PA.rect(img, 6, 5, 4, 5, GOLD)
			PA.rect(img, 5, 6, 6, 3, GOLD)
			PA.rect(img, 7, 6, 2, 3, FIRE_L)
			PA.line(img, 4, 3, 11, 11, GOLD_D)
			PA.line(img, 11, 3, 4, 11, GOLD_D)
			PA.rect(img, 6, 5, 4, 5, GOLD)
			PA.rect(img, 7, 6, 2, 3, WHITE)
		"bolt":
			PA.line(img, 10, 0, 6, 6, FIRE_L)
			PA.line(img, 11, 0, 7, 6, FIRE_L)
			PA.line(img, 6, 6, 10, 7, FIRE_L)
			PA.line(img, 10, 7, 5, 15, FIRE_L)
			PA.line(img, 11, 7, 6, 15, WHITE)
			PA.line(img, 9, 1, 6, 6, WHITE)
		"leaf":
			PA.ellipse(img, 8.0, 8.0, 3.2, 5.5, GREEN)
			PA.ellipse(img, 7.2, 7.4, 1.6, 3.8, GREEN.lightened(0.25))
			PA.line(img, 8, 3, 8, 14, GREEN_D)
			PA.px(img, 8, 14, WOOD_D)
		"zzz":
			# un grand Z épais et un petit : lisibles même de loin
			PA.rect(img, 1, 5, 9, 2, WHITE)
			PA.rect(img, 1, 13, 9, 2, WHITE)
			for d in 6:
				PA.rect(img, 7 - d, 7 + d, 3, 1, WHITE)
			PA.rect(img, 11, 1, 4, 1, PURPLE)
			PA.rect(img, 11, 4, 4, 1, PURPLE)
			PA.px(img, 13, 2, PURPLE)
			PA.px(img, 12, 3, PURPLE)
		"note":
			PA.rect(img, 9, 2, 1, 9, WHITE)
			PA.rect(img, 10, 2, 3, 2, WHITE)
			PA.ellipse(img, 7.5, 11.5, 2.5, 2.0, WHITE)
		"pan":
			PA.ellipse(img, 6.5, 6.5, 5.5, 5.5, IRON)
			PA.ellipse(img, 6.5, 6.5, 4.0, 4.0, IRON_L.darkened(0.2))
			PA.ellipse(img, 5.5, 5.5, 1.6, 1.2, IRON_L)
			PA.line(img, 10, 10, 15, 15, WOOD)
			PA.line(img, 11, 10, 15, 14, WOOD_D)
		"ladle":
			PA.ellipse(img, 5.0, 11.0, 3.5, 3.0, STEEL_D)
			PA.ellipse(img, 5.0, 10.4, 2.4, 1.8, STEEL)
			PA.line(img, 7, 9, 13, 1, STEEL)
			PA.line(img, 8, 9, 14, 1, STEEL_D)
		"knife":
			PA.line(img, 3, 12, 11, 4, STEEL)
			PA.line(img, 4, 12, 12, 4, WHITE)
			PA.line(img, 4, 13, 12, 5, STEEL_D)
			PA.rect(img, 1, 12, 3, 3, WOOD)
			PA.px(img, 13, 3, WHITE)
		"sickle":
			for a in 11:
				var ang := -0.4 + a * 0.32
				PA.px(img, int(round(8.0 + cos(ang) * 5.5)), int(round(7.0 - sin(ang) * 5.5)), STEEL)
				PA.px(img, int(round(8.0 + cos(ang) * 4.5)), int(round(7.0 - sin(ang) * 4.5)), WHITE)
			PA.line(img, 12, 9, 14, 15, WOOD)
			PA.line(img, 13, 9, 15, 15, WOOD_D)
		"sword":
			PA.line(img, 4, 11, 13, 2, STEEL)
			PA.line(img, 5, 11, 14, 2, WHITE)
			PA.line(img, 5, 12, 14, 3, STEEL_D)
			PA.line(img, 2, 9, 7, 14, GOLD)
			PA.line(img, 1, 14, 3, 12, WOOD_D)
			PA.px(img, 1, 15, GOLD_D)
		"arrow":
			PA.line(img, 1, 8, 12, 8, WOOD)
			PA.rect(img, 12, 6, 1, 5, STEEL)
			PA.rect(img, 13, 7, 1, 3, STEEL)
			PA.px(img, 14, 8, WHITE)
			PA.line(img, 1, 6, 3, 8, CREAM)
			PA.line(img, 1, 10, 3, 8, CREAM)
		"axe":
			PA.line(img, 3, 14, 11, 3, WOOD)
			PA.line(img, 4, 14, 12, 3, WOOD_D)
			PA.ellipse(img, 11.0, 5.0, 4.0, 3.6, STEEL_D)
			PA.ellipse(img, 12.0, 4.5, 2.8, 2.6, STEEL)
			PA.rect(img, 13, 3, 2, 2, WHITE)
		"staff":
			PA.line(img, 3, 15, 11, 3, WOOD)
			PA.line(img, 4, 15, 12, 3, WOOD_D)
			PA.ellipse(img, 12.0, 3.0, 2.4, 2.4, WOOD)
			PA.px(img, 12, 2, CREAM)
		"bottle":
			PA.rect(img, 5, 6, 6, 9, GREEN_D)
			PA.rect(img, 6, 8, 4, 6, SLIME)
			PA.rect(img, 7, 2, 2, 4, GREEN_D)
			PA.rect(img, 7, 1, 2, 1, WOOD)
			PA.px(img, 6, 7, WHITE)
		"mug":
			PA.rect(img, 3, 5, 8, 9, WOOD)
			PA.rect(img, 4, 6, 6, 7, BROWN)
			PA.rect(img, 3, 3, 8, 3, CREAM)
			PA.px(img, 5, 2, CREAM)
			PA.px(img, 8, 2, CREAM)
			PA.rect(img, 11, 7, 2, 1, WOOD)
			PA.rect(img, 13, 8, 1, 3, WOOD)
			PA.rect(img, 11, 11, 2, 1, WOOD)
		"smoke":
			PA.ellipse(img, 6.0, 9.0, 4.5, 4.0, GREY)
			PA.ellipse(img, 10.0, 7.0, 4.0, 3.6, GREY)
			PA.ellipse(img, 9.0, 11.0, 3.6, 3.0, GREY_D)
			PA.ellipse(img, 6.0, 7.5, 2.4, 2.0, WHITE)
			edge = false
		"bubble":
			PA.ellipse(img, 8.0, 8.0, 5.5, 5.5, Color(SLIME.r, SLIME.g, SLIME.b, 1.0))
			PA.ellipse(img, 8.5, 8.5, 4.0, 4.0, SLIME.lightened(0.3))
			PA.rect(img, 5, 5, 2, 2, WHITE)
		"drop":
			PA.ellipse(img, 8.0, 10.0, 3.6, 4.0, BLUE)
			for y in range(2, 8):
				PA.rect(img, 8 - (y - 2) / 3, y, 1 + (y - 2) / 2, 1, BLUE)
			PA.px(img, 6, 10, WHITE)
		"ring":
			for a in 40:
				var ang := a * TAU / 40.0
				PA.px(img, int(round(7.5 + cos(ang) * 6.5)), int(round(7.5 + sin(ang) * 6.5)), WHITE)
			edge = false
		"slash":
			for a in 16:
				var ang := -0.9 + a * 0.12
				var r := 7.0
				PA.px(img, int(round(2.0 + cos(ang) * r * 1.6)), int(round(8.0 - sin(ang) * r)), WHITE)
				if a > 3 and a < 13:
					PA.px(img, int(round(1.0 + cos(ang) * r * 1.6)), int(round(8.0 - sin(ang) * r)), STEEL)
				if a > 5 and a < 11:
					PA.px(img, int(round(0.0 + cos(ang) * r * 1.6)), int(round(8.0 - sin(ang) * r)), STEEL)
			edge = false
		"impact":
			for a in 8:
				var ang := a * TAU / 8.0
				PA.line(img, int(round(7.5 + cos(ang) * 3.0)), int(round(7.5 + sin(ang) * 3.0)), int(round(7.5 + cos(ang) * 7.0)), int(round(7.5 + sin(ang) * 7.0)), FIRE_L if a % 2 == 0 else WHITE)
			PA.ellipse(img, 8.0, 8.0, 3.4, 3.4, FIRE)
			PA.ellipse(img, 8.0, 8.0, 2.2, 2.2, FIRE_L)
			PA.rect(img, 7, 7, 2, 2, WHITE)
			edge = false
		"plus":
			PA.rect(img, 6, 2, 4, 12, Color("#8af0a0"))
			PA.rect(img, 2, 6, 12, 4, Color("#8af0a0"))
			PA.rect(img, 7, 3, 2, 10, WHITE)
			PA.rect(img, 3, 7, 10, 2, WHITE)
		"shield":
			PA.rect(img, 3, 2, 10, 7, BLUE)
			for y in range(9, 15):
				PA.rect(img, 3 + (y - 8), y, 10 - 2 * (y - 8), 1, BLUE)
			PA.rect(img, 7, 3, 2, 9, WHITE)
			PA.rect(img, 4, 5, 8, 2, WHITE)
		"skull":
			PA.ellipse(img, 8.0, 7.0, 5.5, 5.0, SLIME)
			PA.rect(img, 5, 10, 6, 4, SLIME)
			PA.rect(img, 5, 6, 2, 3, GREEN_D)
			PA.rect(img, 9, 6, 2, 3, GREEN_D)
			PA.px(img, 8, 10, GREEN_D)
			PA.rect(img, 6, 13, 1, 1, GREEN_D)
			PA.rect(img, 9, 13, 1, 1, GREEN_D)
		"coin":
			PA.ellipse(img, 8.0, 8.0, 5.5, 5.5, GOLD_D)
			PA.ellipse(img, 8.0, 8.0, 4.2, 4.2, GOLD)
			PA.rect(img, 7, 5, 2, 6, GOLD_D)
			PA.px(img, 5, 5, WHITE)
		"pillow":
			PA.rect(img, 2, 5, 12, 8, CREAM)
			PA.rect(img, 3, 6, 10, 6, WHITE)
			PA.px(img, 1, 4, CREAM)
			PA.px(img, 14, 4, CREAM)
			PA.px(img, 1, 13, CREAM)
			PA.px(img, 14, 13, CREAM)
			PA.line(img, 5, 9, 10, 9, PURPLE)
		"feather":
			PA.line(img, 3, 13, 12, 3, GREY_D)
			PA.ellipse(img, 8.5, 7.0, 2.6, 5.0, WHITE)
			PA.line(img, 4, 12, 12, 3, GREY)
		"rocket":
			PA.rect(img, 6, 4, 4, 8, RED)
			PA.rect(img, 7, 5, 1, 6, PINK)
			PA.rect(img, 7, 2, 2, 2, GOLD)
			PA.px(img, 7, 1, GOLD)
			PA.rect(img, 5, 10, 1, 3, GOLD_D)
			PA.rect(img, 10, 10, 1, 3, GOLD_D)
			PA.rect(img, 7, 12, 2, 2, FIRE_L)
			PA.px(img, 8, 14, FIRE)
		"eye":
			PA.ellipse(img, 8.0, 8.0, 7.0, 4.0, FIRE_D)
			PA.ellipse(img, 8.0, 8.0, 5.5, 3.0, FIRE)
			PA.ellipse(img, 8.0, 8.0, 2.4, 3.0, FIRE_L)
			PA.rect(img, 7, 5, 2, 6, Color("#1b1425"))
		"bang":
			PA.rect(img, 6, 1, 4, 9, RED)
			PA.rect(img, 7, 2, 2, 7, PINK)
			PA.rect(img, 6, 12, 4, 3, RED)
		"bowl":
			PA.ellipse(img, 8.0, 9.0, 6.5, 5.0, WOOD)
			PA.rect(img, 1, 3, 14, 6, Color(0, 0, 0, 0))
			PA.ellipse(img, 8.0, 9.0, 6.5, 2.0, BROWN)
			PA.ellipse(img, 8.0, 9.0, 5.0, 1.2, FIRE_L.darkened(0.15))
			PA.px(img, 6, 5, WHITE)
			PA.px(img, 9, 4, WHITE)
			PA.px(img, 7, 3, WHITE)
		"bread":
			PA.ellipse(img, 8.0, 9.0, 6.5, 4.0, BROWN)
			PA.ellipse(img, 8.0, 8.0, 5.5, 2.6, BROWN.lightened(0.25))
			PA.line(img, 5, 7, 6, 9, WOOD_D)
			PA.line(img, 8, 6, 9, 9, WOOD_D)
			PA.line(img, 11, 7, 12, 9, WOOD_D)
		"cloud":
			PA.ellipse(img, 5.0, 9.0, 4.0, 3.5, GREY)
			PA.ellipse(img, 10.5, 9.0, 4.5, 3.8, GREY)
			PA.ellipse(img, 8.0, 6.5, 4.0, 3.4, WHITE)
			PA.rect(img, 3, 10, 11, 2, GREY)
			edge = false
		"root":
			PA.line(img, 8, 1, 8, 8, WOOD)
			PA.line(img, 7, 2, 7, 9, BROWN)
			PA.line(img, 8, 8, 4, 14, WOOD)
			PA.line(img, 8, 8, 12, 14, WOOD)
			PA.line(img, 8, 9, 8, 15, BROWN)
			PA.ellipse(img, 8.0, 2.0, 2.0, 1.4, GREEN)
		"stinger":
			for x in range(2, 14):
				var h := maxi(1, (14 - x) / 3)
				PA.rect(img, x, 8 - h / 2, 1, h, GOLD if x < 8 else IRON)
			PA.px(img, 14, 8, WHITE)
		"tusk":
			for a in 9:
				var ang := 0.2 + a * 0.3
				PA.px(img, int(round(5.0 + cos(ang) * 7.0)), int(round(13.0 - sin(ang) * 9.0)), CREAM)
				PA.px(img, int(round(5.0 + cos(ang) * 6.0)), int(round(13.0 - sin(ang) * 8.0)), WHITE)
			PA.rect(img, 10, 11, 3, 3, CREAM)
		"tongue":
			PA.rect(img, 0, 6, 12, 4, PINK)
			PA.rect(img, 0, 7, 11, 1, RED)
			PA.ellipse(img, 12.5, 8.0, 3.0, 3.0, PINK)
			PA.px(img, 13, 7, WHITE)
		"fork":
			PA.rect(img, 7, 6, 2, 10, STEEL_D)
			PA.rect(img, 4, 0, 1, 6, STEEL)
			PA.rect(img, 7, 0, 2, 6, STEEL)
			PA.rect(img, 11, 0, 1, 6, STEEL)
			PA.rect(img, 4, 5, 8, 2, STEEL)
		"pot":
			PA.ellipse(img, 8.0, 9.0, 6.0, 5.5, IRON)
			PA.rect(img, 2, 5, 12, 2, IRON_L)
			PA.rect(img, 0, 7, 2, 2, IRON_L)
			PA.rect(img, 14, 7, 2, 2, IRON_L)
			PA.px(img, 5, 9, IRON_L)
		"lid":
			PA.ellipse(img, 8.0, 9.0, 7.0, 4.0, IRON_L)
			PA.ellipse(img, 8.0, 8.0, 6.0, 2.6, STEEL_D)
			PA.rect(img, 7, 4, 2, 2, WOOD)
			PA.px(img, 5, 7, WHITE)
		"scroll":
			PA.rect(img, 3, 3, 10, 10, CREAM)
			PA.rect(img, 2, 2, 12, 2, CREAM.darkened(0.2))
			PA.rect(img, 2, 12, 12, 2, CREAM.darkened(0.2))
			for y in [6, 8, 10]:
				PA.rect(img, 5, y, 6, 1, WOOD_D)
			PA.ellipse(img, 11.0, 11.0, 1.6, 1.6, RED)
		"crown":
			PA.rect(img, 2, 8, 12, 5, GOLD)
			for x in [2, 7, 12]:
				PA.rect(img, x, 4, 2, 4, GOLD)
				PA.px(img, x, 3, FIRE_L)
			PA.rect(img, 2, 12, 12, 1, GOLD_D)
			PA.px(img, 5, 10, RED)
			PA.px(img, 10, 10, RED)
		"heart":
			PA.ellipse(img, 5.5, 6.0, 3.2, 3.2, RED)
			PA.ellipse(img, 10.5, 6.0, 3.2, 3.2, RED)
			for y in range(7, 14):
				PA.rect(img, 3 + (y - 7), y, 10 - 2 * (y - 7), 1, RED)
			PA.px(img, 5, 5, PINK)
		"up":
			for y in range(1, 8):
				PA.rect(img, 8 - y, y, y * 2, 1, GOLD)
			PA.rect(img, 6, 8, 4, 7, GOLD)
			PA.rect(img, 7, 3, 2, 11, FIRE_L)
		"down":
			for y in range(1, 8):
				PA.rect(img, 8 - y, 15 - y, y * 2, 1, Color("#d89a9a"))
			PA.rect(img, 6, 1, 4, 7, Color("#d89a9a"))
			PA.rect(img, 7, 2, 2, 11, Color("#f0c4c4"))
		"dizzy":
			var r := 0.5
			for a in 60:
				var ang := a * 0.3
				r += 0.11
				PA.px(img, int(round(7.5 + cos(ang) * r)), int(round(7.5 + sin(ang) * r)), GOLD if a % 3 != 0 else WHITE)
			edge = false
		"slime":
			PA.ellipse(img, 8.0, 9.0, 6.0, 4.5, SLIME)
			PA.ellipse(img, 6.5, 8.0, 3.0, 2.0, SLIME.lightened(0.3))
			PA.rect(img, 4, 12, 2, 3, SLIME)
			PA.rect(img, 10, 12, 2, 2, SLIME)
			PA.px(img, 5, 7, WHITE)
		"spore":
			PA.ellipse(img, 8.0, 8.0, 3.5, 3.5, PURPLE)
			PA.ellipse(img, 7.4, 7.4, 1.6, 1.6, WHITE)
			PA.px(img, 2, 4, PURPLE)
			PA.px(img, 13, 5, PURPLE)
			PA.px(img, 4, 13, PURPLE)
			PA.px(img, 12, 12, PURPLE)
		"fang":
			for x in [3, 9]:
				for y in range(2, 13):
					PA.rect(img, x + (y - 2) / 4, y, maxi(1, 4 - (y - 2) / 3), 1, CREAM)
			PA.rect(img, 2, 1, 12, 2, RED)
		"hoof":
			PA.ellipse(img, 8.0, 9.0, 5.5, 5.0, WOOD_D)
			PA.rect(img, 7, 4, 2, 6, Color(0, 0, 0, 0))
			PA.ellipse(img, 5.5, 8.0, 1.6, 2.4, BROWN)
			PA.ellipse(img, 10.5, 8.0, 1.6, 2.4, BROWN)
		"wave":
			for k in 3:
				for a in 9:
					var ang := -0.9 + a * 0.225
					PA.px(img, int(round(1.0 + k * 4.0 + cos(ang) * 4.0)), int(round(8.0 - sin(ang) * (4.0 + k * 1.5))), WHITE)
			edge = false
		"finger":
			PA.rect(img, 1, 6, 10, 4, Color("#9aa8c8"))
			PA.rect(img, 11, 7, 3, 2, Color("#9aa8c8"))
			PA.px(img, 14, 7, WHITE)
			PA.rect(img, 2, 7, 8, 1, Color("#c8d4f0"))
			PA.rect(img, 1, 10, 4, 3, Color("#7a88a8"))
		"band":
			for a in 40:
				var ang := a * TAU / 40.0
				PA.px(img, int(round(7.5 + cos(ang) * 5.5)), int(round(7.5 + sin(ang) * 4.5)), GOLD)
				PA.px(img, int(round(7.5 + cos(ang) * 4.5)), int(round(7.5 + sin(ang) * 3.5)), GOLD_D)
			PA.px(img, 5, 4, WHITE)
		"mouth":
			PA.ellipse(img, 8.0, 8.0, 6.0, 7.0, PURPLE_D)
			PA.ellipse(img, 8.0, 8.5, 4.2, 5.2, Color("#2a1a3a"))
			PA.ellipse(img, 8.0, 12.0, 2.6, 1.6, PINK)
			PA.rect(img, 6, 2, 4, 1, WHITE)
		"dust":
			PA.ellipse(img, 5.0, 10.0, 3.0, 2.6, Color("#d9c9a8"))
			PA.ellipse(img, 10.0, 9.0, 3.6, 3.0, Color("#d9c9a8"))
			PA.ellipse(img, 8.0, 7.0, 2.4, 2.0, CREAM)
			edge = false
		"petard":
			PA.rect(img, 4, 6, 8, 5, RED)
			PA.rect(img, 4, 7, 8, 1, PINK)
			PA.rect(img, 3, 6, 1, 5, GOLD_D)
			PA.rect(img, 12, 6, 1, 5, GOLD_D)
			PA.line(img, 12, 6, 14, 3, WOOD_D)
			PA.px(img, 14, 2, FIRE_L)
			PA.px(img, 15, 1, FIRE)
		"hand":
			PA.rect(img, 4, 6, 8, 8, Color("#eab98f"))
			for x in [4, 6, 8, 10]:
				PA.rect(img, x, 2, 2, 5, Color("#eab98f"))
			PA.rect(img, 2, 8, 2, 4, Color("#eab98f"))
			PA.rect(img, 5, 8, 6, 1, Color("#c8946a"))
		"straw":
			PA.line(img, 2, 13, 13, 3, GOLD)
			PA.line(img, 3, 14, 14, 6, GOLD_D)
			PA.line(img, 1, 9, 12, 2, FIRE_L)
			PA.line(img, 5, 14, 14, 9, GOLD)
			edge = false
		"web":
			PA.ellipse(img, 8.0, 8.0, 6.5, 5.0, Color("#9ec4b0"))
			PA.ellipse(img, 7.0, 7.0, 3.5, 2.4, Color("#c8e8d8"))
			PA.rect(img, 3, 12, 2, 3, Color("#9ec4b0"))
			PA.rect(img, 8, 12, 2, 4, Color("#9ec4b0"))
			PA.rect(img, 12, 11, 2, 3, Color("#9ec4b0"))
		_:
			PA.rect(img, 6, 6, 4, 4, WHITE)
	if edge:
		PA.outline(img, Rect2i(0, 0, SIZE, SIZE))
	return img

#!/usr/bin/env python3
"""Peint l'icône du jeu et l'écran de démarrage (assets/icone.png, assets/demarrage.png).

À relancer seulement pour changer ces images : python3 tools/fabriquer_images.py
Les PNG produits sont enregistrés dans le dépôt ; le build n'a pas besoin de Python.
Demande la bibliothèque Pillow (pip install pillow).
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FOND = (10, 10, 20)          # même couleur que default_clear_color du projet
OR = (232, 190, 92)
OR_CLAIR = (255, 232, 160)
OR_SOMBRE = (150, 104, 36)
POLICES = ["/System/Library/Fonts/Supplemental/Georgia Bold.ttf",
           "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf",
           "C:/Windows/Fonts/georgiab.ttf"]


def police(taille):
    for p in POLICES:
        if os.path.exists(p):
            return ImageFont.truetype(p, taille)
    return ImageFont.load_default()


def anneau(taille, centre, rayon, epaisseur):
    """Un anneau d'or avec reflet, sur un calque transparent (peint en grand puis réduit)."""
    k = 4
    calque = Image.new("RGBA", (taille[0] * k, taille[1] * k), (0, 0, 0, 0))
    d = ImageDraw.Draw(calque)
    cx, cy, r, e = centre[0] * k, centre[1] * k, rayon * k, epaisseur * k
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=OR_SOMBRE)
    d.ellipse([cx - r + e * 0.18, cy - r + e * 0.18, cx + r - e * 0.18, cy + r - e * 0.18], fill=OR)
    # reflet : arc clair en haut à gauche
    d.arc([cx - r + e * 0.30, cy - r + e * 0.30, cx + r - e * 0.30, cy + r - e * 0.30],
          start=195, end=285, fill=OR_CLAIR, width=int(e * 0.22))
    d.ellipse([cx - r + e, cy - r + e, cx + r - e, cy + r - e], fill=(0, 0, 0, 0))
    # ombre intérieure
    d.ellipse([cx - r + e, cy - r + e, cx + r - e, cy + r - e], outline=OR_SOMBRE, width=int(e * 0.10))
    return calque.resize(taille, Image.LANCZOS)


def lueur(taille, centre, rayon, couleur, force):
    calque = Image.new("RGBA", taille, (0, 0, 0, 0))
    d = ImageDraw.Draw(calque)
    d.ellipse([centre[0] - rayon, centre[1] - rayon, centre[0] + rayon, centre[1] + rayon],
              fill=couleur + (force,))
    return calque.filter(ImageFilter.GaussianBlur(rayon * 0.5))


def fond_degrade(taille):
    img = Image.new("RGB", taille, FOND)
    px = img.load()
    w, h = taille
    for y in range(h):
        for x in range(w):
            dx, dy = (x - w / 2) / w, (y - h * 0.45) / h
            v = max(0.0, 1.0 - math.sqrt(dx * dx + dy * dy) * 1.9)
            px[x, y] = (int(FOND[0] + 26 * v), int(FOND[1] + 20 * v), int(FOND[2] + 34 * v))
    return img


def icone():
    t = 256
    img = fond_degrade((t, t)).convert("RGBA")
    img.alpha_composite(lueur((t, t), (t // 2, t // 2), 90, OR, 70))
    img.alpha_composite(anneau((t, t), (t // 2, t // 2), 84, 30))
    masque = Image.new("L", (t * 4, t * 4), 0)
    ImageDraw.Draw(masque).rounded_rectangle([0, 0, t * 4 - 1, t * 4 - 1], radius=48 * 4, fill=255)
    img.putalpha(masque.resize((t, t), Image.LANCZOS))
    img.save(os.path.join(RACINE, "assets", "icone.png"))


def demarrage():
    w, h = 1280, 720
    img = fond_degrade((w, h)).convert("RGBA")
    img.alpha_composite(lueur((w, h), (w // 2, 250), 190, OR, 60))
    img.alpha_composite(anneau((w, h), (w // 2, 250), 120, 42))
    d = ImageDraw.Draw(img)
    for texte, taille, y, col in [("Le Seigneur des", 54, 440, OR_CLAIR), ("Anneaux Péniens", 74, 500, OR)]:
        f = police(taille)
        largeur = d.textlength(texte, font=f)
        d.text(((w - largeur) / 2 + 3, y + 3), texte, font=f, fill=(0, 0, 0, 200))
        d.text(((w - largeur) / 2, y), texte, font=f, fill=col)
    f = police(24)
    texte = "Chargement..."
    d.text(((w - d.textlength(texte, font=f)) / 2, 650), texte, font=f, fill=(170, 160, 140))
    img.convert("RGB").save(os.path.join(RACINE, "assets", "demarrage.png"))


if __name__ == "__main__":
    icone()
    demarrage()
    print("assets/icone.png et assets/demarrage.png écrits.")

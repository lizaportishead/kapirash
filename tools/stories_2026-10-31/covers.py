"""Flat vector-style covers for the two park stories (PIL, 3x supersampling).

Palette and look (cream paper, violet / pink / yellow / teal blocks, near-black details) follow
the other story covers. Run: python3 covers.py  ->  app/assets/story_{setnja_sa_psom,na_decjem_igralistu}.png
"""
import os
from PIL import Image, ImageDraw

W, H, S = 748, 492, 3
INK, CREAM = '#130e1d', '#f9f8ee'
VIOLET, PINK, ROSE, YELLOW = '#5645cd', '#e9afbc', '#de88c8', '#ece875'
TEAL, MINT, SAND, SKIN, SKIN2 = '#88c1ba', '#c2dfdf', '#ecd795', '#f0d1a5', '#c6928c'
PLUM, BROWN, DARKBROWN = '#462d54', '#897063', '#5b3a4b'
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))


class Canvas:
    def __init__(self, bg):
        self.im = Image.new('RGB', (W * S, H * S), bg)
        self.d = ImageDraw.Draw(self.im)

    def _s(self, pts):
        return [v * S for v in pts]

    def rect(self, x0, y0, x1, y1, fill, r=0):
        self.d.rounded_rectangle(self._s([x0, y0, x1, y1]), radius=r * S, fill=fill)

    def ell(self, x0, y0, x1, y1, fill):
        self.d.ellipse(self._s([min(x0, x1), min(y0, y1), max(x0, x1), max(y0, y1)]), fill=fill)

    def circle(self, cx, cy, r, fill):
        self.ell(cx - r, cy - r, cx + r, cy + r, fill)

    def poly(self, pts, fill):
        self.d.polygon(self._s([v for p in pts for v in p]), fill=fill)

    def line(self, pts, fill, w):
        self.d.line(self._s([v for p in pts for v in p]), fill=fill, width=int(w * S), joint='curve')

    def arc(self, box, a0, a1, fill, w):
        self.d.arc(self._s(box), a0, a1, fill=fill, width=int(w * S))

    def face(self, cx, cy, r, skin, hair=None, smile=True):
        self.circle(cx, cy, r, skin)
        if hair:
            self.d.pieslice(self._s([cx - r, cy - r, cx + r, cy + r]), 180, 360, fill=hair)
        for dx in (-r * 0.36, r * 0.36):
            self.circle(cx + dx, cy + r * 0.05, max(1.6, r * 0.09), INK)
        if smile:
            self.arc([cx - r * 0.4, cy + r * 0.05, cx + r * 0.4, cy + r * 0.6], 20, 160, INK, max(1.5, r * 0.08))

    def save(self, name, dy=34):
        out = self.im.resize((W, H), Image.LANCZOS)
        top = out.crop((0, 0, W, 1)).resize((W, dy))
        out.paste(out.crop((0, 0, W, H - dy)), (0, dy))
        out.paste(top, (0, 0))
        out.save(f'{ROOT}/app/assets/{name}.png', optimize=True)


def tree(c, x, ground, h, crown, trunk=DARKBROWN, r=62):
    c.rect(x - 7, ground - h, x + 7, ground, trunk)
    c.ell(x - r, ground - h - r * 1.25, x + r, ground - h + r * 0.75, crown)


def dog(c, x, y, body, ear, s=1.0, facing=1, white=False):
    """Small dog standing on y (paws), facing right if facing > 0."""
    f = facing
    c.line([(x - f * 34 * s, y - 40 * s), (x - f * 52 * s, y - 62 * s)], body, 7 * s)  # tail
    c.ell(x - 40 * s, y - 56 * s, x + 36 * s, y - 14 * s, body)
    for dx in (-30, -12, 14, 28):
        c.rect(x + dx * s - 4 * s, y - 24 * s, x + dx * s + 4 * s, y, body, 3 * s)
    hx = x + f * 38 * s
    c.circle(hx, y - 60 * s, 21 * s, body)
    c.ell(hx + f * 8 * s - 8 * s, y - 56 * s, hx + f * 8 * s + 8 * s, y - 40 * s, SAND if not white else CREAM)
    c.circle(hx + f * 18 * s, y - 56 * s, 4 * s, INK)
    c.circle(hx + f * 4 * s, y - 66 * s, 2.6 * s, INK)
    c.ell(hx - f * 24 * s - 7 * s, y - 80 * s, hx - f * 8 * s + 7 * s, y - 48 * s, ear)


def person(c, x, ground, top, bottom, skin, hair, h=1.0, hair_style='short', hat=None):
    """Standing figure seen from the front: legs, sweater, head."""
    hs = h
    c.rect(x - 22 * hs, ground - 110 * hs, x - 3 * hs, ground - 4 * hs, bottom, 5 * hs)
    c.rect(x + 3 * hs, ground - 110 * hs, x + 22 * hs, ground - 4 * hs, bottom, 5 * hs)
    c.rect(x - 28 * hs, ground - 7 * hs, x - 1 * hs, ground, INK, 4 * hs)
    c.rect(x + 1 * hs, ground - 7 * hs, x + 28 * hs, ground, INK, 4 * hs)
    c.rect(x - 34 * hs, ground - 205 * hs, x + 34 * hs, ground - 95 * hs, top, 16 * hs)
    c.rect(x - 8 * hs, ground - 220 * hs, x + 8 * hs, ground - 200 * hs, skin)
    if hair_style == 'long':
        c.rect(x - 30 * hs, ground - 266 * hs, x + 30 * hs, ground - 196 * hs, hair, 22 * hs)
    c.face(x, ground - 240 * hs, 27 * hs, skin, hair if hair_style != 'long' else None)
    if hair_style == 'long':
        c.d.pieslice(c._s([x - 27 * hs, ground - 267 * hs, x + 27 * hs, ground - 213 * hs]), 180, 360, fill=hair)


def walk_in_the_park():
    c = Canvas(CREAM)
    c.ell(-120, -260, 880, 330, PINK)
    c.circle(612, 105, 48, YELLOW)
    c.rect(0, 392, W, H, MINT)
    c.rect(0, 392, W, 402, TEAL)
    tree(c, 60, 392, 150, TEAL, r=70)
    tree(c, 355, 392, 170, '#a3c2bd', r=58)
    tree(c, 735, 392, 150, TEAL, r=64)
    # bin
    c.rect(122, 318, 168, 392, TEAL, 6)
    c.rect(116, 308, 174, 322, '#5a9a92', 5)
    c.rect(139, 340, 151, 372, MINT, 3)
    # bench with Mira and Bela
    c.rect(455, 330, 706, 346, INK, 4)
    c.rect(463, 346, 477, 392, INK)
    c.rect(684, 346, 698, 392, INK)
    c.rect(455, 280, 706, 292, INK, 4)
    c.rect(466, 292, 476, 330, INK)
    c.rect(684, 292, 694, 330, INK)
    c.rect(536, 252, 610, 336, VIOLET, 14)          # sweater
    c.rect(544, 322, 604, 392, PLUM, 8)             # legs
    c.rect(536, 380, 566, 394, INK, 4)
    c.rect(582, 380, 612, 394, INK, 4)
    c.face(573, 226, 26, SKIN, None)
    c.d.pieslice(c._s([547, 200, 599, 252]), 170, 370, fill='#e7e7ea')
    c.ell(551, 196, 595, 222, '#e7e7ea')
    c.circle(564, 228, 2.4, INK); c.circle(582, 228, 2.4, INK)
    c.arc([563, 230, 583, 247], 20, 160, INK, 2.2)
    dog(c, 650, 330, '#f4f4f0', '#d9d9d2', s=0.9, facing=-1, white=True)
    # Ivana with Riki on a leash
    ix = 232
    person(c, ix, 392, VIOLET, PLUM, SKIN, INK, h=1.0, hair_style='long')
    c.line([(ix + 30, 212), (ix + 62, 256), (ix + 82, 290)], SKIN, 9)          # arm to leash
    c.line([(ix + 82, 290), (322, 352)], INK, 2.6)                                # leash
    c.line([(ix - 34, 215), (ix - 54, 262)], SKIN, 9)
    c.rect(ix - 66, 258, ix - 44, 292, ROSE, 4)                                   # small bag
    dog(c, 352, 392, BROWN, DARKBROWN, s=1.0, facing=1)
    c.save('story_setnja_sa_psom')


def playground():
    c = Canvas(CREAM)
    c.ell(-120, -300, 880, 300, '#a9a0ef')
    c.circle(650, 92, 44, YELLOW)
    c.rect(0, 380, W, H, SAND)
    c.rect(0, 380, W, 392, '#d9be75')
    # slide
    c.rect(44, 168, 160, 188, YELLOW, 6)
    c.rect(52, 188, 62, 382, INK)
    c.rect(142, 188, 152, 382, INK)
    c.rect(44, 100, 160, 124, VIOLET, 8)
    c.rect(56, 124, 66, 168, INK); c.rect(138, 124, 148, 168, INK)
    c.poly([(150, 170), (225, 170), (330, 372), (292, 380)], TEAL)
    c.poly([(150, 170), (225, 170), (232, 182), (160, 182)], '#5a9a92')
    for y in range(206, 372, 32):
        c.rect(62, y, 142, y + 7, INK, 2)
    # kid sliding
    c.rect(262, 262, 300, 316, ROSE, 9)
    c.face(281, 238, 20, SKIN, INK)
    c.line([(270, 312), (300, 352)], PLUM, 11)
    c.line([(290, 308), (322, 340)], PLUM, 11)
    # swing set
    c.line([(400, 372), (440, 120)], INK, 8)
    c.line([(540, 372), (500, 120)], INK, 8)
    c.line([(430, 126), (510, 126)], INK, 9)
    c.line([(448, 126), (440, 300)], INK, 3)
    c.line([(492, 126), (500, 300)], INK, 3)
    c.rect(432, 298, 508, 310, VIOLET, 4)
    c.rect(448, 238, 492, 300, YELLOW, 10)                    # Luka
    c.face(470, 214, 22, SKIN, DARKBROWN)
    c.line([(452, 246), (440, 280)], SKIN, 8); c.line([(488, 246), (500, 280)], SKIN, 8)
    c.line([(462, 300), (458, 346)], PLUM, 9); c.line([(478, 300), (486, 346)], PLUM, 9)
    # sandbox with Nikola
    c.rect(560, 336, 730, 392, '#d9be75', 8)
    c.rect(570, 346, 720, 392, SAND, 6)
    c.rect(612, 262, 664, 340, '#d94f4f', 12)       # red jacket
    c.face(638, 238, 23, SKIN2, INK)
    c.line([(620, 296), (590, 330)], SKIN2, 8)
    c.line([(656, 296), (692, 326)], SKIN2, 8)
    c.line([(692, 326), (712, 300)], VIOLET, 5)
    c.poly([(704, 288), (726, 296), (716, 314), (700, 304)], VIOLET)           # spade blade
    c.rect(560, 354, 600, 392, TEAL, 5)                                       # bucket
    c.rect(556, 350, 604, 360, '#5a9a92', 3)
    c.save('story_na_decjem_igralistu')


if __name__ == '__main__':
    walk_in_the_park()
    playground()

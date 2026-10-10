# -*- coding: utf-8 -*-
"""
生成 App Store 图标（1024x1024 PNG）

跑法（在项目根目录执行；需要 Python 3 + Pillow）：
    python tools/make_icon.py

    Windows 上如果 `python` 命令不通，就用 Python 的完整路径，例如：
    "C:/Users/<你的用户名>/AppData/Local/Programs/Python/Python312/python.exe" tools/make_icon.py
    （若提示 No module named 'PIL'，先执行 python -m pip install Pillow）

改配色：直接改下面 PALETTE 里的两个颜色即可，其余会自动重算。

⚠️ Apple 对图标的要求（脚本已满足）：
  · 1024 x 1024 像素
  · 无透明通道（最后强制转 RGB）
  · 不预先切圆角 —— 系统会自动裁切，画满幅方形就对了
"""

import os
from PIL import Image, ImageDraw

SIZE = 1024

# ---- 配色（改这里就行）------------------------------------------------
BG_TOP = (26, 203, 151)      # 顶部薄荷绿
BG_BOTTOM = (9, 137, 100)    # 底部深薄荷绿
JAR = (255, 255, 255)        # 罐身
COIN = (255, 197, 61)        # 金币
COIN_EDGE = (235, 158, 0)    # 金币描边
# ----------------------------------------------------------------------


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def bg_color_at(y):
    return lerp(BG_TOP, BG_BOTTOM, y / (SIZE - 1))


def main():
    img = Image.new("RGB", (SIZE, SIZE))
    d = ImageDraw.Draw(img)

    # 1) 垂直渐变背景
    for y in range(SIZE):
        d.line([(0, y), (SIZE, y)], fill=bg_color_at(y))

    base = img.convert("RGBA")

    # 2) 罐子本体：罐身 + 罐口（两段圆角矩形叠加）
    jar_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    dj = ImageDraw.Draw(jar_layer)
    dj.rounded_rectangle([222, 395, 802, 870], radius=130, fill=JAR)
    dj.rounded_rectangle([322, 310, 702, 415], radius=50, fill=JAR)
    base = Image.alpha_composite(base, jar_layer)

    # 3) 投币口：用该高度的背景色画一条扁椭圆，视觉上"挖"出一个口子
    ax, ay = 512, 368
    arx, ary = 96, 15
    hole = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    dh = ImageDraw.Draw(hole)
    # 椭圆上下边缘各用一点渐变色，避免看起来像贴纸
    dh.ellipse([ax - arx, ay - ary, ax + arx, ay + ary],
               fill=bg_color_at(ay) + (255,))
    dh.ellipse([ax - arx - 3, ay - ary - 4, ax + arx + 3, ay + ary + 2],
               fill=(0, 0, 0, 26))
    dh.ellipse([ax - arx, ay - ary, ax + arx, ay + ary],
               fill=bg_color_at(ay) + (255,))
    base = Image.alpha_composite(base, hole)

    # 4) 金币（正在投入罐口的样子）
    cx, cy, r = 512, 212, 80
    coin = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    dc = ImageDraw.Draw(coin)
    dc.ellipse([cx - r, cy - r, cx + r, cy + r], fill=COIN,
               outline=COIN_EDGE, width=9)
    dc.ellipse([cx - r + 26, cy - r + 26, cx + r - 26, cy + r - 26],
               outline=COIN_EDGE, width=7)
    base = Image.alpha_composite(base, coin)

    # 5) 金币高光（左上角一小片白色柔光，增加立体感）
    gloss = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    dg = ImageDraw.Draw(gloss)
    dg.ellipse([cx - 46, cy - 62, cx + 6, cy - 10], fill=(255, 255, 255, 92))
    dg.ellipse([cx - 96, cy - 30, cx - 60, cy + 6], fill=(255, 255, 255, 56))
    base = Image.alpha_composite(base, gloss)

    # 6) 罐身高光（左侧一条竖向柔光，暗示玻璃质感）
    shine = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ds = ImageDraw.Draw(shine)
    ds.rounded_rectangle([268, 452, 306, 760], radius=19,
                         fill=BG_TOP + (0,))
    ds.rounded_rectangle([268, 452, 306, 760], radius=19,
                         fill=(255, 255, 255, 26))
    base = Image.alpha_composite(base, shine)

    # 7) 导出：强制 RGB，去掉 alpha 通道
    out_dir = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "..", "SavingsJar", "Resources", "Assets.xcassets",
        "AppIcon.appiconset",
    )
    out_dir = os.path.normpath(out_dir)
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "AppIcon-1024.png")

    final = base.convert("RGB")
    final.save(out_path, "PNG", optimize=True)

    print("OK ->", out_path)
    print("尺寸:", final.size, "模式:", final.mode)


if __name__ == "__main__":
    main()

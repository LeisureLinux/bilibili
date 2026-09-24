#!/usr/bin/env python3
"""
mp3 音乐元数据整理工具 —— 把散装音乐导入、按歌手归类、补全元数据/封面/歌词。

典型场景: 从 iPod / 播放器导出 mp3 后, 统一整理成规范的音乐库。

Copyright: LeisureLinux@Bilibili
VERSION:   1.0.0
License:   MIT

用法:
  mp3_metadata_organizer.py sync   <源目录> <目标目录> [--dry-run]   复制+排除非音乐+按歌手归类+去重
  mp3_metadata_organizer.py meta   <目录>                           元数据规范化(乱码修复 + 繁转简)
  mp3_metadata_organizer.py lyrics <目录> [--limit N] [--dry-run]   补歌词(netease 优先, 多候选词)
  mp3_metadata_organizer.py covers <目录> [--limit N] [--dry-run]   补封面(搜真封面, 搜不到生成渐变封面)
  mp3_metadata_organizer.py all    <源目录> <目标目录>               完整流程: sync -> meta -> lyrics -> covers

依赖:
  pip3 install mutagen opencc-python-reimplemented syncedlyrics sacad
  apt  install eyeD3 ffmpeg        (中文字体: Noto Sans SC / Noto Music)

设计说明:
  - mp3(TIT2/TPE1/TALB) 与 m4a(©nam/©ART/©alb) 统一处理
  - 乱码修复: latin1->gbk (老播放器常见)
  - 繁转简: opencc t2s
  - 歌词源: netease 优先(中文覆盖好), 回退 lrclib; 搜索词做多候选
  - 封面: sacad 按 (artist, album) 搜专辑封面; 搜不到用渐变+音符生成封面
  - sync 会排除常见播客/演讲(EXCLUDE_ARTISTS), 按需增删
"""
import sys
import re
import argparse
import subprocess
import tempfile
from pathlib import Path
from collections import defaultdict

from mutagen import File as MFile
from mutagen.id3 import TIT2, TPE1, TALB, APIC
from mutagen.mp4 import MP4Cover
from opencc import OpenCC

AUDIO_EXTS = (".mp3", ".m4a", ".mp4")
CC = OpenCC("t2s")

# 非音乐(播客/演讲)的 artist 关键词 —— 这些不同步到音乐库
EXCLUDE_ARTISTS = [
    "twogomers", "Bloomberg LP", "VoiceAmerica", "Connected Social Media",
    "Dave Ramsey", "The White House", "The Marathon Show", "The Public Speaker",
    "Knowledge@Wharton", "CIOTalkRadio", "Process Excellence Network",
    "Stanford Technology Ventures", "Fabian Oefner", "Parul Sehgal",
    "Andrew Fitzgerald", "Robin Nagle", "Steve Howard", "Dong Woo Jang",
    "Eli Beer", "Rodney Brooks", "Stefan Larsson",
]

# 生成封面用的字体(按候选依次查找, 找不到回退到 fontconfig)
def _find_font(candidates, fallback_families):
    from pathlib import Path
    home = Path.home()
    for c in candidates:
        p = Path(str(c).replace("~", str(home)))
        if p.exists():
            return str(p)
    # 回退: 用 fc-match 按字体族名查找
    for fam in fallback_families:
        try:
            r = subprocess.run(["fc-match", "-f", "%{file}", fam],
                               capture_output=True, text=True, timeout=10)
            if r.returncode == 0 and r.stdout.strip():
                return r.stdout.strip()
        except Exception:
            pass
    return None


FONT_SC = _find_font(
    ["~/.fonts/static/NotoSansSC-Bold.ttf",
     "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc",
     "/usr/share/fonts/truetype/noto/NotoSansCJK-Bold.ttc"],
    ["Noto Sans SC:bold", "Noto Sans CJK SC:bold", "sans-serif:bold"])

FONT_MUSIC = _find_font(
    ["/usr/share/fonts/truetype/noto/NotoMusic-Regular.ttf"],
    ["Noto Music"])


# ---------------------------------------------------------------- 元数据工具
def read_tags(f):
    """返回 (title, artist, album)。"""
    try:
        m = MFile(str(f))
        if m is None or m.tags is None:
            return "", "", ""
        t = m.tags

        def g(keys):
            for k in keys:
                if k in t:
                    v = t[k]
                    return (v[0] if isinstance(v, list) else str(v)).strip()
            return ""
        if f.suffix.lower() == ".mp3":
            return g(["TIT2"]), g(["TPE1"]), g(["TALB"])
        return g(["\xa9nam"]), g(["\xa9ART"]), g(["\xa9alb"])
    except Exception:
        return "", "", ""


def fix_garble(s):
    """latin1 被误读为 gbk 的乱码修复。"""
    try:
        return s.encode("latin1").decode("gbk")
    except Exception:
        return s


def sanitize(s):
    """去掉控制字符(含 null byte)、首尾空白。"""
    return "".join(ch for ch in s if ch >= " " and ch != "\x7f").strip()


def norm(s):
    """乱码修复 + 繁转简 + 去控制字符。"""
    return CC.convert(sanitize(fix_garble(s)))


def norm_artist(a):
    """歌手名归一化(去括号、乐队后缀、别名)。"""
    a = re.sub(r"\(.*?\)", "", (a or "").strip()).strip()
    a = a.replace("樂隊", "").replace("乐队", "").strip()
    alias = {"王靖雯王菲": "王菲", "王靖雯": "王菲", "温拿乐队": "温拿"}
    return alias.get(a, a)


def has_cover(f):
    try:
        m = MFile(str(f))
        if m is None or m.tags is None:
            return False
        if f.suffix.lower() == ".mp3":
            return any(k.startswith("APIC") for k in m.tags)
        return bool(m.tags.get("covr"))
    except Exception:
        return False


def write_meta(f, title=None, artist=None, album=None):
    """写回 title/artist/album(保留其它 frame)。"""
    m = MFile(str(f))
    if m.tags is None:
        m.add_tags()
    t = m.tags
    if f.suffix.lower() == ".mp3":
        if title is not None:
            t["TIT2"] = TIT2(encoding=3, text=title)
        if artist is not None:
            t["TPE1"] = TPE1(encoding=3, text=artist)
        if album is not None:
            t["TALB"] = TALB(encoding=3, text=album)
    else:
        if title is not None:
            t["\xa9nam"] = [title]
        if artist is not None:
            t["\xa9ART"] = [artist]
        if album is not None:
            t["\xa9alb"] = [album]
    m.save()


# ---------------------------------------------------------------- 命令: sync
def cmd_sync(src, dst, dry=False):
    src, dst = Path(src), Path(dst)
    if not src.is_dir():
        print(f"错误: 源目录不存在: {src}", file=sys.stderr)
        sys.exit(1)
    files = sorted([p for p in src.rglob("*") if p.suffix.lower() in AUDIO_EXTS])
    print(f"源文件: {len(files)}")

    excluded, items = [], []
    for f in files:
        ti, ar, _ = read_tags(f)
        ti, ar = norm(ti), ar  # 修复乱码/繁转简(不转歌手,歌手名在归类时归一)
        if ti.startswith("TED:") or ti.startswith("TED ") or \
           any(kw.lower() in ar.lower() for kw in EXCLUDE_ARTISTS):
            excluded.append(f)
            continue
        items.append((f, ti, ar))

    # 去重: 同 (归一化 title, 归一化 artist) 只留一个, mp3 优先
    groups = defaultdict(list)
    for f, ti, ar in items:
        groups[(CC.convert(ti).lower(), norm_artist(CC.convert(ar)).lower())].append((f, ti, ar))
    keep, removed = [], []
    for grp in groups.values():
        if len(grp) == 1:
            keep.append(grp[0])
            continue
        mp3s = [x for x in grp if x[0].suffix.lower() == ".mp3"]
        chosen = mp3s[0] if mp3s else grp[0]
        keep.append(chosen)
        removed += [x for x in grp if x[0] != chosen[0]]

    print(f"排除非音乐: {len(excluded)}, 去重移除: {len(removed)}, 待同步: {len(keep)}")
    if dry:
        for f, ti, ar in keep[:30]:
            a = norm_artist(CC.convert(norm(ar))) or "_未分类"
            print(f"  {f.name} -> {a}/{CC.convert(ti) or f.stem}{f.suffix}")
        print("(dry-run)")
        return

    n = 0
    for f, ti, ar in keep:
        a = re.sub(r'[<>:"/\\|?*]', "_", norm_artist(CC.convert(norm(ar))) or "_未分类")
        t = re.sub(r'[<>:"/\\|?*]', "_", CC.convert(ti) or f.stem)
        d = dst / a
        d.mkdir(parents=True, exist_ok=True)
        out = d / (t + f.suffix.lower())
        if out.exists():
            continue
        import shutil
        shutil.copy2(f, out)
        n += 1
    print(f"复制完成: {n} 个")


# ---------------------------------------------------------------- 命令: meta
def cmd_meta(root, dry=False):
    root = Path(root)
    n = 0
    for f in sorted(root.rglob("*")):
        if f.suffix.lower() not in AUDIO_EXTS:
            continue
        ti, ar, al = read_tags(f)
        if not (ti or ar or al):
            continue
        nti, nar, nal = norm(ti), norm(ar), norm(al)
        if (nti, nar, nal) != (ti, ar, al):
            if dry:
                print(f"  {f.name}: '{ar}/{ti}' -> '{nar}/{nti}'")
            else:
                write_meta(f, nti or ti, nar or ar, nal or al)
            n += 1
    print(f"元数据规范化: {n} 个文件" + (" (dry-run)" if dry else ""))


# ---------------------------------------------------------------- 命令: lyrics
def _clean_kw(f, title, artist):
    stem = f.stem
    if artist and stem.endswith("-" + artist):
        stem = stem[:-(len(artist) + 1)]
    stem = re.sub(r'^[\w\u4e00-\u9fff]+\s*-\s*', '', stem)
    stem = re.sub(r'\([^)]*\)|（[^）]*）|\[[^\]]*\]|【[^】]*】', '', stem)
    stem = re.sub(r'(Official\s*Music\s*Video|Official\s*Video|MV|Lyrics?|Audio)', '', stem, flags=re.I)
    stem = stem.strip(' -·,')
    return stem


def cmd_lyrics(root, limit=None, dry=False):
    root = Path(root)
    files = sorted([p for p in root.rglob("*") if p.suffix.lower() in AUDIO_EXTS])
    todo = [f for f in files if not f.with_suffix(".lrc").exists()]
    if limit:
        todo = todo[:limit]
    print(f"缺 lrc: {len(todo)}")
    ok = 0
    for i, f in enumerate(todo, 1):
        ti, ar, _ = read_tags(f)
        ti, ar = CC.convert(norm(ti)).strip(), CC.convert(norm(ar)).strip()
        cands = []
        if ti and ar:
            cands += [f"{ar} {ti}", ti]
        elif ti:
            cands.append(ti)
        stem = CC.convert(norm(_clean_kw(f, ti, ar))).strip()
        if stem and stem not in cands:
            cands.append(stem)

        content, used = "", ""
        for kw in cands:
            if not kw:
                continue
            tmp = tempfile.mktemp(suffix=".lrc")
            try:
                subprocess.run(["syncedlyrics", "-p", "netease", "lrclib", "--synced-only", kw, "-o", tmp],
                               capture_output=True, text=True, timeout=50)
            except Exception:
                pass
            if Path(tmp).exists() and Path(tmp).stat().st_size > 50:
                content = Path(tmp).read_text(encoding="utf-8", errors="replace")
                used = kw
                Path(tmp).unlink(missing_ok=True)
                break
            Path(tmp).unlink(missing_ok=True)
        if content.strip():
            if not dry:
                f.with_suffix(".lrc").write_text(CC.convert(content), encoding="utf-8")
            ok += 1
            print(f"[{i}/{len(todo)}] ✓ {f.name}  ({used})")
        else:
            print(f"[{i}/{len(todo)}] ✗ {f.name}")
    print(f"歌词: 补 {ok} 个" + (" (dry-run)" if dry else ""))


# ---------------------------------------------------------------- 命令: covers
def _gen_cover(title, artist, out, size=500):
    from PIL import Image, ImageDraw, ImageFont
    img = Image.new("RGB", (size, size))
    px = img.load()
    c1, c2 = (42, 44, 90), (120, 50, 90)
    for y in range(size):
        for x in range(size):
            t = (x + y) / (size * 2)
            px[x, y] = (int(c1[0]+(c2[0]-c1[0])*t), int(c1[1]+(c2[1]-c1[1])*t), int(c1[2]+(c2[2]-c1[2])*t))
    d = ImageDraw.Draw(img)
    title_font = ImageFont.truetype(FONT_SC, 52)
    artist_font = ImageFont.truetype(FONT_SC, 28)
    music_font = ImageFont.truetype(FONT_MUSIC, 80)

    def wrap(text, font, max_w):
        lines, line = [], ""
        for ch in text:
            bbox = d.textbbox((0, 0), line + ch, font=font)
            if bbox[2]-bbox[0] > max_w and line:
                lines.append(line); line = ch
            else:
                line += ch
        if line:
            lines.append(line)
        return lines

    tl = wrap(title or "", title_font, 400) if title else []
    al = wrap(artist or "", artist_font, 400) if artist else []
    nb = d.textbbox((0, 0), "♪", font=music_font)
    d.text(((size-(nb[2]-nb[0]))//2, 50), "♪", fill="#f5e6d0", font=music_font)
    y = max(200, (size - (len(tl)*70 + (len(al)*40 if al else 0)))//2 + 40)
    for ln in tl:
        b = d.textbbox((0, 0), ln, font=title_font)
        d.text(((size-(b[2]-b[0]))//2, y), ln, fill="#ffffff", font=title_font); y += 70
    if al:
        y += 12
        for ln in al:
            b = d.textbbox((0, 0), ln, font=artist_font)
            d.text(((size-(b[2]-b[0]))//2, y), ln, fill="#e0d8f0", font=artist_font); y += 40
    img.save(out, "JPEG", quality=90)


def _embed_cover(f, img_path):
    m = MFile(str(f))
    if m.tags is None:
        m.add_tags()
    data = Path(img_path).read_bytes()
    if f.suffix.lower() == ".mp3":
        m.tags.add(APIC(encoding=3, mime="image/jpeg", type=3, desc="Cover", data=data))
    else:
        m.tags["covr"] = [MP4Cover(data, imageformat=MP4Cover.FORMAT_JPEG)]
    m.save()


def cmd_covers(root, limit=None, dry=False):
    root = Path(root)
    files = sorted([p for p in root.rglob("*") if p.suffix.lower() in AUDIO_EXTS])
    todo = [f for f in files if not has_cover(f)]
    if limit:
        todo = todo[:limit]
    print(f"缺封面: {len(todo)}")
    real = gen = 0
    for i, f in enumerate(todo, 1):
        ti, ar, al = read_tags(f)
        ti, ar = CC.convert(norm(ti)), CC.convert(norm(ar))
        tmp = tempfile.mktemp(suffix=".jpg")
        ok = False
        if ar and al and al.upper() != "KXT":
            try:
                subprocess.run(["sacad", "-s", "itunes", "-v", "warning", ar, al, "500", tmp],
                               capture_output=True, text=True, timeout=90)
                if Path(tmp).exists() and Path(tmp).stat().st_size > 1000:
                    ok = True
            except Exception:
                pass
        if not ok:
            _gen_cover(ti or f.stem, ar, tmp)
        if dry:
            print(f"[{i}/{len(todo)}] {'真封面' if ok else '生成封面'} {f.name}")
            Path(tmp).unlink(missing_ok=True)
            continue
        _embed_cover(f, tmp)
        Path(tmp).unlink(missing_ok=True)
        if ok:
            real += 1
        else:
            gen += 1
        print(f"[{i}/{len(todo)}] {'✓真' if ok else '○生成'} {f.name}")
    print(f"封面: 真封面 {real}, 生成封面 {gen}" + (" (dry-run)" if dry else ""))


# ---------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser(description="mp3 音乐元数据整理工具")
    sub = ap.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("sync", help="复制+归类+去重")
    s.add_argument("src"); s.add_argument("dst"); s.add_argument("--dry-run", action="store_true")

    m = sub.add_parser("meta", help="元数据规范化")
    m.add_argument("root"); m.add_argument("--dry-run", action="store_true")

    l = sub.add_parser("lyrics", help="补歌词")
    l.add_argument("root"); l.add_argument("--limit", type=int); l.add_argument("--dry-run", action="store_true")

    c = sub.add_parser("covers", help="补封面")
    c.add_argument("root"); c.add_argument("--limit", type=int); c.add_argument("--dry-run", action="store_true")

    a = sub.add_parser("all", help="完整流程")
    a.add_argument("src"); a.add_argument("dst")

    args = ap.parse_args()
    if args.cmd == "sync":
        cmd_sync(args.src, args.dst, args.dry_run)
    elif args.cmd == "meta":
        cmd_meta(args.root, args.dry_run)
    elif args.cmd == "lyrics":
        cmd_lyrics(args.root, args.limit, args.dry_run)
    elif args.cmd == "covers":
        cmd_covers(args.root, args.limit, args.dry_run)
    elif args.cmd == "all":
        cmd_sync(args.src, args.dst)
        cmd_meta(args.dst)
        cmd_lyrics(args.dst)
        cmd_covers(args.dst)


if __name__ == "__main__":
    main()

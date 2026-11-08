#!/usr/bin/env python3
# LegendStudy+ marketing banner generator (SVG sources).
# Brand tokens: Primary #FFAC14, Dark #E99500, Soft #FFF3DC, SurfaceWarm #FFFDF9,
# Text #202124, Secondary #666, Divider #EEE. Korean via Apple SD Gothic Neo.
import base64, os, html, unicodedata, pathlib

HERE = pathlib.Path(__file__).parent
# Official brand symbol (memo + pencil). Repo-relative; self-contained.
SYM_PNG = (HERE / "../../brand/source/legendstudy_square_logo_source.png").resolve()
OUT = HERE / "svg"
OUT.mkdir(exist_ok=True)
sym_b64 = base64.b64encode(SYM_PNG.read_bytes()).decode()
SYM_URI = "data:image/png;base64," + sym_b64

PRIMARY="#FFAC14"; DARK="#E99500"; SOFT="#FFF3DC"; WARM="#FFFDF9"
INK="#202124"; SEC="#5B5F66"; WHITE="#FFFFFF"; NAVY="#243244"

FONT="'Apple SD Gothic Neo','AppleSDGothicNeo','NanumSquareOTF','Noto Sans CJK KR',sans-serif"

def esc(s): return html.escape(s, quote=True)

def wtext(s, fs):
    """Rough rendered width estimate for mixed KR/latin at font-size fs."""
    w=0.0
    for ch in s:
        o=ord(ch)
        if o>0x1100 and unicodedata.east_asian_width(ch) in ("W","F"):
            w+=fs*1.0
        elif ch==" ": w+=fs*0.30
        elif ch.isupper() or ch in "@#%&": w+=fs*0.62
        elif ch.isdigit(): w+=fs*0.56
        else: w+=fs*0.54
    return w

def chip(x,y,text,fs=14,fill=SOFT,ink=DARK,pad=14):
    w=wtext(text,fs)+pad*2; h=fs+14
    return (f'<rect x="{x}" y="{y}" width="{w:.0f}" height="{h:.0f}" rx="{h/2:.0f}" fill="{fill}"/>'
            f'<text x="{x+pad:.0f}" y="{y+h/2:.0f}" font-family="{FONT}" font-size="{fs}" font-weight="800" '
            f'fill="{ink}" dominant-baseline="central">{esc(text)}</text>'), w, h

def cta(x,y,text,fs=17,fill=PRIMARY,ink=INK,padx=22,h=None):
    h=h or fs+26
    w=wtext(text,fs)+padx*2
    return (f'<rect x="{x}" y="{y}" width="{w:.0f}" height="{h:.0f}" rx="{h/2:.0f}" fill="{fill}"/>'
            f'<text x="{x+w/2:.0f}" y="{y+h/2:.0f}" font-family="{FONT}" font-size="{fs}" font-weight="800" '
            f'fill="{ink}" text-anchor="middle" dominant-baseline="central">{esc(text)}</text>'), w, h

def symbol_mark(x,y,size):
    # crop official 150x150 symbol to top 96px (memo+pencil, above the .com text)
    sc=size/150.0; crop_h=96*sc
    return (f'<svg x="{x}" y="{y}" width="{size}" height="{crop_h:.0f}" viewBox="0 0 150 96">'
            f'<image href="{SYM_URI}" x="0" y="0" width="150" height="150" preserveAspectRatio="xMidYMin meet"/></svg>')

def brandmark(x,y,scale=1.0):
    s=40*scale
    sym=symbol_mark(x,y, s)
    tx=x+s+10
    return (sym +
            f'<text x="{tx:.0f}" y="{y+s*0.52:.0f}" font-family="{FONT}" font-size="{19*scale:.0f}" '
            f'font-weight="900" fill="{INK}" dominant-baseline="central">레전드스터디'
            f'<tspan fill="{PRIMARY}">+</tspan></text>')

def pc_banner(bg_stops, eyebrow, title_lines, sub, cta_text, cta_fill, cta_ink, accent):
    W,H=1024,256
    parts=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img">']
    parts.append('<defs>'
        f'<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">{bg_stops}</linearGradient>'
        f'<linearGradient id="panel" x1="0" y1="0" x2="1" y2="1">'
        f'<stop offset="0" stop-color="{WHITE}"/><stop offset="1" stop-color="{SOFT}"/></linearGradient></defs>')
    parts.append(f'<rect width="{W}" height="{H}" rx="20" fill="url(#bg)"/>')
    # decorative accent blob on right
    parts.append(f'<circle cx="{W-150}" cy="{H+40}" r="190" fill="{accent}" opacity="0.14"/>')
    parts.append(f'<circle cx="{W-70}" cy="30" r="90" fill="{accent}" opacity="0.10"/>')
    # right brand card
    cardx=W-300; cardw=250
    parts.append(f'<rect x="{cardx}" y="34" width="{cardw}" height="{H-68}" rx="18" fill="url(#panel)" '
                 f'stroke="{PRIMARY}" stroke-opacity="0.35"/>')
    parts.append(symbol_mark(cardx+cardw/2-45, 60, 90))
    parts.append(f'<text x="{cardx+cardw/2:.0f}" y="178" font-family="{FONT}" font-size="22" font-weight="900" '
                 f'fill="{INK}" text-anchor="middle">레전드스터디<tspan fill="{PRIMARY}">+</tspan></text>')
    parts.append(f'<text x="{cardx+cardw/2:.0f}" y="206" font-family="{FONT}" font-size="13" font-weight="700" '
                 f'fill="{SEC}" text-anchor="middle">LegendStudy+</text>')
    # left content
    LX=56
    ch,cw,chh=chip(LX,34,eyebrow)
    parts.append(ch)
    ty=34+chh+34
    for i,ln in enumerate(title_lines):
        parts.append(f'<text x="{LX}" y="{ty+i*42}" font-family="{FONT}" font-size="33" font-weight="900" '
                     f'fill="{INK}">{ln}</text>')
    sy=ty+len(title_lines)*42+8
    parts.append(f'<text x="{LX}" y="{sy}" font-family="{FONT}" font-size="15.5" font-weight="600" '
                 f'fill="{SEC}">{esc(sub)}</text>')
    cy=sy+20
    c,_,_=cta(LX,cy,cta_text,fs=17,fill=cta_fill,ink=cta_ink)
    parts.append(c)
    parts.append('</svg>')
    return "\n".join(parts)

def mobile_banner(bg_stops, eyebrow, title_lines, sub, cta_text, cta_fill, cta_ink, accent):
    W,H=640,360
    parts=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img">']
    parts.append('<defs>'
        f'<linearGradient id="bgm" x1="0" y1="0" x2="1" y2="1">{bg_stops}</linearGradient></defs>')
    parts.append(f'<rect width="{W}" height="{H}" rx="22" fill="url(#bgm)"/>')
    parts.append(f'<circle cx="{W-40}" cy="{H-20}" r="150" fill="{accent}" opacity="0.13"/>')
    LX=36
    parts.append(brandmark(LX,30,scale=1.0))
    ch,cw,chh=chip(LX,92,eyebrow,fs=13)
    parts.append(ch)
    ty=92+chh+36
    for i,ln in enumerate(title_lines):
        parts.append(f'<text x="{LX}" y="{ty+i*40}" font-family="{FONT}" font-size="30" font-weight="900" '
                     f'fill="{INK}">{ln}</text>')
    sy=ty+len(title_lines)*40+6
    # sub may wrap: pass as list already split
    parts.append(f'<text x="{LX}" y="{sy}" font-family="{FONT}" font-size="15" font-weight="600" '
                 f'fill="{SEC}">{esc(sub)}</text>')
    cy=sy+22
    c,cw2,chh2=cta(LX,cy,cta_text,fs=17,fill=cta_fill,ink=cta_ink)
    parts.append(c)
    parts.append('</svg>')
    return "\n".join(parts)

# ---- Banner definitions ----
O_STOPS=f'<stop offset="0" stop-color="{WARM}"/><stop offset="1" stop-color="{SOFT}"/>'
LAB_STOPS=f'<stop offset="0" stop-color="#FFF8EC"/><stop offset="1" stop-color="#FFE9C2"/>'

BANNERS={
 "ios-launch": dict(
    bg=O_STOPS, accent=PRIMARY,
    eyebrow="iOS 앱 출시",
    pc_title=["레전드스터디+, 이제", "아이폰에서도 만나보세요."],
    mo_title=["레전드스터디+,","이제 아이폰에서도","만나보세요."],
    sub="모의고사·논술 기출을 iOS 앱에서 더 빠르게.",
    cta="App Store에서 다운로드 →", cta_fill=PRIMARY, cta_ink=INK),
 "android-launch": dict(
    bg=O_STOPS, accent=PRIMARY,
    eyebrow="Android 앱 출시",
    pc_title=["레전드스터디+,", "안드로이드 앱 출시!"],
    mo_title=["레전드스터디+,","안드로이드","앱 출시!"],
    sub="구글 플레이에서 지금 바로 설치하세요.",
    cta="Google Play에서 다운로드 →", cta_fill=PRIMARY, cta_ink=INK),
 "lab-beta": dict(
    bg=LAB_STOPS, accent=DARK,
    eyebrow="논술 LAB 베타",
    pc_title=["논술, 내 글에서", "부족한 것이 무엇일까?"],
    mo_title=["논술, 내 글에서","부족한 것이","무엇일까?"],
    sub="인문논술 LAB 베타 오픈 · 매일 무료 첨삭 1회",
    cta="논술 LAB 시작하기 →", cta_fill=PRIMARY, cta_ink=INK),
 # §B university-post promo template (example: 서강대, AVAILABLE state)
 "univ-post-sogang": dict(
    bg=LAB_STOPS, accent=DARK,
    eyebrow="논술 LAB · 첨삭 지원",
    pc_title=["서강대 논술, 내 답안의", "부족한 점을 바로 확인하세요."],
    mo_title=["서강대 논술,","내 답안을","바로 점검하세요."],
    sub="대학별 평가 기준에 맞춘 AI 첨삭 · 베타 매일 무료 1회",
    cta="서강대 논술 첨삭받기 →", cta_fill=PRIMARY, cta_ink=INK),
 # §B template: COMING_SOON state (example 준비중 대학)
 "univ-post-comingsoon": dict(
    bg=O_STOPS, accent=PRIMARY,
    eyebrow="논술 LAB · 준비 중",
    pc_title=["○○대 논술 자료,", "지금 바로 확인해 보세요."],
    mo_title=["○○대 논술 자료,","지금 확인해","보세요."],
    sub="첨삭 지원은 준비 중 · 공식 기출과 자료를 먼저 확인하세요.",
    cta="○○대 논술 자료 확인하기 →", cta_fill=WHITE, cta_ink=INK),
}

for key,b in BANNERS.items():
    pc=pc_banner(b["bg"],b["eyebrow"],b["pc_title"],b["sub"],b["cta"],b["cta_fill"],b["cta_ink"],b["accent"])
    mo=mobile_banner(b["bg"],b["eyebrow"],b["mo_title"],b["sub"],b["cta"],b["cta_fill"],b["cta_ink"],b["accent"])
    (OUT/f"{key}-pc.svg").write_text(pc)
    (OUT/f"{key}-mobile.svg").write_text(mo)
    print("wrote", key)
print("done")

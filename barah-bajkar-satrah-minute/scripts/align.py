"""Align manuscript words to narration timing.

The manuscript is the text authority. The whisper transcript only supplies timing
evidence: manuscript and transcript are compared character by character (after
normalising Devanagari spelling variants), and each manuscript word takes the
times of the transcript characters it matched. Unmatched words are interpolated
between matched neighbours and keep conf=0.

Usage:
  python3 -I scripts/align.py                     # provisional (no transcript)
  python3 -I scripts/align.py work/transcript.large-v3-turbo.json
Writes src/timing/alignment.json.
"""
import difflib
import json
import re
import subprocess
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANUSCRIPT = ROOT / "source-text" / "Barah_Bajkar_Satrah_Minute_Hindi.txt"
AUDIO = ROOT / "public" / "audio" / "narration.mp3"
OUT = ROOT / "src" / "timing" / "alignment.json"
TITLE = "बारह बजकर सत्रह मिनट"

TITLE_SPAN = None
DIGITS = {"22": "बाईस", "10": "दस", "8": "आठ", "17": "सत्रह", "12": "बारह", "11": "ग्यारह"}
STRIP = re.compile(r"[\s“”\"‘’'.,!?।…\-–—:;()\[\]]")


def norm_chars(s: str) -> str:
    s = unicodedata.normalize("NFD", s)
    s = s.replace("़", "")  # nukta
    s = s.replace("ँ", "ं")  # chandrabindu -> anusvara
    s = unicodedata.normalize("NFC", s)
    return STRIP.sub("", s)


def audio_duration() -> float:
    out = subprocess.check_output(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(AUDIO)]
    )
    return round(float(out.strip()), 3)


def load_manuscript():
    paras, words = [], []
    for ln, raw in enumerate(MANUSCRIPT.read_text(encoding="utf-8").splitlines(), start=1):
        text = raw.strip()
        if not text:
            continue
        toks = text.split()
        paras.append({"line": ln, "text": text, "firstWord": len(words), "wordCount": len(toks)})
        for t in toks:
            words.append({"p": len(paras) - 1, "text": t})
    return paras, words


def provisional(paras, words, dur):
    # Proportional to normalised character count, with a fixed pause between paragraphs.
    start, end, pause = 2.2, dur - 0.6, 0.55
    weights = [max(1, len(norm_chars(w["text"]))) + 1.2 for w in words]
    total_pause = pause * (len(paras) - 1)
    rate = (end - start - total_pause) / sum(weights)
    t = start
    last_p = 0
    for w, wt in zip(words, weights):
        if w["p"] != last_p:
            t += pause
            last_p = w["p"]
        w["start"] = round(t, 3)
        t += wt * rate
        w["end"] = round(t, 3)
        w["conf"] = 0.0
    return {"source": "provisional (character-count estimate)", "status": "provisional", "title": None}


def tokens_from_transcript(path: Path):
    """Character stream with times from the transcript's word-level segments.

    Individual whisper tokens can carry partial UTF-8 bytes of Devanagari
    characters, so the decoded segment text is used, with the segment's
    offsets as its time span (DTW token time refines the start when valid).
    """
    data = json.loads(path.read_text(encoding="utf-8"))
    chars = []  # (char, start, end)
    segs = [sg for sg in data["transcription"] if norm_chars(sg.get("text", ""))]
    # The spoken title precedes the story; keep it out of the story alignment.
    tnorm = norm_chars(TITLE)
    acc, k = "", 0
    while k < min(6, len(segs)) and len(acc) < len(tnorm):
        acc += norm_chars(segs[k]["text"])
        k += 1
    global TITLE_SPAN
    if difflib.SequenceMatcher(None, acc, tnorm).ratio() > 0.8:
        TITLE_SPAN = {"start": segs[0]["offsets"]["from"] / 1000.0, "end": segs[k - 1]["offsets"]["to"] / 1000.0}
        segs = segs[k:]
    for seg in segs:
        txt = seg.get("text", "").strip()
        n = norm_chars(DIGITS.get(re.sub(r"[^0-9]", "", txt), txt) if re.fullmatch(r"[0-9]+[.,]?", txt) else txt)
        if not n:
            continue
        s = seg["offsets"]["from"] / 1000.0
        e = seg["offsets"]["to"] / 1000.0
        # A short word stretched over seconds means whisper skipped speech there;
        # cap it so the skipped manuscript words get that time instead.
        e = min(e, s + 0.25 + 0.12 * len(n))
        dtws = [t.get("t_dtw", -1) for t in seg.get("tokens", []) if not t.get("text", "").startswith("[_")]
        dtws = [d / 100.0 for d in dtws if d is not None and d >= 0]
        if dtws and s - 0.3 <= dtws[0] <= e:
            s = min(dtws[0], e - 0.02)
        for i, ch in enumerate(n):
            cs = s + (e - s) * i / len(n)
            ce = s + (e - s) * (i + 1) / len(n)
            chars.append((ch, cs, ce))
    return chars


def aligned(paras, words, transcript: Path, dur, skip=frozenset()):
    tchars = tokens_from_transcript(transcript)
    tstr = "".join(c for c, _, _ in tchars)
    mchars, owner = [], []
    for wi, w in enumerate(words):
        if paras[w["p"]]["line"] in skip:
            continue
        for ch in norm_chars(w["text"]):
            mchars.append(ch)
            owner.append(wi)
    mstr = "".join(mchars)
    sm = difflib.SequenceMatcher(None, mstr, tstr, autojunk=False)
    hits = {}  # word index -> list of (start, end)
    matched_chars = 0
    for a, b, size in sm.get_matching_blocks():
        if size < 2:
            continue
        for k in range(size):
            wi = owner[a + k]
            _, cs, ce = tchars[b + k]
            hits.setdefault(wi, []).append((cs, ce))
            matched_chars += 1
    for wi, w in enumerate(words):
        n = max(1, len(norm_chars(w["text"])))
        h = hits.get(wi)
        if h:
            w["start"] = round(min(x[0] for x in h), 3)
            w["end"] = round(max(x[1] for x in h), 3)
            w["conf"] = round(min(1.0, len(h) / n), 3)
        else:
            w["start"] = w["end"] = None
            w["conf"] = 0.0
    # enforce monotonic times and interpolate gaps
    known = [i for i, w in enumerate(words) if w["start"] is not None and w["conf"] >= 0.5]
    clean = []
    for i in known:
        if clean and words[i]["start"] < words[clean[-1]]["start"]:
            words[i]["conf"] = 0.0
            continue
        clean.append(i)
    for i, w in enumerate(words):
        if w["conf"] < 0.5:
            w["start"] = None
    anchors = [(i, words[i]["start"], words[i]["end"]) for i in clean]
    first_t = anchors[0][1] if anchors else 2.0
    for i, w in enumerate(words):
        if w["start"] is not None:
            continue
        prev = max((a for a in anchors if a[0] < i), default=None, key=lambda a: a[0])
        nxt = min((a for a in anchors if a[0] > i), default=None, key=lambda a: a[0])
        if prev and nxt:
            span = nxt[0] - prev[0]
            frac = (i - prev[0]) / span
            t0 = prev[2] + (nxt[1] - prev[2]) * frac
            t1 = prev[2] + (nxt[1] - prev[2]) * (i - prev[0] + 1) / span
        elif prev:
            t0 = prev[2] + 0.35 * (i - prev[0] - 1)
            t1 = t0 + 0.35
        else:
            t1 = first_t - 0.35 * (nxt[0] - i - 1)
            t0 = t1 - 0.35
        w["start"], w["end"] = round(max(0.0, t0), 3), round(min(dur, t1), 3)
    for i in range(1, len(words)):
        if words[i]["start"] < words[i - 1]["start"]:
            words[i]["start"] = words[i - 1]["start"]
        if words[i]["end"] < words[i]["start"]:
            words[i]["end"] = words[i]["start"]
    title = TITLE_SPAN
    first_b = next((b for a, b, size in sm.get_matching_blocks() if size >= 2), 0)
    pre = tstr[:first_b]
    post = tstr[sm.get_matching_blocks()[-2][1] + sm.get_matching_blocks()[-2][2] :] if len(sm.get_matching_blocks()) > 1 else ""
    stats = {
        "manuscriptChars": len(mstr),
        "transcriptChars": len(tstr),
        "matchedChars": matched_chars,
        "wordsMatched": len(clean),
        "wordsInterpolated": len(words) - len(clean),
        "transcriptBeforeStory": pre,
        "transcriptAfterStory": post,
    }
    return {
        "source": f"{json.loads(transcript.read_text(encoding='utf-8')).get('engine', 'whisper.cpp')} ({transcript.name}) + manuscript char alignment",
        "status": "aligned",
        "title": title,
        "stats": stats,
    }


def detect_silences():
    log = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", str(AUDIO), "-af", "silencedetect=noise=-38dB:d=0.25", "-f", "null", "-"],
        capture_output=True, text=True,
    ).stderr
    st = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", log)]
    en = [float(x) for x in re.findall(r"silence_end: ([\d.]+)", log)]
    return list(zip(st, en))


def trim_to_speech(words, silences):
    """Whisper often stretches a word back over the preceding pause; move such
    starts to the pause end, and pull ends that run into a following pause."""
    for w in words:
        if w["conf"] < 0.5:
            continue
        for ss, se in silences:
            if ss >= w["start"] - 0.05 and se > w["start"] and se < w["end"] + 0.4 and ss < w["end"]:
                w["start"] = round(min(se, w["end"] - 0.05) if se < w["end"] else se, 3)
                w["end"] = round(max(w["end"], w["start"] + 0.08), 3)
            elif w["start"] < ss < w["end"] - 0.05 and se > w["end"]:
                w["end"] = round(max(ss, w["start"] + 0.08), 3)


def snap_paragraph_starts(paras, words, silences):
    """Paragraphs follow a pause in this narration; when the first word was put
    inside that pause (ending before or just after it), move it to the pause end."""
    ends = [se for ss, se in silences if se - ss >= 0.3]
    for p in paras:
        ws = [w for w in words[p["firstWord"] : p["firstWord"] + p["wordCount"]] if not w.get("omitted")]
        if len(ws) < 2:
            continue
        w0, w1 = ws[0], ws[1]
        cand = [pe for pe in ends if w0["start"] < pe <= w0["start"] + 1.3 and pe < w1["start"] + 0.2]
        if cand:
            pe = cand[-1]
            w0["start"] = round(pe, 3)
            w0["end"] = round(max(w0["end"], pe + 0.15), 3)
            if w1["start"] < w0["end"]:
                w1["start"] = w0["end"]
                w1["end"] = round(max(w1["end"], w1["start"] + 0.1), 3)


def mark_omitted(words, t0=0.0):
    """Runs of >= 4 unmatched words squeezed into far less time than they would
    take to say were not spoken in this recording."""
    i = 0
    n = len(words)
    while i < n:
        if words[i]["conf"] >= 0.5:
            i += 1
            continue
        j = i
        while j < n and words[j]["conf"] < 0.5:
            j += 1
        run = words[i:j]
        prev_end = words[i - 1]["end"] if i > 0 else t0
        next_start = words[j]["start"] if j < n else prev_end + 10
        chars = sum(len(norm_chars(w["text"])) for w in run)
        if len(run) >= 4 and (next_start - prev_end) < 0.35 * chars * 0.075:
            for w in run:
                w["omitted"] = True
                w["start"] = w["end"] = round(prev_end, 3)
        i = j


def main():
    dur = audio_duration()
    paras, words = load_manuscript()
    if len(sys.argv) > 1:
        meta = aligned(paras, words, Path(sys.argv[1]), dur)
        # pass 2: paragraphs with almost nothing matched were not read in this
        # recording; exclude them so their words cannot claim other speech
        skip = set()
        for p in paras:
            ws = words[p["firstWord"] : p["firstWord"] + p["wordCount"]]
            if sum(1 for w in ws if w["conf"] >= 0.5) / len(ws) < 0.25 and len(ws) >= 3:
                skip.add(p["line"])
        for w in words:
            w.pop("omitted", None)
        meta = aligned(paras, words, Path(sys.argv[1]), dur, frozenset(skip))
        sil = detect_silences()
        trim_to_speech(words, sil)
        mark_omitted(words, (meta.get("title") or {}).get("end", 0.0))
    else:
        meta = provisional(paras, words, dur)
    if len(sys.argv) > 1:
        snap_paragraph_starts(paras, words, sil)
    for p in paras:
        ws = words[p["firstWord"] : p["firstWord"] + p["wordCount"]]
        spoken = [w for w in ws if not w.get("omitted")]
        p["start"] = (spoken or ws)[0]["start"]
        p["end"] = (spoken or ws)[-1]["end"]
        p["conf"] = round(sum(w["conf"] for w in ws) / len(ws), 3)
        p["omitted"] = not spoken
        if spoken and len(spoken) < len(ws):
            p["omittedWords"] = len(ws) - len(spoken)
    om = [p["line"] for p in paras if p.get("omitted")]
    part = [(p["line"], p["omittedWords"]) for p in paras if p.get("omittedWords")]
    meta["omittedParagraphs"] = om
    meta["partlyOmitted"] = part
    out = {"narrationDuration": dur, **meta, "paragraphs": paras, "words": words}
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=0), encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}: {len(paras)} paragraphs, {len(words)} words, status={meta['status']}")
    if "stats" in meta:
        print(json.dumps(meta["stats"], ensure_ascii=False, indent=1))
    print("omitted paragraphs (not in the recording):", meta.get("omittedParagraphs"))
    print("partly omitted (line, words):", meta.get("partlyOmitted"))
    if meta.get("title"):
        print("title spoken:", meta["title"])


if __name__ == "__main__":
    main()

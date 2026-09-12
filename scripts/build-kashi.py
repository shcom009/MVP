"""Turn a CP949 Kashi note into separate song records, preserving annotations.

Usage: python scripts/build-kashi.py input.txt kashi-collection.js
The source is supplied by the user; generated records remain separate from memo expressions.
"""
import json
import re
import sys
from pathlib import Path


def build(source):
    content = source.read_bytes().decode("cp949")
    sections = re.split(r"(?m)^제목\s*,", content)[1:]
    songs = []
    review = []
    for number, section in enumerate(sections, 1):
        paragraphs = [list(filter(None, (line.strip() for line in block.splitlines())))
                      for block in re.split(r"\n\s*\n", section.strip())]
        header = paragraphs.pop(0)
        title_field = header[0].strip()
        title_parts = re.split(r"\.(?=\s*[^.])", title_field, maxsplit=1)
        pronunciation = title_parts[0].strip()
        meaning = title_parts[1].strip() if len(title_parts) > 1 else ""
        info = next((line.split(",", 1)[1].strip() for line in header[1:]
                     if line.startswith("정보,")), "")
        artist = next((line.split(",", 1)[1].strip() for line in header[1:]
                       if line.startswith("가수,")), "")
        if number == 1 and artist == "요네즈 켄시.우타다 히카루":
            # This metadata was copied from the previous JANE DOE example.
            artist = "EGOIST (에고이스트)"
        if not artist:
            artist = {5: "ROOKiEZ is PUNK'D", 8: "스즈키 코노미", 27: "7!! (세븐웁스)"}.get(number, "")
        lines, notes = [], []
        for paragraph in paragraphs:
            if not paragraph:
                continue
            if paragraph[0] in ("*", "**"):
                paragraph.pop(0)
            if not paragraph:
                continue
            if paragraph[0].startswith("*") and not any(item.startswith("-") for item in paragraph):
                notes.extend(paragraph)
                continue
            if all(item.startswith("*") or item.startswith("(힌트)") for item in paragraph):
                notes.extend(item for item in paragraph if item.strip("* "))
                continue
            if len(paragraph) == 1 and (paragraph[0].startswith("(") or paragraph[0] in ("♪♪", "아아~")):
                lines.append([paragraph[0], ""])
                continue
            if paragraph[0].startswith("(") and len(paragraph) > 1:
                lines.append([paragraph.pop(0), ""])
            current = None
            if number == 32 and len(paragraph) == 2 and not any(item.startswith("-") for item in paragraph):
                paragraph.reverse()  # This song uses Korean meaning before pronunciation.
            if len(paragraph) == 3 and not any(item.startswith("-") for item in paragraph):
                if number == 38 or (number == 18 and paragraph[0].startswith("쿠모가")):
                    paragraph = [paragraph[0], " ".join(paragraph[1:])]
            if len(paragraph) > 3 and all(item.isascii() for item in paragraph):
                lines.extend([item, ""] for item in paragraph)
                continue
            for item in paragraph:
                if number == 19 and item.startswith("*") and not item.startswith("**"):
                    item = item.lstrip("*").strip()
                if item.startswith("*") or item.startswith("(힌트)"):
                    if current is None and len(paragraph)>1 and item.startswith("*") and paragraph.index(item)==0:
                        continue
                    if item.strip("* "):
                        (current[2] if current else notes).append(item)
                    continue
                if item.startswith("-") and not item.startswith("--"):
                    if current:
                        current[1] = (current[1] + " " + item[1:].strip()).strip()
                    else:
                        review.append((number, pronunciation, "뜻만 남은 줄", item))
                    continue
                if current and not current[1]:
                    current[1] = item
                elif current and current[1] and len(paragraph) == 3 and not any(x.startswith("-") for x in paragraph):
                    current[1] += " " + item
                else:
                    current = [item, "", []]
                    lines.append(current)
            if number == 21 and lines and lines[-1][0] == "바로 그대가 있는 곳으로":
                continuation = lines.pop()
                lines[-1][1] += " " + continuation[0]
                lines[-1][2].extend(continuation[2])
        for line in lines:
            if len(line) > 2 and not line[2]:
                line.pop()
        if not artist:
            review.append((number, pronunciation, "가수 미기재", ""))
        if not lines:
            review.append((number, pronunciation, "가사 없음", ""))
        songs.append({"id": -(number + 1), "kind": "kashi", "title": pronunciation,
                      "titlePronunciation": pronunciation, "titleMeaning": meaning,
                      "artist": artist, "info": info, "cover": "", "source": "",
                      "searchTerms": [], "lines": lines, "notes": notes})
    return songs, review


if __name__ == "__main__":
    songs, review = build(Path(sys.argv[1]))
    Path(sys.argv[2]).write_text("// User-provided song notes, separate from Naver Memo expressions.\n"
                                 "window.KASHI_SONGS.push(..." +
                                 json.dumps(songs, ensure_ascii=False, separators=(",", ":")) + ");\n",
                                 encoding="utf-8")
    print(f"songs={len(songs)} lines={sum(len(song['lines']) for song in songs)} "
          f"notes={sum(len(song['notes']) for song in songs)} review={len(review)}")
    for issue in review:
        print(*issue, sep=" | ")

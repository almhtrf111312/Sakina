"""Build the 604-page index from the user's export, without copying its API text.

Usage: python3 tool/build_mushaf.py /path/to/604-page-export.html /path/to/tanzil-uthmani.txt
The bundled Tanzil text is copied byte-for-byte and keeps its notice intact.
"""
import base64
import gzip
import hashlib
import json
import re
import sys
from pathlib import Path

html_path, tanzil_path = map(Path, sys.argv[1:3])
source = html_path.read_text(encoding='utf-8')
marker = 'window.__EMBEDDED_MUSHAF_PAGES__ = '
raw, _ = json.JSONDecoder().raw_decode(source[source.index(marker) + len(marker):])
assert list(map(int, raw)) == list(range(1, 605))

names = re.findall(r'\{ n: (\d+), name: "([^"]+)", ayahs: (\d+), page: (\d+)', source)
assert len(names) == 114 and [int(n[0]) for n in names] == list(range(1, 115))
surahs = [{'name': name, 'count': int(count), 'page': int(page)}
          for _, name, count, page in names]

pages = []
for page in range(1, 605):
    entries = []
    for verse in raw[str(page)]:
        chapter, number = verse['chapter_id'], verse['verse_number']
        assert verse['verse_key'] == f'{chapter}:{number}'
        entries.append([chapter, number])
    assert entries
    pages.append(entries)
keys = [tuple(verse) for page in pages for verse in page]
expected = [(chapter, ayah) for chapter, s in enumerate(surahs, 1)
            for ayah in range(1, s['count'] + 1)]
assert len(keys) == len(set(keys)) == 6236 and keys == expected

raw_text = tanzil_path.read_bytes()
assert b'Tanzil Quran Text (Uthmani, Version 1.1)' in raw_text
text_keys = []
for line in raw_text.decode('utf-8').splitlines():
    if not line or line.startswith('#'):
        continue
    chapter, ayah, text = line.split('|', 2)
    assert text
    text_keys.append((int(chapter), int(ayah)))
assert text_keys == expected

assets = Path(__file__).resolve().parents[1] / 'assets/data'
(assets / 'mushaf_pages.json').write_text(json.dumps(
    {'surahs': surahs, 'pages': pages}, ensure_ascii=False,
    separators=(',', ':')), encoding='utf-8')
# Package the unmodified bytes as deterministic gzip/base64 chunks so the
# offline APK can reconstruct exactly the source file, including its notice.
chunks = assets / 'mushaf'
chunks.mkdir(exist_ok=True)
encoded = base64.b64encode(gzip.compress(raw_text, compresslevel=9, mtime=0)).decode('ascii')
for old in chunks.glob('part_*.txt'):
    old.unlink()
for i, start in enumerate(range(0, len(encoded), 24000)):
    (chunks / f'part_{i:02d}.txt').write_text(encoded[start:start + 24000])
assert gzip.decompress(base64.b64decode(''.join(
    p.read_text() for p in sorted(chunks.glob('part_*.txt'))))) == raw_text
print(f'Validated 604 pages, 114 surahs, 6236 unique ayahs. '
      f'Tanzil SHA-256: {hashlib.sha256(raw_text).hexdigest()}')

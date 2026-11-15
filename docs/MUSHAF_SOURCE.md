# Offline Mushaf source and verification

The app bundles **Tanzil Quran Text, Uthmani version 1.1** in
`assets/data/mushaf/part_*.txt` as gzip/base64 chunks. They decompress
byte-for-byte to the text and its original copyright and CC BY 3.0 notice.
Source: [Tanzil Project](https://tanzil.net/download/).
The bundled copy's SHA-256 is
`4b91f9e6e8ac645d039e4ed85b3be492e795232a31cd22d668ac58238722e26f`.
Do not edit the scripture file.

`assets/data/mushaf_pages.json` stores only chapter names, verse counts,
page starts, and verse-to-page order from the user's 604-page export. Its
Quran.com word and tajweed HTML are not distributed. The export's HTML footer
is truncated, and its tajweed markup disagrees with the word text in many
places. The app therefore renders the unchanged Tanzil text without tajweed
color rules. Surah headings, ayah markers, and theme colors are UI elements.

`tool/build_mushaf.py` checks the page order and the 114 chapters/6236 unique
ayah keys against the Tanzil copy. `test/mushaf_integrity_test.dart` checks the
bundled assets at build time. The 604 page boundaries come from the supplied
export; 56 verses carry word page metadata for the preceding page, so the app
flows complete verses within the exported page groups instead of promising
exact 15-line printed Mushaf pagination.

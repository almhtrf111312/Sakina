import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings/settings_repository.dart';

Map<String, dynamic> _parseMushaf(List<String> sources) {
  final index = jsonDecode(sources[0]) as Map<String, dynamic>;
  final text = utf8.decode(gzip.decode(base64Decode(sources[1])));
  final verses = <String, String>{};
  for (final line in const LineSplitter().convert(text)) {
    if (line.isEmpty || line.startsWith('#')) continue;
    final first = line.indexOf('|');
    final second = line.indexOf('|', first + 1);
    if (first < 0 || second < 0) continue;
    verses['${line.substring(0, first)}:${line.substring(first + 1, second)}'] =
        line.substring(second + 1);
  }
  final pages = index['pages'] as List<dynamic>;
  for (final page in pages) {
    for (final entry in page as List<dynamic>) {
      final ayah = entry as List<dynamic>;
      ayah.add(verses['${ayah[0]}:${ayah[1]}']!);
    }
  }
  return index;
}

// Keep only the parsed data between tab visits; pages and controllers still
// dispose normally. Decompression and parsing both run off the UI isolate.
final mushafDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final index = await rootBundle.loadString('assets/data/mushaf_pages.json');
  final parts = await Future.wait([
    for (var i = 0; i < 16; i++)
      rootBundle.loadString(
          'assets/data/mushaf/part_${i.toString().padLeft(2, '0')}.txt'),
  ]);
  return compute(_parseMushaf, [index, parts.join()]);
});

class MushafScreen extends ConsumerStatefulWidget {
  const MushafScreen({super.key});

  @override
  ConsumerState<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends ConsumerState<MushafScreen> {
  late final PageController _controller;
  late final Future<Map<String, dynamic>> _data;
  int _page = 1;
  List<int> _bookmarks = [];
  double _fontSize = 23;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _page = (prefs.getInt('mushaf_last_page') ?? 1).clamp(1, 604);
    final stored = prefs.getStringList('mushaf_bookmarks');
    final legacy = prefs.getInt('mushaf_bookmark');
    _bookmarks = stored == null
        ? [if (legacy != null) legacy.clamp(1, 604)]
        : stored.map(int.tryParse).whereType<int>()
            .where((page) => page >= 1 && page <= 604).toSet().toList();
    _fontSize = (prefs.getDouble('mushaf_font_size') ?? 23).clamp(17, 34);
    _controller = PageController(initialPage: _page - 1, keepPage: false);
    _data = ref.read(mushafDataProvider.future);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (!_controller.hasClients) return;
    _controller.jumpToPage(page.clamp(1, 604) - 1);
    _rememberPage(page.clamp(1, 604));
  }

  void _rememberPage(int page) {
    if (_page == page) return;
    setState(() => _page = page);
    ref.read(sharedPreferencesProvider).setInt('mushaf_last_page', page);
  }

  String _digits(int n) => n.toString().replaceAllMapped(
      RegExp(r'[0-9]'), (m) => String.fromCharCode(0x0660 + int.parse(m[0]!)));

  String _surahName(List<dynamic> surahs, int index) =>
      (surahs[index - 1] as Map<String, dynamic>)['name'] as String;

  void _showIndex(List<dynamic> surahs) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .72,
        child: Column(children: [
          const Text('فهرس السور', style: TextStyle(fontSize: 20,
              fontWeight: FontWeight.bold)),
          Expanded(child: ListView.builder(
            itemCount: 114,
            itemBuilder: (_, i) {
              final surah = surahs[i] as Map<String, dynamic>;
              return ListTile(
                leading: Text(_digits(i + 1)),
                title: Text(surah['name'] as String),
                subtitle: Text('صفحة ${_digits(surah['page'] as int)}'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _goTo(surah['page'] as int);
                },
              );
            },
          )),
        ]),
      )),
    );
  }

  Future<void> _choosePage() async {
    final value = await showDialog<int>(
      context: context,
      builder: (context) => _PagePicker(page: _page),
    );
    if (mounted && value != null) _goTo(value);
  }

  void _resizeText(double delta) {
    setState(() => _fontSize = (_fontSize + delta).clamp(17, 34));
    ref.read(sharedPreferencesProvider).setDouble('mushaf_font_size', _fontSize);
  }

  Future<void> _showBookmarks() async {
    final current = _page;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * .72),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [
              Text('علامات القراءة', style: Theme.of(sheet).textTheme.titleLarge),
              Text('الصفحة الحالية ${_digits(current)}'),
              const SizedBox(height: 12),
              if (_bookmarks.isEmpty) const ListTile(title: Text('لا توجد علامات محفوظة')),
              for (final page in _bookmarks)
                ListTile(
                  leading: const Icon(Icons.bookmark_outline),
                  title: Text('الصفحة ${_digits(page)}'),
                  onTap: () { Navigator.pop(sheet); _goTo(page); },
                  trailing: page == current ? null : TextButton(
                    onPressed: () {
                      Navigator.pop(sheet);
                      _saveBookmarks([
                        for (final saved in _bookmarks) if (saved != page) saved,
                        if (!_bookmarks.contains(current)) current,
                      ]);
                    },
                    child: const Text('استبدال'),
                  ),
                ),
              FilledButton.icon(
                onPressed: _bookmarks.contains(current) ? null : () {
                  Navigator.pop(sheet);
                  _saveBookmarks([..._bookmarks, current]);
                },
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(_bookmarks.isEmpty ? 'حفظ الصفحة' : 'إضافة علامة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveBookmarks(List<int> pages) async {
    final ok = await ref.read(sharedPreferencesProvider)
        .setStringList('mushaf_bookmarks', pages.map((page) => '$page').toList());
    if (!mounted) return;
    if (ok) setState(() => _bookmarks = pages);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'تم حفظ العلامة' : 'تعذر حفظ العلامة'),
    ));
  }

  Widget _pageView(int number, List<dynamic> verses, List<dynamic> surahs) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? scheme.surface : const Color(0xFFFFF9EC);
    final ink = isDark ? scheme.onSurface : const Color(0xFF201A13);
    final first = verses.first as List<dynamic>;
    final heading = _surahName(surahs, first[0] as int);
    // A page may contain more than one new surah. Render each heading at
    // the verse boundary rather than moving all headings to the page top.
    final sections = <Widget>[];
    int? sectionChapter;
    var sectionSpans = <TextSpan>[];
    void flush() {
      if (sectionSpans.isEmpty) return;
      sections.add(RichText(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
        text: TextSpan(style: TextStyle(fontFamily: 'Amiri', fontSize: _fontSize,
            color: ink, height: 1.85), children: sectionSpans),
      ));
      sectionSpans = [];
    }
    for (final entry in verses) {
      final ayah = entry as List<dynamic>;
      final chapter = ayah[0] as int;
      final verseNumber = ayah[1] as int;
      if (chapter != sectionChapter) {
        flush();
        if (sectionChapter != null || verseNumber == 1) {
          sections.add(Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: accent.withOpacity(.11),
              border: Border.symmetric(horizontal: BorderSide(
                  color: accent.withOpacity(.5))),
            ),
            child: Text('سورة ${_surahName(surahs, chapter)}',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Amiri', fontSize: 22,
                  color: ink, fontWeight: FontWeight.bold)),
          ));
          if (chapter != 1 && chapter != 9 && verseNumber == 1) {
            final words = (ayah[2] as String).split(' ');
            sections.add(Text(words.take(4).join(' '),
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Amiri', fontSize: _fontSize,
                  height: 1.8, color: ink)));
          }
        }
        sectionChapter = chapter;
      }
      final text = ayah[2] as String;
      final displayed = chapter != 1 && chapter != 9 && verseNumber == 1
          ? text.split(' ').skip(4).join(' ') : text;
      sectionSpans.add(TextSpan(text: '$displayed '));
      sectionSpans.add(TextSpan(text: '﴿${_digits(verseNumber)}﴾  ',
          style: TextStyle(color: accent, fontWeight: FontWeight.bold)));
    }
    flush();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(.55), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all(
                color: accent.withOpacity(.35))),
            child: SingleChildScrollView(
              key: PageStorageKey('mushaf-$number'),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(children: [
                Text(heading, style: TextStyle(color: accent, fontSize: 14,
                    fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...sections,
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final surahs = data?['surahs'] as List<dynamic>?;
        final pages = data?['pages'] as List<dynamic>?;
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 4,
            title: Row(
              children: [
                Expanded(child: TextButton(
                  onPressed: pages == null ? null : _choosePage,
                  child: FittedBox(fit: BoxFit.scaleDown,
                    child: Text('${_digits(_page)} / ٦٠٤')),
                )),
                IconButton(tooltip: 'الفهرس', icon: const Icon(Icons.list_alt_rounded),
                  onPressed: surahs == null ? null : () => _showIndex(surahs)),
                IconButton(tooltip: 'علامات القراءة', icon: const Icon(Icons.bookmark_add_outlined),
                  onPressed: pages == null ? null : _showBookmarks),
                IconButton(tooltip: 'تكبير الخط', icon: const Icon(Icons.text_increase),
                  onPressed: pages == null || _fontSize >= 34 ? null : () => _resizeText(1)),
                IconButton(tooltip: 'تصغير الخط', icon: const Icon(Icons.text_decrease),
                  onPressed: pages == null || _fontSize <= 17 ? null : () => _resizeText(-1)),
              ],
            ),
          ),
          body: pages == null || surahs == null
              ? Center(child: snapshot.hasError
                  ? const Text('تعذر فتح المصحف المحلي')
                  : const CircularProgressIndicator())
              : PageView.builder(
                  controller: _controller,
                  itemCount: 604,
                  onPageChanged: (index) => _rememberPage(index + 1),
                  itemBuilder: (_, index) =>
                      _pageView(index + 1, pages[index] as List<dynamic>, surahs),
                ),
        );
      },
    );
  }
}

class _PagePicker extends StatefulWidget {
  const _PagePicker({required this.page});
  final int page;

  @override
  State<_PagePicker> createState() => _PagePickerState();
}

class _PagePickerState extends State<_PagePicker> {
  final _form = GlobalKey<FormState>();

  int? _pageNumber(String? input) {
    final normalized = (input ?? '').trim().replaceAllMapped(
      RegExp('[٠-٩۰-۹]'),
      (match) {
        final code = match[0]!.codeUnitAt(0);
        return (code - (code >= 0x06F0 ? 0x06F0 : 0x0660)).toString();
      },
    );
    final page = int.tryParse(normalized);
    return page != null && page >= 1 && page <= 604 ? page : null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(Icons.menu_book_outlined),
    title: const Text('انتقال إلى صفحة'),
    content: Form(
      key: _form,
      child: TextFormField(
        initialValue: '${widget.page}',
        autofocus: true,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        style: Theme.of(context).textTheme.headlineMedium,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.go,
        decoration: const InputDecoration(
          labelText: 'رقم الصفحة',
          helperText: 'من ١ إلى ٦٠٤',
          border: OutlineInputBorder(),
        ),
        validator: (input) => _pageNumber(input) == null ? 'أدخل رقماً بين ١ و٦٠٤' : null,
        onSaved: (input) => Navigator.pop(context, _pageNumber(input)),
        onFieldSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      FilledButton(onPressed: _submit, child: const Text('انتقال')),
    ],
  );

  void _submit() {
    if (_form.currentState!.validate()) _form.currentState!.save();
  }
}

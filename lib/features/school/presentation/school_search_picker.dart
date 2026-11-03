import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/school.dart';
import '../school_providers.dart';

/// Search drafts never write a profile. Only the parent confirmation saves them.
class SchoolSearchPicker extends ConsumerStatefulWidget {
  const SchoolSearchPicker({
    super.key,
    required this.onChanged,
    this.enabled = true,
    this.onSearchPendingChanged,
    this.inlineSearch = false,
  });
  final ValueChanged<School?> onChanged;
  final bool enabled;
  final bool inlineSearch;

  /// An entered query must be resolved before the parent can confirm a school.
  final ValueChanged<bool>? onSearchPendingChanged;
  @override
  ConsumerState<SchoolSearchPicker> createState() => _SchoolSearchPickerState();
}

class _SchoolSearchPickerState extends ConsumerState<SchoolSearchPicker> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _example = 0, _generation = 0;
  bool _loading = false, _searched = false, _failed = false, _touched = false;
  List<School> _schools = [];
  School? _selected;
  static const _examples = ['서울고등학교', '별내고등학교', '진접고등학교', '경기고등학교'];
  static const _orange = Color(0xFFFFAC14);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    if (!MediaQuery.disableAnimationsOf(context) && !_touched) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted) {
          setState(() => _example = (_example + 1) % _examples.length);
        }
      });
    }
  }

  void _stopHints() {
    _timer?.cancel();
    if (!_touched) setState(() => _touched = true);
  }

  void _change(String _) {
    _stopHints();
    _generation++;
    setState(() {
      _schools = [];
      _selected = null;
      _loading = _searched = _failed = false;
    });
    widget.onChanged(null);
    widget.onSearchPendingChanged?.call(_input.text.trim().isNotEmpty);
  }

  Future<void> _search() async {
    final query = _input.text.trim();
    if (!widget.enabled || query.isEmpty || _loading) return;
    _stopHints();
    _focus.unfocus();
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _failed = false;
      _selected = null;
      _schools = [];
    });
    widget.onChanged(null);
    widget.onSearchPendingChanged?.call(true);
    try {
      // Use the existing repository/API; no persistent catalogue or new endpoint.
      final schools = await ref.read(schoolRepositoryProvider).search(query);
      if (!mounted || generation != _generation) return;
      setState(() {
        _schools = schools;
        _selected = schools.firstOrNull;
        _searched = true;
      });
      widget.onChanged(_selected);
      widget.onSearchPendingChanged?.call(_selected == null);
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _failed = true;
        _searched = true;
      });
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  String _region(School school) =>
      school.address.trim().split(RegExp(r'\s+')).take(2).join(' ');

  String _discriminator(School school) {
    final region = _region(school);
    final ambiguous =
        _schools
            .where((s) => s.name == school.name && _region(s) == region)
            .length >
        1;
    return region.isEmpty
        ? school.identity
        : ambiguous
        ? '$region · ${school.identity}'
        : region;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: _input,
        focusNode: _focus,
        enabled: widget.enabled,
        maxLength: 100,
        textInputAction: TextInputAction.search,
        onTap: _stopHints,
        onChanged: _change,
        onSubmitted: (_) => _search(),
        decoration: InputDecoration(
          labelText: '학교 검색',
          counterText: '',
          prefixIcon: widget.inlineSearch ? null : const Icon(Icons.search),
          suffixIcon: widget.inlineSearch
              ? Padding(
                  padding: const EdgeInsets.all(4),
                  child: OutlinedButton(
                    onPressed:
                        widget.enabled &&
                            !_loading &&
                            _input.text.trim().isNotEmpty
                        ? _search
                        : null,
                    child: Text(_loading ? '검색 중…' : '검색'),
                  ),
                )
              : null,
          hint: ExcludeSemantics(
            child: AnimatedSwitcher(
              duration: _touched || MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 350),
              child: Text(
                _touched ? '학교 이름을 검색해 주세요' : _examples[_example],
                maxLines: widget.inlineSearch ? 1 : null,
                overflow: widget.inlineSearch ? TextOverflow.ellipsis : null,
                key: ValueKey(_touched ? -1 : _example),
              ),
            ),
          ),
        ),
      ),
      if (!widget.inlineSearch) ...[
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed:
              widget.enabled && !_loading && _input.text.trim().isNotEmpty
              ? _search
              : null,
          icon: const Icon(Icons.search),
          label: Text(_loading ? '검색 중…' : '검색'),
        ),
      ],
      if (_searched || _loading)
        const Padding(padding: EdgeInsets.only(top: 16), child: Text('검색 결과')),
      if (_loading) const Center(child: CircularProgressIndicator()),
      if (_failed) ...[
        const Text('학교를 불러오지 못했어요.'),
        TextButton(
          onPressed: widget.enabled ? _search : null,
          child: const Text('다시 시도'),
        ),
      ],
      if (_searched && !_failed && !_loading && _schools.isEmpty)
        const Text('검색 결과가 없어요.'),
      if (_schools.length >= 100) const Text('결과가 많아요. 학교 이름을 더 자세히 입력해 주세요.'),
      for (final school in _schools)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Semantics(
            selected: school.identity == _selected?.identity,
            child: Material(
              color: school.identity == _selected?.identity
                  ? const Color(0xFFFFF3DC)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: school.identity == _selected?.identity
                      ? _orange
                      : const Color(0xFFDCDCDC),
                  width: 1.5,
                ),
              ),
              child: ListTile(
                title: Text(school.name),
                // Only duplicate names need a minimal location discriminator.
                subtitle:
                    _schools.where((s) => s.name == school.name).length > 1
                    ? Text(_discriminator(school))
                    : null,
                trailing: school.identity == _selected?.identity
                    ? const Icon(
                        Icons.check_circle,
                        color: _orange,
                        semanticLabel: '선택됨',
                      )
                    : null,
                onTap: !widget.enabled
                    ? null
                    : () {
                        setState(() => _selected = school);
                        widget.onChanged(school);
                      },
              ),
            ),
          ),
        ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../../config.dart';
import '../../net/game_api.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game_ui.dart';

const _categoryLabels = {
  'history': 'History',
  'literature': 'Literature',
  'football': 'Football',
  'movies': 'Movies',
  'flags': 'Flags',
  'songs': 'Songs',
  'geography': 'Geography',
  'cars': 'Cars',
  'whoPlayer': "Who's the Player",
  'whoCelebrity': "Who's the Celebrity",
};

String _adminError(String code) => switch (code) {
      'bad_admin_key' => 'Wrong admin key',
      'admin_disabled' => 'ADMIN_KEY is not set on the server',
      'bad_category' => 'Pick a category',
      'question_text_empty' => 'Write the question',
      'question_answer_empty' => 'Write the real answer',
      'question_needs_decoys' => 'Add at least 3 wrong answers (one per line)',
      'question_not_arabic' => 'Answers must be Arabic (no English letters)',
      'decoy_is_answer' => 'A wrong answer matches the real one',
      'bad_image_url' => 'Image link must start with https://',
      'unknown_question' => 'That question no longer exists',
      'connection_failed' => "Can't reach the server",
      _ => 'Something went wrong ($code)',
    };

/// The secret entry point: asks for the admin key and, if the server accepts it,
/// opens the question manager. The key is only kept in memory.
Future<void> openAdminEntry(BuildContext context) async {
  final key = TextEditingController();
  final api = GameApi(apiUri());
  String? error;
  var busy = false;
  List<dynamic>? questions;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        Future<void> submit() async {
          setState(() {
            busy = true;
            error = null;
          });
          try {
            final r = await api.send({'type': 'admin_list', 'adminKey': key.text.trim()});
            if (r['error'] != null) {
              setState(() => error = _adminError(r['error'] as String));
            } else {
              questions = r['questions'] as List<dynamic>;
              if (ctx.mounted) Navigator.pop(ctx, true);
              return;
            }
          } catch (_) {
            setState(() => error = _adminError('connection_failed'));
          }
          setState(() => busy = false);
        }

        return AlertDialog(
          backgroundColor: Cave.cream,
          title: Text('ADMIN', style: displayFont(size: 28)),
          content: TextField(
            controller: key,
            autofocus: true,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Admin key',
              prefixIcon: const Icon(Icons.vpn_key_rounded),
              errorText: error,
            ),
            onSubmitted: (_) => busy ? null : submit(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: busy ? null : submit, child: const Text('Enter')),
          ],
        );
      },
    ),
  );
  key.dispose();
  if (ok == true && context.mounted) {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => AdminScreen(api: api, adminKey: key.text.trim(), initial: questions!),
    ));
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.api, required this.adminKey, required this.initial});
  final GameApi api;
  final String adminKey;
  final List<dynamic> initial;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late List<Map<String, dynamic>> _all = _parse(widget.initial);
  String? _category;
  String _search = '';
  bool _busy = false;

  static List<Map<String, dynamic>> _parse(List<dynamic> raw) =>
      raw.cast<Map<String, dynamic>>().toList();

  /// Sends an admin message; on success replaces the list with the fresh one.
  Future<bool> _send(Map<String, Object?> msg) async {
    setState(() => _busy = true);
    try {
      final r = await widget.api.send({...msg, 'adminKey': widget.adminKey});
      if (r['error'] != null) {
        _toast(_adminError(r['error'] as String));
        return false;
      }
      setState(() => _all = _parse(r['questions'] as List<dynamic>));
      return true;
    } catch (_) {
      _toast(_adminError('connection_failed'));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _edit([Map<String, dynamic>? q]) async {
    final saved = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => _QuestionDialog(initial: q, send: (m) => widget.api.send({...m, 'adminKey': widget.adminKey})),
    );
    if (saved == null) return;
    setState(() => _all = _parse(saved['questions'] as List<dynamic>));
    _toast(q == null ? 'Question added' : 'Question saved');
  }

  Future<void> _remove(Map<String, dynamic> q) async {
    final source = q['source'] as String;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Cave.cream,
        title: Text(source == 'edited' ? 'Restore original?' : 'Delete question?'),
        content: ArabicText(q['text'] as String),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(source == 'edited' ? 'Restore' : 'Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await _send({'type': 'admin_delete', 'id': q['id']});
  }

  @override
  Widget build(BuildContext context) {
    final shown = _all.where((q) {
      if (_category != null && q['category'] != _category) return false;
      if (_search.isEmpty) return true;
      return (q['text'] as String).contains(_search) || (q['answer'] as String).contains(_search);
    }).toList();
    final custom = _all.where((q) => q['source'] != 'builtin').length;

    return Scaffold(
      body: CaveBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(child: Text('QUESTIONS', style: displayFont(size: 28))),
                        Text('${_all.length} total · $custom yours', style: displayFont(size: 15)),
                      ],
                    ),
                  ),
                  if (_busy) const LinearProgressIndicator(color: Cave.lava, minHeight: 4),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        prefixIcon: Icon(Icons.search_rounded),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _search = v.trim()),
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      children: [
                        for (final entry in {null: 'All', ..._categoryLabels}.entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(entry.value),
                              selected: _category == entry.key,
                              onSelected: (_) => setState(() => _category = entry.key),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                      itemCount: shown.length,
                      itemBuilder: (_, i) => _QuestionTile(
                        q: shown[i],
                        onTap: () => _edit(shown[i]),
                        onRemove: shown[i]['source'] == 'builtin' ? null : () => _remove(shown[i]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Cave.lava,
        foregroundColor: Cave.gold,
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add question'),
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.q, required this.onTap, required this.onRemove});
  final Map<String, dynamic> q;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final source = q['source'] as String;
    final badge = switch (source) {
      'custom' => 'NEW',
      'edited' => 'EDITED',
      _ => null,
    };
    return Card(
      color: Cave.cream,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Cave.outline, width: 2),
      ),
      child: ListTile(
        onTap: onTap,
        title: ArabicText(q['text'] as String, textAlign: TextAlign.right),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(_categoryLabels[q['category']] ?? '${q['category']}', style: displayFont(size: 13)),
              if (q['level'] == 'hard') Text('HARD', style: displayFont(size: 13, color: Cave.lava)),
              if (badge != null) Text(badge, style: displayFont(size: 13, color: Cave.success)),
              ArabicText('✔ ${q['answer']}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        trailing: onRemove == null
            ? const Icon(Icons.edit_rounded)
            : IconButton(
                tooltip: source == 'edited' ? 'Restore original' : 'Delete',
                icon: Icon(source == 'edited' ? Icons.restore_rounded : Icons.delete_rounded),
                onPressed: onRemove,
              ),
      ),
    );
  }
}

/// Add / edit form. Saves itself and pops with the server's fresh list.
class _QuestionDialog extends StatefulWidget {
  const _QuestionDialog({required this.initial, required this.send});
  final Map<String, dynamic>? initial;
  final Future<Map<String, dynamic>> Function(Map<String, Object?>) send;

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  late final _text = TextEditingController(text: widget.initial?['text'] as String? ?? '');
  late final _answer = TextEditingController(text: widget.initial?['answer'] as String? ?? '');
  late final _aliases = TextEditingController(text: _lines(widget.initial?['aliases']));
  late final _decoys = TextEditingController(text: _lines(widget.initial?['decoys']));
  late final _image = TextEditingController(text: widget.initial?['imageUrl'] as String? ?? '');
  late String _category = widget.initial?['category'] as String? ?? Category.history.name;
  late bool _hard = widget.initial?['level'] == 'hard';
  String? _error;
  bool _busy = false;

  static String _lines(Object? list) => (list as List<dynamic>? ?? const []).join('\n');
  static List<String> _split(String s) =>
      s.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  @override
  void dispose() {
    for (final c in [_text, _answer, _aliases, _decoys, _image]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await widget.send({
        'type': 'admin_save',
        if (widget.initial != null) 'id': widget.initial!['id'],
        'question': {
          'category': _category,
          'level': _hard ? 'hard' : 'normal',
          'text': _text.text,
          'answer': _answer.text,
          'aliases': _split(_aliases.text),
          'decoys': _split(_decoys.text),
          'imageUrl': _image.text,
        },
      });
      if (r['error'] != null) {
        setState(() => _error = _adminError(r['error'] as String));
      } else if (mounted) {
        Navigator.pop(context, r);
        return;
      }
    } catch (_) {
      setState(() => _error = _adminError('connection_failed'));
    }
    if (mounted) setState(() => _busy = false);
  }

  Widget _arabicField(TextEditingController c, String label, {int lines = 1, String? hint}) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextField(
          controller: c,
          textDirection: TextDirection.rtl,
          minLines: lines,
          maxLines: lines == 1 ? 1 : lines + 3,
          decoration: InputDecoration(labelText: label, hintText: hint, alignLabelWithHint: true),
        ),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: Cave.cream,
        title: Text(widget.initial == null ? 'NEW QUESTION' : 'EDIT QUESTION', style: displayFont(size: 26)),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final e in _categoryLabels.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hard question'),
                  value: _hard,
                  onChanged: (v) => setState(() => _hard = v),
                ),
                _arabicField(_text, 'Question', lines: 2),
                _arabicField(_answer, 'Real answer'),
                _arabicField(_aliases, 'Also accepted (one per line, optional)', lines: 2),
                _arabicField(_decoys, 'Wrong answers (one per line, at least 3)', lines: 3),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: _image,
                    decoration: const InputDecoration(labelText: 'Image link https://… (optional)'),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: const TextStyle(color: Cave.lava, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: _busy ? null : _save, child: const Text('Save')),
        ],
      );
}

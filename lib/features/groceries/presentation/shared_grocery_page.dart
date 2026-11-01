import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:miga/core/ui/miga_skeleton.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:miga/features/groceries/domain/grocery_item.dart';
import 'package:miga/features/groceries/presentation/sheets/grocery_list_sheet.dart';
import 'package:miga/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedGroceryPage extends StatefulWidget {
  const SharedGroceryPage({
    super.key,
    required this.client,
    required this.items,
    required this.currency,
    this.canCreate = true,
    this.onUpgrade,
  });
  final SupabaseClient client;
  final List<GroceryItem> items;
  final String currency;
  final bool canCreate;
  final VoidCallback? onUpgrade;
  @override
  State<SharedGroceryPage> createState() => _SharedGroceryPageState();
}

class _SharedGroceryPageState extends State<SharedGroceryPage> {
  List<Map<String, dynamic>> _lists = [];
  Map<String, dynamic>? _selected;
  List<GroceryItem>? _draft;
  int? _draftRevision;
  String? _invitation;
  bool _busy = false, _failed = false, _conflict = false;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  String _draftKey(String id) =>
      'miga.shared.${widget.client.auth.currentUser!.id}.$id';

  Future<void> _cacheDraft() async {
    if (_selected == null || _draft == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      _draftKey(_selected!['id'] as String),
      jsonEncode({
        'revision': _draftRevision,
        'items': _draft!.map((i) => i.toJson()).toList(),
      }),
    )) {
      throw StateError('Draft could not be saved');
    }
  }

  Future<void> _restoreDraft(Map<String, dynamic> list) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_draftKey(list['id'] as String));
    if (!mounted || _selected?['id'] != list['id']) return;
    final draft = encoded == null
        ? null
        : jsonDecode(encoded) as Map<String, dynamic>;
    setState(() {
      _draft = draft == null
          ? null
          : (draft['items'] as List)
                .map((i) => GroceryItem.fromJson(i as Map<String, dynamic>))
                .toList();
      _draftRevision = draft?['revision'] as int?;
      _conflict = _draft != null && _draftRevision != _selected!['revision'];
      _invitation = prefs.getString(
        '${_draftKey(list['id'] as String)}.invitation',
      );
    });
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final lists = await widget.client
          .from('miga_shared_lists')
          .select('id, owner_id, data, revision, created_at')
          .order('created_at');
      if (!mounted) return;
      setState(() => _lists = lists);
      if (_selected != null) {
        final selected = lists
            .where((list) => list['id'] == _selected!['id'])
            .firstOrNull;
        if (selected != null) _select(selected);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _select(Map<String, dynamic> list) {
    unawaited(_subscription?.cancel());
    setState(() => _selected = list);
    unawaited(_restoreDraft(list));
    _subscription = widget.client
        .from('miga_shared_lists')
        .stream(primaryKey: ['id'])
        .eq('id', list['id'] as String)
        .listen(
          (rows) {
            if (!mounted || rows.isEmpty) return;
            setState(() {
              if (_draft != null && rows.first['revision'] != _draftRevision) {
                _conflict = true;
              }
              _selected = rows.first;
            });
          },
          onError: (_) {
            if (mounted) setState(() => _failed = true);
          },
        );
  }

  Future<void> _create() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final result = await widget.client.rpc(
        'miga_create_list',
        params: {'p_data': widget.items.map((i) => i.toJson()).toList()},
      ) as Map;
      if (!mounted) return;
      _invitation = result['invitation'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_draftKey(result['id'] as String)}.invitation',
        _invitation!,
      );
      final row = await widget.client
          .from('miga_shared_lists')
          .select('id, owner_id, data, revision, created_at')
          .eq('id', result['id'])
          .single();
      if (mounted) _select(row);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final l = AppLocalizations.of(context)!;
    final input = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.joinSharedList),
        content: TextField(
          controller: input,
          maxLength: 64,
          decoration: InputDecoration(labelText: l.invitationCode),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.text.trim()),
            child: Text(l.confirmAction),
          ),
        ],
      ),
    );
    // Wait for the dialog's exit animation before disposing its field.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    input.dispose();
    if (!mounted || code == null || _busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final id = await widget.client.rpc(
        'miga_join_list',
        params: {'p_code': code},
      );
      final row = await widget.client
          .from('miga_shared_lists')
          .select('id, owner_id, data, revision, created_at')
          .eq('id', id)
          .single();
      if (mounted) {
        _invitation = null;
        _select(row);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final row = _selected;
    if (row == null || _busy) return;
    final revision = _draftRevision ?? row['revision'] as int;
    final items = await showGroceryList(
      context,
      _draft ??
          (row['data'] as List)
              .map((i) => GroceryItem.fromJson(i as Map<String, dynamic>))
              .toList(),
      currency: widget.currency,
    );
    if (!mounted || items == null) return;
    _draft = items;
    _draftRevision = revision;
    await _saveDraft();
  }

  Future<void> _saveDraft() async {
    if (_draft == null || _busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await _cacheDraft();
      await widget.client.rpc(
        'miga_update_list',
        params: {
          'p_id': _selected!['id'],
          'p_revision': _draftRevision,
          'p_data': _draft!.map((i) => i.toJson()).toList(),
        },
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey(_selected!['id'] as String));
      if (mounted) {
        setState(() {
          _draft = null;
          _draftRevision = null;
          _conflict = false;
        });
      }
      await _load();
    } on PostgrestException catch (error) {
      if (mounted) {
        setState(() {
          _conflict = error.code == '40001';
          _failed = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    final l = AppLocalizations.of(context)!;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.leaveSharedList),
        content: Text(l.sharedListDeleteWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.confirmAction),
          ),
        ],
      ),
    );
    if (!mounted || accepted != true) return;
    setState(() => _busy = true);
    try {
      await widget.client.rpc(
        'miga_leave_list',
        params: {'p_id': _selected!['id']},
      );
      await _subscription?.cancel();
      if (mounted) {
        setState(() {
          _selected = null;
          _draft = null;
          _invitation = null;
        });
      }
      await _load();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final items = (_selected?['data'] as List? ?? []).map(
      (i) => GroceryItem.fromJson(i as Map<String, dynamic>),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.sharedListTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(l.sharedListNote),
            const SizedBox(height: 20),
            if (_busy && _selected == null && _lists.isEmpty)
              const SkeletonRows()
            else if (_busy)
              const LinearProgressIndicator(),
            if (_failed) Text(_conflict ? l.syncConflict : l.cloudUnavailable),
            if (_selected == null) ...[
              FilledButton(
                onPressed: _busy
                    ? null
                    : widget.canCreate
                    ? _create
                    : widget.onUpgrade,
                child: Text(l.createSharedList),
              ),
              TextButton(
                onPressed: _busy ? null : _join,
                child: Text(l.joinSharedList),
              ),
              for (final list in _lists)
                ListTile(
                  title: Text(
                    '${l.sharedListTitle} · ${(list['id'] as String).substring(0, 8)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _select(list),
                ),
              TextButton(
                onPressed: _busy ? null : _load,
                child: Text(l.homeRetry),
              ),
            ] else ...[
              if (_invitation != null)
                TextButton.icon(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: _invitation!)),
                  icon: const Icon(Icons.copy),
                  label: Text(l.copyInvitation),
                ),
              for (final item in items)
                ListTile(
                  leading: Icon(
                    item.checked ? Icons.check_circle : Icons.circle_outlined,
                  ),
                  title: Text(item.name),
                  subtitle: Text('${item.quantity}'),
                ),
              FilledButton(
                onPressed: _busy ? null : _edit,
                child: Text(l.homeGroceryList),
              ),
              if (_draft != null) ...[
                Text(l.sharedDraftSaved),
                if (!_conflict)
                  TextButton(
                    onPressed: _busy ? null : _saveDraft,
                    child: Text(l.homeRetry),
                  ),
                if (_conflict)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            setState(() {
                              _draftRevision = _selected!['revision'] as int;
                              _conflict = false;
                            });
                            _saveDraft();
                          },
                    child: Text(l.keepLocal),
                  ),
                if (_conflict)
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove(_draftKey(_selected!['id'] as String));
                      if (!mounted) return;
                      setState(() {
                        _draft = null;
                        _conflict = false;
                      });
                    },
                    child: Text(l.keepCloud),
                  ),
              ],
              TextButton(
                onPressed: _busy ? null : _leave,
                child: Text(l.leaveSharedList),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

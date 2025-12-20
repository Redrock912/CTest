import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/memo.dart';

class MemoStorage {
  MemoStorage(this._prefs);

  static const _storageKey = 'saved_memos';
  final SharedPreferences _prefs;

  static Future<MemoStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return MemoStorage(prefs);
  }

  Future<List<Memo>> load() async {
    final raw = _prefs.getStringList(_storageKey) ?? <String>[];
    return raw
        .map((item) => Memo.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<Memo> memos) async {
    final serialized = memos.map((memo) => jsonEncode(memo.toJson())).toList();
    await _prefs.setStringList(_storageKey, serialized);
  }
}

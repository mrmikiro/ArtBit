import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/artwork.dart';
import 'database_helper.dart';

/// Abstract storage interface
abstract class StorageHelper {
  Future<void> initialize();
  Future<int> insertArtwork(ArtWork artwork);
  Future<List<ArtWork>> getAllArtworks();
  Future<int> updateArtwork(ArtWork artwork);
  Future<int> deleteArtwork(String id);
  Future<List<String>> getDistinctAuthors();
  Future<List<String>> getDistinctTechniques();
  Future<List<String>> getDistinctFormatos();

  /// Factory that returns the right implementation based on platform
  factory StorageHelper() {
    if (kIsWeb) {
      return WebStorageHelper();
    } else {
      return SqliteStorageHelper();
    }
  }
}

/// SQLite implementation for mobile
class SqliteStorageHelper implements StorageHelper {
  final DatabaseHelper _db = DatabaseHelper();

  @override
  Future<void> initialize() async {
    await _db.database;
  }

  @override
  Future<int> insertArtwork(ArtWork artwork) => _db.insertArtwork(artwork);

  @override
  Future<List<ArtWork>> getAllArtworks() => _db.getAllArtworks();

  @override
  Future<int> updateArtwork(ArtWork artwork) => _db.updateArtwork(artwork);

  @override
  Future<int> deleteArtwork(String id) => _db.deleteArtwork(id);

  @override
  Future<List<String>> getDistinctAuthors() => _db.getDistinctAuthors();

  @override
  Future<List<String>> getDistinctTechniques() => _db.getDistinctTechniques();

  @override
  Future<List<String>> getDistinctFormatos() async {
    final artworks = await _db.getAllArtworks();
    return artworks.map((a) => a.formato).where((f) => f.isNotEmpty).toSet().toList()..sort();
  }
}

/// Persistent implementation for web using SharedPreferences
class WebStorageHelper implements StorageHelper {
  static const _key = 'vault_artworks';
  List<ArtWork> _artworks = [];
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      _artworks = list.map((e) => ArtWork.fromMap(e)).toList();
      // Migration: purge all legacy seed artworks
      final before = _artworks.length;
      _artworks.removeWhere((a) => _isSeedArtwork(a));
      if (_artworks.length != before) await _save();
    } else {
      _artworks = [];
      await _save();
    }
    _initialized = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_artworks.map((a) => a.toMap()).toList());
    await prefs.setString(_key, data);
  }

  static const _seedTitles = {
    'Perro semihundido', 'La noche estrellada', 'Guernica',
    'La persistencia de la memoria', 'El beso', 'Las dos Fridas',
    'Composición VIII', 'El pensador', 'El gran vidrio',
    'Lirios', 'La joven de la perla', 'Latas de sopa Campbell',
    'Sin título (cráneo)',
  };

  bool _isSeedArtwork(ArtWork a) => _seedTitles.contains(a.title);

  @override
  Future<int> insertArtwork(ArtWork artwork) async {
    _artworks.insert(0, artwork);
    await _save();
    return 1;
  }

  @override
  Future<List<ArtWork>> getAllArtworks() async {
    if (!_initialized) await initialize();
    return List.from(_artworks);
  }

  @override
  Future<int> updateArtwork(ArtWork artwork) async {
    final index = _artworks.indexWhere((a) => a.id == artwork.id);
    if (index != -1) {
      _artworks[index] = artwork;
      await _save();
      return 1;
    }
    return 0;
  }

  @override
  Future<int> deleteArtwork(String id) async {
    _artworks.removeWhere((a) => a.id == id);
    await _save();
    return 1;
  }

  @override
  Future<List<String>> getDistinctAuthors() async =>
      _artworks.map((a) => a.author).toSet().toList()..sort();

  @override
  Future<List<String>> getDistinctTechniques() async =>
      _artworks.map((a) => a.technique).where((t) => t.isNotEmpty).toSet().toList()..sort();

  @override
  Future<List<String>> getDistinctFormatos() async =>
      _artworks.map((a) => a.formato).where((f) => f.isNotEmpty).toSet().toList()..sort();
}

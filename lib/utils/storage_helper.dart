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
  Future<List<ArtWork>> searchArtworks({
    String? query,
    String? author,
    String? technique,
    String? modality,
  });
  Future<List<String>> getDistinctAuthors();
  Future<List<String>> getDistinctTechniques();
  Future<List<String>> getDistinctModalities();
  Future<List<String>> getDistinctMovements();

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
  Future<List<ArtWork>> searchArtworks({
    String? query,
    String? author,
    String? technique,
    String? modality,
  }) =>
      _db.searchArtworks(
        query: query,
        author: author,
        technique: technique,
        modality: modality,
      );

  @override
  Future<List<String>> getDistinctAuthors() => _db.getDistinctAuthors();

  @override
  Future<List<String>> getDistinctTechniques() => _db.getDistinctTechniques();

  @override
  Future<List<String>> getDistinctModalities() => _db.getDistinctModalities();

  @override
  Future<List<String>> getDistinctMovements() async {
    final artworks = await _db.getAllArtworks();
    return artworks.map((a) => a.movement).toSet().toList()..sort();
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
      // Migration: remove Goya seed artwork if still present
      final before = _artworks.length;
      _artworks.removeWhere((a) =>
          a.title == 'Perro semihundido' &&
          a.author == 'Francisco de Goya');
      if (_artworks.length != before) await _save();
    } else {
      _seedSampleData();
      await _save();
    }
    _initialized = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_artworks.map((a) => a.toMap()).toList());
    await prefs.setString(_key, data);
  }

  void _seedSampleData() {
    _artworks = [
      ArtWork(title: 'La noche estrellada', author: 'Vincent van Gogh', modality: 'Pintura', technique: 'Óleo', movement: 'Impresionismo', year: 1889, value: 80000000),
      ArtWork(title: 'Guernica', author: 'Pablo Picasso', modality: 'Pintura', technique: 'Óleo', movement: 'Cubismo', year: 1937, value: 200000000),
      ArtWork(title: 'La persistencia de la memoria', author: 'Salvador Dalí', modality: 'Pintura', technique: 'Óleo', movement: 'Surrealismo', year: 1931, value: 150000000),
      ArtWork(title: 'El beso', author: 'Gustav Klimt', modality: 'Pintura', technique: 'Óleo', movement: 'Modernismo', year: 1908, value: 120000000),
      ArtWork(title: 'Las dos Fridas', author: 'Frida Kahlo', modality: 'Pintura', technique: 'Óleo', movement: 'Surrealismo', year: 1939, value: 35000000),
      ArtWork(title: 'Composición VIII', author: 'Wassily Kandinsky', modality: 'Pintura', technique: 'Óleo', movement: 'Arte Abstracto', year: 1923, value: 40000000),
      ArtWork(title: 'El pensador', author: 'Auguste Rodin', modality: 'Escultura', technique: 'Bronce', movement: 'Realismo', year: 1904, value: 15000000),
      ArtWork(title: 'El gran vidrio', author: 'Marcel Duchamp', modality: 'Instalación', technique: 'Mixta', movement: 'Arte Contemporáneo', year: 1923, value: 60000000),
      ArtWork(title: 'Lirios', author: 'Vincent van Gogh', modality: 'Pintura', technique: 'Óleo', movement: 'Impresionismo', year: 1889, value: 53900000),
      ArtWork(title: 'La joven de la perla', author: 'Johannes Vermeer', modality: 'Pintura', technique: 'Óleo', movement: 'Barroco', year: 1665, value: 100000000),
      ArtWork(title: 'Latas de sopa Campbell', author: 'Andy Warhol', modality: 'Grabado', technique: 'Serigrafía', movement: 'Pop Art', year: 1962, value: 11700000),
      ArtWork(title: 'Sin título (cráneo)', author: 'Jean-Michel Basquiat', modality: 'Pintura', technique: 'Acrílico', movement: 'Arte Contemporáneo', year: 1981, value: 110500000),
    ];
  }

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
  Future<List<ArtWork>> searchArtworks({
    String? query,
    String? author,
    String? technique,
    String? modality,
  }) async {
    return _artworks.where((a) {
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        if (!a.title.toLowerCase().contains(q) &&
            !a.author.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (author != null && author.isNotEmpty && a.author != author) return false;
      if (technique != null && technique.isNotEmpty && a.technique != technique) return false;
      if (modality != null && modality.isNotEmpty && a.modality != modality) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<String>> getDistinctAuthors() async =>
      _artworks.map((a) => a.author).toSet().toList()..sort();

  @override
  Future<List<String>> getDistinctTechniques() async =>
      _artworks.map((a) => a.technique).toSet().toList()..sort();

  @override
  Future<List<String>> getDistinctModalities() async =>
      _artworks.map((a) => a.modality).toSet().toList()..sort();

  @override
  Future<List<String>> getDistinctMovements() async =>
      _artworks.map((a) => a.movement).toSet().toList()..sort();
}

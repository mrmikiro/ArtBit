import 'package:flutter/foundation.dart' show kIsWeb;
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

  /// Factory that returns the right implementation based on platform
  factory StorageHelper() {
    if (kIsWeb) {
      return InMemoryStorageHelper();
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
}

/// In-memory implementation for web
class InMemoryStorageHelper implements StorageHelper {
  final List<ArtWork> _artworks = [];

  InMemoryStorageHelper() {
    // Seed with sample data so the web demo isn't empty
    _seedSampleData();
  }

  void _seedSampleData() {
    _artworks.addAll([
      ArtWork(
        title: 'La noche estrellada',
        author: 'Vincent van Gogh',
        modality: 'Pintura',
        technique: 'Óleo',
        movement: 'Impresionismo',
        year: 1889,
        value: 80000000,
      ),
      ArtWork(
        title: 'Guernica',
        author: 'Pablo Picasso',
        modality: 'Pintura',
        technique: 'Óleo',
        movement: 'Cubismo',
        year: 1937,
        value: 200000000,
      ),
      ArtWork(
        title: 'La persistencia de la memoria',
        author: 'Salvador Dalí',
        modality: 'Pintura',
        technique: 'Óleo',
        movement: 'Surrealismo',
        year: 1931,
        value: 150000000,
      ),
      ArtWork(
        title: 'El beso',
        author: 'Gustav Klimt',
        modality: 'Pintura',
        technique: 'Óleo',
        movement: 'Modernismo',
        year: 1908,
        value: 120000000,
      ),
      ArtWork(
        title: 'Las dos Fridas',
        author: 'Frida Kahlo',
        modality: 'Pintura',
        technique: 'Óleo',
        movement: 'Surrealismo',
        year: 1939,
        value: 35000000,
      ),
      ArtWork(
        title: 'Composición VIII',
        author: 'Wassily Kandinsky',
        modality: 'Pintura',
        technique: 'Óleo',
        movement: 'Arte Abstracto',
        year: 1923,
        value: 40000000,
      ),
    ]);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<int> insertArtwork(ArtWork artwork) async {
    _artworks.insert(0, artwork);
    return 1;
  }

  @override
  Future<List<ArtWork>> getAllArtworks() async {
    return List.from(_artworks);
  }

  @override
  Future<int> updateArtwork(ArtWork artwork) async {
    final index = _artworks.indexWhere((a) => a.id == artwork.id);
    if (index != -1) {
      _artworks[index] = artwork;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> deleteArtwork(String id) async {
    _artworks.removeWhere((a) => a.id == id);
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
      if (author != null && author.isNotEmpty && a.author != author) {
        return false;
      }
      if (technique != null && technique.isNotEmpty && a.technique != technique) {
        return false;
      }
      if (modality != null && modality.isNotEmpty && a.modality != modality) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<String>> getDistinctAuthors() async {
    return _artworks.map((a) => a.author).toSet().toList()..sort();
  }

  @override
  Future<List<String>> getDistinctTechniques() async {
    return _artworks.map((a) => a.technique).toSet().toList()..sort();
  }

  @override
  Future<List<String>> getDistinctModalities() async {
    return _artworks.map((a) => a.modality).toSet().toList()..sort();
  }
}

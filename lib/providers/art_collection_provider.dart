import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/artwork.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/storage_helper.dart';

class ArtCollectionProvider extends ChangeNotifier {
  final StorageHelper _localDb = StorageHelper();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  String? _uid;
  bool _useFirebase = false;

  List<ArtWork> _artworks = [];
  List<ArtWork> _filteredArtworks = [];
  List<ArtWork> _featuredArtworks = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _filterAuthor;
  String? _filterTechnique;
  String? _filterFormato;

  List<String> _authors = [];
  List<String> _techniques = [];
  List<String> _formatos = [];

  // Getters
  List<ArtWork> get artworks => _filteredArtworks;
  List<ArtWork> get allArtworks => _artworks;
  List<ArtWork> get featuredArtworks => _featuredArtworks;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get filterAuthor => _filterAuthor;
  String? get filterTechnique => _filterTechnique;
  String? get filterFormato => _filterFormato;
  List<String> get authors => _authors;
  List<String> get techniques => _techniques;
  List<String> get formatos => _formatos;
  bool get hasActiveFilters =>
      _filterAuthor != null ||
      _filterTechnique != null ||
      _filterFormato != null;
  int get totalCount => _artworks.length;
  int get filteredCount => _filteredArtworks.length;

  double get totalCollectionValue =>
      _artworks.fold(0.0, (sum, artwork) => sum + artwork.value);

  List<ArtWork> getWorksByAuthor(String author) =>
      _artworks.where((a) => a.author == author).toList();

  List<ArtWork> getWorksByFormato(String formato) =>
      _artworks.where((a) => a.formato == formato).toList();

  List<ArtWork> getWorksByTechnique(String technique) =>
      _artworks.where((a) => a.technique == technique).toList();


  void refreshFeatured() {
    if (_artworks.length <= 4) {
      _featuredArtworks = List.from(_artworks);
    } else {
      final shuffled = List<ArtWork>.from(_artworks)..shuffle(Random());
      _featuredArtworks = shuffled.take(4).toList();
    }
    notifyListeners();
  }

  /// Load artworks — merges Firebase + local to never lose data
  Future<void> loadArtworks({String? uid}) async {
    _uid = uid;
    _useFirebase = uid != null;
    _isLoading = true;
    notifyListeners();

    try {
      // Always load local data first (our reliable source)
      List<ArtWork> localArtworks = [];
      try {
        localArtworks = await _localDb.getAllArtworks();
        debugPrint('Loaded ${localArtworks.length} artworks from local');
      } catch (e) {
        debugPrint('Local load failed: $e');
      }

      if (_useFirebase) {
        try {
          final firestoreArtworks = await _firestoreService.getAllArtworks(uid!);
          debugPrint('Loaded ${firestoreArtworks.length} artworks from Firestore');

          if (firestoreArtworks.isNotEmpty) {
            // Merge: use Firestore as base, add any local-only artworks
            final firestoreIds = firestoreArtworks.map((a) => a.id).toSet();
            final localOnly = localArtworks.where((a) => !firestoreIds.contains(a.id));
            _artworks = [...firestoreArtworks, ...localOnly];

            // Sync local-only artworks to Firestore
            for (final artwork in localOnly) {
              try {
                await _firestoreService.insertArtwork(uid!, artwork);
                debugPrint('Synced local artwork to Firestore: ${artwork.id}');
              } catch (e) {
                debugPrint('Sync to Firestore failed: $e');
              }
            }
          } else {
            // Firestore empty — use local data
            _artworks = localArtworks;
          }
        } catch (e) {
          debugPrint('Firestore load failed: $e — using local data');
          _artworks = localArtworks;
        }
      } else {
        _artworks = localArtworks;
      }

      // Purge legacy seed artworks (Goya) from all sources
      await _purgeLegacySeedData();

      _refreshFilterOptions();
      _applyFilters();
      refreshFeatured();
    } catch (e) {
      debugPrint('Error loading artworks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// All legacy seed artwork titles that must be purged
  static const _seedTitles = {
    'Perro semihundido', 'La noche estrellada', 'Guernica',
    'La persistencia de la memoria', 'El beso', 'Las dos Fridas',
    'Composición VIII', 'El pensador', 'El gran vidrio',
    'Lirios', 'La joven de la perla', 'Latas de sopa Campbell',
    'Sin título (cráneo)',
  };

  bool _isSeedArtwork(ArtWork a) => _seedTitles.contains(a.title);

  /// Remove all legacy seed artworks from every source.
  Future<void> _purgeLegacySeedData() async {
    final toRemove = _artworks.where(_isSeedArtwork).toList();

    for (final artwork in toRemove) {
      debugPrint('Purging seed artwork: ${artwork.title}');
      if (_useFirebase && _uid != null) {
        try {
          await _firestoreService.deleteArtwork(_uid!, artwork.id);
          await _storageService.deleteWorkFiles(_uid!, artwork.id);
        } catch (e) {
          debugPrint('Firestore purge failed: $e');
        }
      }
      try {
        await _localDb.deleteArtwork(artwork.id);
      } catch (e) {
        debugPrint('Local purge failed: $e');
      }
    }

    if (toRemove.isNotEmpty) {
      _artworks.removeWhere(_isSeedArtwork);
    }
  }

  /// Add a new artwork.
  /// [imageBytesList] — bytes for each new image picked on web.
  Future<void> addArtwork(ArtWork artwork, {List<Uint8List>? imageBytesList}) async {
    try {
      ArtWork savedArtwork = artwork;

      // Persist images
      savedArtwork = await _persistImages(savedArtwork, imageBytesList: imageBytesList);

      // Save to Firebase
      if (_useFirebase && _uid != null) {
        try {
          await _firestoreService.insertArtwork(_uid!, savedArtwork);
          debugPrint('Artwork saved to Firestore: ${savedArtwork.id}');
        } catch (e) {
          debugPrint('Firestore insert failed: $e');
          // Continue — local save is the backup
        }
      }

      // Always save locally as cache/backup
      try {
        await _localDb.insertArtwork(savedArtwork);
      } catch (e) {
        debugPrint('Local insert failed: $e');
      }

      _artworks.insert(0, savedArtwork);
      _refreshFilterOptions();
      _applyFilters();
      refreshFeatured();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding artwork: $e');
      rethrow;
    }
  }

  /// Update an existing artwork.
  /// [imageBytesList] — bytes for each new image picked on web.
  Future<void> updateArtwork(ArtWork artwork, {List<Uint8List>? imageBytesList}) async {
    try {
      ArtWork savedArtwork = artwork;

      // Persist images
      savedArtwork = await _persistImages(savedArtwork, imageBytesList: imageBytesList);

      // Save to Firebase
      if (_useFirebase && _uid != null) {
        try {
          await _firestoreService.updateArtwork(_uid!, savedArtwork);
          debugPrint('Artwork updated in Firestore: ${savedArtwork.id}');
        } catch (e) {
          debugPrint('Firestore update failed: $e');
        }
      }

      // Always save locally
      try {
        await _localDb.updateArtwork(savedArtwork);
      } catch (e) {
        debugPrint('Local update failed: $e');
      }

      final index = _artworks.indexWhere((a) => a.id == savedArtwork.id);
      if (index != -1) {
        _artworks[index] = savedArtwork;
      }
      _refreshFilterOptions();
      _applyFilters();
      refreshFeatured();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating artwork: $e');
      rethrow;
    }
  }

  /// Delete an artwork
  Future<void> deleteArtwork(String id) async {
    try {
      if (_useFirebase && _uid != null) {
        try {
          await _firestoreService.deleteArtwork(_uid!, id);
          await _storageService.deleteWorkFiles(_uid!, id);
        } catch (e) {
          debugPrint('Firestore delete failed: $e');
        }
      }

      // Always delete locally too
      if (!kIsWeb) {
        try {
          final artwork = _artworks.firstWhere((a) => a.id == id);
          if (artwork.imagePath != null &&
              !artwork.imagePath!.startsWith('http') &&
              !artwork.imagePath!.startsWith('data:')) {
            final imageFile = File(artwork.imagePath!);
            if (await imageFile.exists()) {
              await imageFile.delete();
            }
          }
        } catch (_) {}
      }
      try {
        await _localDb.deleteArtwork(id);
      } catch (e) {
        debugPrint('Local delete failed: $e');
      }

      _artworks.removeWhere((a) => a.id == id);
      _refreshFilterOptions();
      _applyFilters();
      refreshFeatured();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting artwork: $e');
      rethrow;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setFilterAuthor(String? author) {
    _filterAuthor = (_filterAuthor == author) ? null : author;
    _applyFilters();
    notifyListeners();
  }

  void setFilterTechnique(String? technique) {
    _filterTechnique = (_filterTechnique == technique) ? null : technique;
    _applyFilters();
    notifyListeners();
  }

  void setFilterFormato(String? formato) {
    _filterFormato = (_filterFormato == formato) ? null : formato;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterAuthor = null;
    _filterTechnique = null;
    _filterFormato = null;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredArtworks = _artworks.where((artwork) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch = artwork.title.toLowerCase().contains(query) ||
            artwork.author.toLowerCase().contains(query) ||
            artwork.technique.toLowerCase().contains(query) ||
            artwork.formato.toLowerCase().contains(query) ||
            artwork.comments.toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }
      if (_filterAuthor != null && artwork.author != _filterAuthor) return false;
      if (_filterTechnique != null && artwork.technique != _filterTechnique) return false;
      if (_filterFormato != null && artwork.formato != _filterFormato) return false;
      return true;
    }).toList();
  }

  void _refreshFilterOptions() {
    _authors = _artworks.map((a) => a.author).toSet().toList()..sort();
    _techniques = _artworks.map((a) => a.technique).where((t) => t.isNotEmpty).toSet().toList()..sort();
    _formatos = _artworks.map((a) => a.formato).where((f) => f.isNotEmpty).toSet().toList()..sort();
  }

  /// Persist all artwork images.
  /// [imageBytesList] contains bytes for newly picked images (index matches
  /// the position in artwork.imagePaths that are NOT yet persisted).
  Future<ArtWork> _persistImages(
    ArtWork artwork, {
    List<Uint8List>? imageBytesList,
  }) async {
    if (artwork.imagePaths.isEmpty) return artwork;

    final persistedPaths = <String>[];
    int bytesIndex = 0;

    for (final path in artwork.imagePaths) {
      // Already persisted (data URI or HTTP URL)
      if (path.startsWith('data:') || path.startsWith('http')) {
        persistedPaths.add(path);
        continue;
      }

      // New image that needs persisting
      final bytes = (imageBytesList != null && bytesIndex < imageBytesList.length)
          ? imageBytesList[bytesIndex++]
          : null;

      if (kIsWeb) {
        if (bytes != null && bytes.isNotEmpty) {
          final b64 = base64Encode(bytes);
          persistedPaths.add('data:image/jpeg;base64,$b64');
          debugPrint('Image ${persistedPaths.length} encoded as base64');
        }
        // Skip unpersistable paths on web
        continue;
      }

      // Mobile: upload to Firebase or copy locally
      if (_useFirebase && _uid != null) {
        try {
          final imgId = '${artwork.id}_${persistedPaths.length}';
          String imageUrl;
          if (bytes != null) {
            imageUrl = await _storageService.uploadWorkImageBytes(
              uid: _uid!, workId: imgId, bytes: bytes,
            );
          } else {
            imageUrl = await _storageService.uploadWorkImage(
              uid: _uid!, workId: imgId, filePath: path,
            );
          }
          persistedPaths.add(imageUrl);
          continue;
        } catch (e) {
          debugPrint('Firebase upload failed for image: $e');
        }
      }

      // Mobile fallback: copy to documents
      final file = File(path);
      if (await file.exists()) {
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${appDir.path}/vault_images');
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }
        final ext = p.extension(path);
        final newPath = '${imagesDir.path}/${artwork.id}_${persistedPaths.length}$ext';
        if (path != newPath) await file.copy(newPath);
        persistedPaths.add(newPath);
      }
    }

    return artwork.copyWith(imagePaths: persistedPaths);
  }
}

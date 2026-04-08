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
  String? _filterModality;

  List<String> _authors = [];
  List<String> _techniques = [];
  List<String> _modalities = [];
  List<String> _movements = [];

  // Getters
  List<ArtWork> get artworks => _filteredArtworks;
  List<ArtWork> get allArtworks => _artworks;
  List<ArtWork> get featuredArtworks => _featuredArtworks;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get filterAuthor => _filterAuthor;
  String? get filterTechnique => _filterTechnique;
  String? get filterModality => _filterModality;
  List<String> get authors => _authors;
  List<String> get techniques => _techniques;
  List<String> get modalities => _modalities;
  List<String> get movements => _movements;
  bool get hasActiveFilters =>
      _filterAuthor != null ||
      _filterTechnique != null ||
      _filterModality != null;
  int get totalCount => _artworks.length;
  int get filteredCount => _filteredArtworks.length;

  double get totalCollectionValue =>
      _artworks.fold(0.0, (sum, artwork) => sum + artwork.value);

  List<ArtWork> getWorksByAuthor(String author) =>
      _artworks.where((a) => a.author == author).toList();

  List<ArtWork> getWorksByModality(String modality) =>
      _artworks.where((a) => a.modality == modality).toList();

  List<ArtWork> getWorksByTechnique(String technique) =>
      _artworks.where((a) => a.technique == technique).toList();

  List<ArtWork> getWorksByMovement(String movement) =>
      _artworks.where((a) => a.movement == movement).toList();

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

  /// Remove legacy seed artworks that should no longer exist.
  Future<void> _purgeLegacySeedData() async {
    final toRemove = _artworks.where((a) =>
        a.title == 'Perro semihundido' && a.author == 'Francisco de Goya',
    ).toList();

    for (final artwork in toRemove) {
      debugPrint('Purging legacy seed artwork: ${artwork.title}');
      // Delete from Firestore
      if (_useFirebase && _uid != null) {
        try {
          await _firestoreService.deleteArtwork(_uid!, artwork.id);
          await _storageService.deleteWorkFiles(_uid!, artwork.id);
        } catch (e) {
          debugPrint('Firestore purge failed: $e');
        }
      }
      // Delete from local storage
      try {
        await _localDb.deleteArtwork(artwork.id);
      } catch (e) {
        debugPrint('Local purge failed: $e');
      }
    }

    if (toRemove.isNotEmpty) {
      _artworks.removeWhere((a) =>
          a.title == 'Perro semihundido' && a.author == 'Francisco de Goya');
    }
  }

  /// Add a new artwork.
  /// [imageBytes] should be provided when picking images on web.
  Future<void> addArtwork(ArtWork artwork, {Uint8List? imageBytes}) async {
    try {
      ArtWork savedArtwork = artwork;

      // Persist image
      savedArtwork = await _persistImage(savedArtwork, imageBytes: imageBytes);

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
  /// [imageBytes] should be provided when picking new images on web.
  Future<void> updateArtwork(ArtWork artwork, {Uint8List? imageBytes}) async {
    try {
      ArtWork savedArtwork = artwork;

      // Persist image
      savedArtwork = await _persistImage(savedArtwork, imageBytes: imageBytes);

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

  void setFilterModality(String? modality) {
    _filterModality = (_filterModality == modality) ? null : modality;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterAuthor = null;
    _filterTechnique = null;
    _filterModality = null;
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
            artwork.movement.toLowerCase().contains(query) ||
            artwork.modality.toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }
      if (_filterAuthor != null && artwork.author != _filterAuthor) return false;
      if (_filterTechnique != null && artwork.technique != _filterTechnique) return false;
      if (_filterModality != null && artwork.modality != _filterModality) return false;
      return true;
    }).toList();
  }

  void _refreshFilterOptions() {
    _authors = _artworks.map((a) => a.author).toSet().toList()..sort();
    _techniques = _artworks.map((a) => a.technique).toSet().toList()..sort();
    _modalities = _artworks.map((a) => a.modality).toSet().toList()..sort();
    _movements = _artworks.map((a) => a.movement).toSet().toList()..sort();
  }

  /// Persist the artwork image.
  /// On web: always encode as base64 data URI (guaranteed to work, no CORS).
  /// On mobile: upload to Firebase Storage or copy to local documents.
  Future<ArtWork> _persistImage(
    ArtWork artwork, {
    Uint8List? imageBytes,
  }) async {
    if (artwork.imagePath == null || artwork.imagePath!.isEmpty) {
      return artwork;
    }
    // Already a data URI — already persisted for web
    if (artwork.imagePath!.startsWith('data:')) {
      return artwork;
    }

    // === WEB: always use base64 data URI (no CORS issues, always works) ===
    if (kIsWeb) {
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final b64 = base64Encode(imageBytes);
        final dataUri = 'data:image/jpeg;base64,$b64';
        debugPrint('Image encoded as base64 data URI (${imageBytes.length} bytes)');

        // Also try Firebase Storage upload in background for cross-device sync
        if (_useFirebase && _uid != null) {
          _storageService.uploadWorkImageBytes(
            uid: _uid!,
            workId: artwork.id,
            bytes: imageBytes,
          ).then((_) => debugPrint('Background upload to Storage OK'))
           .catchError((e) => debugPrint('Background upload failed: $e'));
        }

        return artwork.copyWith(imagePath: dataUri);
      }
      // Already an HTTP URL (from Firestore) — keep it
      if (artwork.imagePath!.startsWith('http')) {
        return artwork;
      }
      // No bytes available — can't persist on web
      debugPrint('WARNING: No image bytes available for web persistence');
      return artwork;
    }

    // === MOBILE: use Firebase Storage URL or local file ===
    if (artwork.imagePath!.startsWith('http')) {
      return artwork;
    }

    if (_useFirebase && _uid != null) {
      try {
        String imageUrl;
        if (imageBytes != null) {
          imageUrl = await _storageService.uploadWorkImageBytes(
            uid: _uid!,
            workId: artwork.id,
            bytes: imageBytes,
          );
        } else {
          imageUrl = await _storageService.uploadWorkImage(
            uid: _uid!,
            workId: artwork.id,
            filePath: artwork.imagePath!,
          );
        }
        debugPrint('Image uploaded to Firebase Storage');
        return artwork.copyWith(imagePath: imageUrl);
      } catch (e) {
        debugPrint('Firebase Storage upload failed: $e');
      }
    }

    return _copyImageToDocuments(artwork);
  }

  Future<ArtWork> _copyImageToDocuments(ArtWork artwork) async {
    if (artwork.imagePath == null) return artwork;

    final file = File(artwork.imagePath!);
    if (!await file.exists()) return artwork;

    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/vault_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final extension = p.extension(artwork.imagePath!);
    final newPath = '${imagesDir.path}/${artwork.id}$extension';

    if (artwork.imagePath != newPath) {
      await file.copy(newPath);
    }

    return artwork.copyWith(imagePath: newPath);
  }
}

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

  /// Load artworks — if uid is provided, use Firebase; otherwise use local storage
  Future<void> loadArtworks({String? uid}) async {
    _uid = uid;
    _useFirebase = uid != null;
    _isLoading = true;
    notifyListeners();

    try {
      if (_useFirebase) {
        _artworks = await _firestoreService.getAllArtworks(uid!);
      } else {
        _artworks = await _localDb.getAllArtworks();
      }
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

  /// Add a new artwork.
  /// [imageBytes] can be provided for reliable web uploads.
  Future<void> addArtwork(ArtWork artwork, {Uint8List? imageBytes}) async {
    try {
      ArtWork savedArtwork = artwork;

      if (_useFirebase && _uid != null) {
        savedArtwork = await _uploadImageIfNeeded(
          artwork,
          imageBytes: imageBytes,
        );
        await _firestoreService.insertArtwork(_uid!, savedArtwork);
      } else {
        savedArtwork = await _saveImageLocally(artwork);
        await _localDb.insertArtwork(savedArtwork);
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
  /// [imageBytes] can be provided for reliable web uploads.
  Future<void> updateArtwork(ArtWork artwork, {Uint8List? imageBytes}) async {
    try {
      ArtWork savedArtwork = artwork;

      if (_useFirebase && _uid != null) {
        savedArtwork = await _uploadImageIfNeeded(
          artwork,
          imageBytes: imageBytes,
        );
        await _firestoreService.updateArtwork(_uid!, savedArtwork);
      } else {
        savedArtwork = await _saveImageLocally(artwork);
        await _localDb.updateArtwork(savedArtwork);
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
        await _firestoreService.deleteArtwork(_uid!, id);
        await _storageService.deleteWorkFiles(_uid!, id);
      } else {
        final artwork = _artworks.firstWhere((a) => a.id == id);
        if (!kIsWeb && artwork.imagePath != null) {
          final imageFile = File(artwork.imagePath!);
          if (await imageFile.exists()) {
            await imageFile.delete();
          }
        }
        await _localDb.deleteArtwork(id);
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

  /// Upload image to Firebase Storage if needed, using bytes when available (web).
  Future<ArtWork> _uploadImageIfNeeded(
    ArtWork artwork, {
    Uint8List? imageBytes,
  }) async {
    if (artwork.imagePath == null || artwork.imagePath!.isEmpty) {
      return artwork;
    }
    // Already an HTTP URL — no upload needed
    if (artwork.imagePath!.startsWith('http')) {
      return artwork;
    }

    String imageUrl;
    if (imageBytes != null) {
      // Use bytes directly — most reliable for web
      imageUrl = await _storageService.uploadWorkImageBytes(
        uid: _uid!,
        workId: artwork.id,
        bytes: imageBytes,
      );
    } else {
      // Upload from file path (mobile)
      imageUrl = await _storageService.uploadWorkImage(
        uid: _uid!,
        workId: artwork.id,
        filePath: artwork.imagePath!,
      );
    }
    return artwork.copyWith(imagePath: imageUrl);
  }

  Future<ArtWork> _saveImageLocally(ArtWork artwork) async {
    if (artwork.imagePath == null) return artwork;
    if (kIsWeb) return artwork;

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

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/artwork.dart';
import '../utils/database_helper.dart';

class ArtCollectionProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<ArtWork> _artworks = [];
  List<ArtWork> _filteredArtworks = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _filterAuthor;
  String? _filterTechnique;
  String? _filterModality;

  // Distinct values for filter chips
  List<String> _authors = [];
  List<String> _techniques = [];
  List<String> _modalities = [];

  // Getters
  List<ArtWork> get artworks => _filteredArtworks;
  List<ArtWork> get allArtworks => _artworks;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get filterAuthor => _filterAuthor;
  String? get filterTechnique => _filterTechnique;
  String? get filterModality => _filterModality;
  List<String> get authors => _authors;
  List<String> get techniques => _techniques;
  List<String> get modalities => _modalities;
  bool get hasActiveFilters =>
      _filterAuthor != null ||
      _filterTechnique != null ||
      _filterModality != null;
  int get totalCount => _artworks.length;
  int get filteredCount => _filteredArtworks.length;

  double get totalCollectionValue =>
      _artworks.fold(0.0, (sum, artwork) => sum + artwork.value);

  /// Load all artworks from database
  Future<void> loadArtworks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _artworks = await _dbHelper.getAllArtworks();
      await _refreshFilterOptions();
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading artworks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new artwork
  Future<void> addArtwork(ArtWork artwork) async {
    try {
      // If there's an image, copy it to app directory
      final savedArtwork = await _saveImageIfNeeded(artwork);
      await _dbHelper.insertArtwork(savedArtwork);
      _artworks.insert(0, savedArtwork);
      await _refreshFilterOptions();
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding artwork: $e');
      rethrow;
    }
  }

  /// Update an existing artwork
  Future<void> updateArtwork(ArtWork artwork) async {
    try {
      final savedArtwork = await _saveImageIfNeeded(artwork);
      await _dbHelper.updateArtwork(savedArtwork);

      final index = _artworks.indexWhere((a) => a.id == savedArtwork.id);
      if (index != -1) {
        _artworks[index] = savedArtwork;
      }
      await _refreshFilterOptions();
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating artwork: $e');
      rethrow;
    }
  }

  /// Delete an artwork
  Future<void> deleteArtwork(String id) async {
    try {
      // Find the artwork to delete its image
      final artwork = _artworks.firstWhere((a) => a.id == id);
      if (artwork.imagePath != null) {
        final imageFile = File(artwork.imagePath!);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }

      await _dbHelper.deleteArtwork(id);
      _artworks.removeWhere((a) => a.id == id);
      await _refreshFilterOptions();
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting artwork: $e');
      rethrow;
    }
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Set filter by author
  void setFilterAuthor(String? author) {
    _filterAuthor = (_filterAuthor == author) ? null : author;
    _applyFilters();
    notifyListeners();
  }

  /// Set filter by technique
  void setFilterTechnique(String? technique) {
    _filterTechnique = (_filterTechnique == technique) ? null : technique;
    _applyFilters();
    notifyListeners();
  }

  /// Set filter by modality
  void setFilterModality(String? modality) {
    _filterModality = (_filterModality == modality) ? null : modality;
    _applyFilters();
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _filterAuthor = null;
    _filterTechnique = null;
    _filterModality = null;
    _applyFilters();
    notifyListeners();
  }

  /// Apply all active filters
  void _applyFilters() {
    _filteredArtworks = _artworks.where((artwork) {
      // Text search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch = artwork.title.toLowerCase().contains(query) ||
            artwork.author.toLowerCase().contains(query) ||
            artwork.technique.toLowerCase().contains(query) ||
            artwork.movement.toLowerCase().contains(query) ||
            artwork.modality.toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }

      // Filter by author
      if (_filterAuthor != null && artwork.author != _filterAuthor) {
        return false;
      }

      // Filter by technique
      if (_filterTechnique != null && artwork.technique != _filterTechnique) {
        return false;
      }

      // Filter by modality
      if (_filterModality != null && artwork.modality != _filterModality) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Refresh the distinct filter options from DB
  Future<void> _refreshFilterOptions() async {
    _authors = await _dbHelper.getDistinctAuthors();
    _techniques = await _dbHelper.getDistinctTechniques();
    _modalities = await _dbHelper.getDistinctModalities();
  }

  /// Save image to app's documents directory if it's from a temp location
  Future<ArtWork> _saveImageIfNeeded(ArtWork artwork) async {
    if (artwork.imagePath == null) return artwork;

    final file = File(artwork.imagePath!);
    if (!await file.exists()) return artwork;

    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/artbit_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final extension = p.extension(artwork.imagePath!);
    final newPath = '${imagesDir.path}/${artwork.id}$extension';

    // Only copy if the file isn't already in our directory
    if (artwork.imagePath != newPath) {
      await file.copy(newPath);
    }

    return ArtWork(
      id: artwork.id,
      title: artwork.title,
      author: artwork.author,
      modality: artwork.modality,
      technique: artwork.technique,
      movement: artwork.movement,
      year: artwork.year,
      imagePath: newPath,
      value: artwork.value,
      createdAt: artwork.createdAt,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artwork.dart';


class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Collection reference for a user's works
  CollectionReference<Map<String, dynamic>> _worksRef(String uid) =>
      _db.collection('users').doc(uid).collection('works');

  /// Create or update user profile
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Insert a new artwork
  Future<void> insertArtwork(String uid, ArtWork artwork) async {
    await _worksRef(uid).doc(artwork.id).set({
      ...artwork.toMap(),
      'userId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get all artworks for a user
  Future<List<ArtWork>> getAllArtworks(String uid) async {
    final snapshot = await _worksRef(uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ArtWork.fromMap(doc.data()))
        .toList();
  }

  /// Update an artwork
  Future<void> updateArtwork(String uid, ArtWork artwork) async {
    await _worksRef(uid).doc(artwork.id).update({
      ...artwork.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete an artwork
  Future<void> deleteArtwork(String uid, String workId) async {
    await _worksRef(uid).doc(workId).delete();
  }

  /// Get distinct values for a field
  Future<List<String>> getDistinctValues(
    String uid,
    String field,
  ) async {
    final snapshot = await _worksRef(uid).get();
    return snapshot.docs
        .map((doc) => doc.data()[field] as String? ?? '')
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }
}

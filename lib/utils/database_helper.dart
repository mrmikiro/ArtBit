import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/artwork.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'artbit.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE artworks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        modality TEXT NOT NULL,
        technique TEXT NOT NULL,
        movement TEXT NOT NULL,
        year INTEGER,
        imagePath TEXT,
        value REAL NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertArtwork(ArtWork artwork) async {
    final db = await database;
    return await db.insert(
      'artworks',
      artwork.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ArtWork>> getAllArtworks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'artworks',
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => ArtWork.fromMap(map)).toList();
  }

  Future<int> updateArtwork(ArtWork artwork) async {
    final db = await database;
    return await db.update(
      'artworks',
      artwork.toMap(),
      where: 'id = ?',
      whereArgs: [artwork.id],
    );
  }

  Future<int> deleteArtwork(String id) async {
    final db = await database;
    return await db.delete(
      'artworks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ArtWork>> searchArtworks({
    String? query,
    String? author,
    String? technique,
    String? modality,
  }) async {
    final db = await database;
    final List<String> conditions = [];
    final List<dynamic> arguments = [];

    if (query != null && query.isNotEmpty) {
      conditions.add('(title LIKE ? OR author LIKE ?)');
      arguments.addAll(['%$query%', '%$query%']);
    }
    if (author != null && author.isNotEmpty) {
      conditions.add('author = ?');
      arguments.add(author);
    }
    if (technique != null && technique.isNotEmpty) {
      conditions.add('technique = ?');
      arguments.add(technique);
    }
    if (modality != null && modality.isNotEmpty) {
      conditions.add('modality = ?');
      arguments.add(modality);
    }

    final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      'artworks',
      where: whereClause,
      whereArgs: arguments.isNotEmpty ? arguments : null,
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => ArtWork.fromMap(map)).toList();
  }

  Future<List<String>> getDistinctAuthors() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT author FROM artworks ORDER BY author');
    return result.map((map) => map['author'] as String).toList();
  }

  Future<List<String>> getDistinctTechniques() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT technique FROM artworks ORDER BY technique');
    return result.map((map) => map['technique'] as String).toList();
  }

  Future<List<String>> getDistinctModalities() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT modality FROM artworks ORDER BY modality');
    return result.map((map) => map['modality'] as String).toList();
  }
}

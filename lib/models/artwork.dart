import 'package:uuid/uuid.dart';

class ArtWork {
  final String id;
  final String title;
  final String author;
  final String modality;
  final String technique;
  final String movement;
  final int? year;
  final String? imagePath;
  final double value;
  final DateTime createdAt;

  ArtWork({
    String? id,
    required this.title,
    required this.author,
    required this.modality,
    required this.technique,
    required this.movement,
    this.year,
    this.imagePath,
    required this.value,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  ArtWork copyWith({
    String? title,
    String? author,
    String? modality,
    String? technique,
    String? movement,
    int? year,
    String? imagePath,
    double? value,
  }) {
    return ArtWork(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      modality: modality ?? this.modality,
      technique: technique ?? this.technique,
      movement: movement ?? this.movement,
      year: year ?? this.year,
      imagePath: imagePath ?? this.imagePath,
      value: value ?? this.value,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'modality': modality,
      'technique': technique,
      'movement': movement,
      'year': year,
      'imagePath': imagePath,
      'value': value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ArtWork.fromMap(Map<String, dynamic> map) {
    return ArtWork(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      modality: map['modality'] as String,
      technique: map['technique'] as String,
      movement: map['movement'] as String,
      year: map['year'] as int?,
      imagePath: map['imagePath'] as String?,
      value: (map['value'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ArtWork && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Predefined options for dropdowns
class ArtworkOptions {
  static const List<String> modalities = [
    'Pintura',
    'Escultura',
    'Fotografía',
    'Grabado',
    'Dibujo',
    'Arte Digital',
    'Instalación',
    'Arte Textil',
    'Cerámica',
    'Mixta',
  ];

  static const List<String> techniques = [
    'Óleo',
    'Acrílico',
    'Acuarela',
    'Temple',
    'Pastel',
    'Carboncillo',
    'Tinta',
    'Collage',
    'Serigrafía',
    'Litografía',
    'Bronce',
    'Mármol',
    'Madera',
    'Digital',
    'Mixta',
  ];

  static const List<String> movements = [
    'Renacimiento',
    'Barroco',
    'Impresionismo',
    'Expresionismo',
    'Cubismo',
    'Surrealismo',
    'Art Déco',
    'Pop Art',
    'Minimalismo',
    'Arte Abstracto',
    'Arte Contemporáneo',
    'Realismo',
    'Romanticismo',
    'Modernismo',
    'Postmodernismo',
  ];
}

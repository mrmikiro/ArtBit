import 'package:uuid/uuid.dart';

class ArtWork {
  final String id;
  final String title;
  final String author;
  final String modality;
  final String technique;
  final String movement;
  final String purchasePlace;
  final String community;
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
    this.movement = '',
    this.purchasePlace = '',
    this.community = '',
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
    String? purchasePlace,
    String? community,
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
      purchasePlace: purchasePlace ?? this.purchasePlace,
      community: community ?? this.community,
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
      'purchasePlace': purchasePlace,
      'community': community,
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
      modality: map['modality'] as String? ?? '',
      technique: map['technique'] as String? ?? '',
      movement: map['movement'] as String? ?? '',
      purchasePlace: map['purchasePlace'] as String? ?? '',
      community: map['community'] as String? ?? '',
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
}

import 'package:uuid/uuid.dart';

class ArtWork {
  final String id;
  final String title;
  final String author;
  final String formato;
  final String technique;
  final String rama;
  final String country;
  final String state;
  final String locality;
  final String purchasePlace;
  final String comments;
  final int? year;
  final List<String> imagePaths;
  final double value;
  final DateTime createdAt;

  ArtWork({
    String? id,
    required this.title,
    required this.author,
    required this.formato,
    this.technique = '',
    this.rama = '',
    this.country = '',
    this.state = '',
    this.locality = '',
    this.purchasePlace = '',
    this.comments = '',
    this.year,
    List<String>? imagePaths,
    // Legacy single image support
    String? imagePath,
    required this.value,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        imagePaths = imagePaths ??
            (imagePath != null && imagePath.isNotEmpty ? [imagePath] : []),
        createdAt = createdAt ?? DateTime.now();

  bool get isArtePopular => formato == 'Arte popular';

  /// First image path (for thumbnails), or null if no images
  String? get imagePath => imagePaths.isNotEmpty ? imagePaths.first : null;

  /// Whether this artwork has any images
  bool get hasImages => imagePaths.isNotEmpty;

  ArtWork copyWith({
    String? title,
    String? author,
    String? formato,
    String? technique,
    String? rama,
    String? country,
    String? state,
    String? locality,
    String? purchasePlace,
    String? comments,
    int? year,
    List<String>? imagePaths,
    double? value,
  }) {
    return ArtWork(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      formato: formato ?? this.formato,
      technique: technique ?? this.technique,
      rama: rama ?? this.rama,
      country: country ?? this.country,
      state: state ?? this.state,
      locality: locality ?? this.locality,
      purchasePlace: purchasePlace ?? this.purchasePlace,
      comments: comments ?? this.comments,
      year: year ?? this.year,
      imagePaths: imagePaths ?? this.imagePaths,
      value: value ?? this.value,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'formato': formato,
      'modality': formato,
      'technique': technique,
      'rama': rama,
      'country': country,
      'state': state,
      'locality': locality,
      'purchasePlace': purchasePlace,
      'comments': comments,
      'year': year,
      'imagePaths': imagePaths,
      // Backwards compat: keep single imagePath for old readers
      'imagePath': imagePath,
      'value': value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ArtWork.fromMap(Map<String, dynamic> map) {
    // Read imagePaths list first, fall back to single imagePath
    List<String> paths = [];
    if (map['imagePaths'] != null) {
      paths = (map['imagePaths'] as List).cast<String>();
    } else if (map['imagePath'] != null &&
        (map['imagePath'] as String).isNotEmpty) {
      paths = [map['imagePath'] as String];
    }

    return ArtWork(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      formato: map['formato'] as String? ??
          map['modality'] as String? ??
          '',
      technique: map['technique'] as String? ?? '',
      rama: map['rama'] as String? ?? '',
      country: map['country'] as String? ?? '',
      state: map['state'] as String? ?? '',
      locality: map['locality'] as String? ?? '',
      purchasePlace: map['purchasePlace'] as String? ?? '',
      comments: map['comments'] as String? ??
          map['movement'] as String? ??
          '',
      year: map['year'] as int?,
      imagePaths: paths,
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
  static const List<String> formatos = [
    'Arte popular',
    'Fotografía',
    'Ilustración',
    'Pintura / dibujo',
    'Otro',
  ];

  static const List<String> ramas = [
    'Barro',
    'Madera',
    'Fibras vegetales',
    'Textiles',
    'Papel',
    'Metales',
    'Cera',
    'Vidrio',
    'Otros',
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

  static const List<String> estadosMexico = [
    'Aguascalientes', 'Baja California', 'Baja California Sur', 'Campeche',
    'Chiapas', 'Chihuahua', 'Ciudad de México', 'Coahuila', 'Colima',
    'Durango', 'Estado de México', 'Guanajuato', 'Guerrero', 'Hidalgo',
    'Jalisco', 'Michoacán', 'Morelos', 'Nayarit', 'Nuevo León', 'Oaxaca',
    'Puebla', 'Querétaro', 'Quintana Roo', 'San Luis Potosí', 'Sinaloa',
    'Sonora', 'Tabasco', 'Tamaulipas', 'Tlaxcala', 'Veracruz', 'Yucatán',
    'Zacatecas',
  ];

  static const List<String> countries = [
    'México',
    'Argentina', 'Bolivia', 'Brasil', 'Chile', 'Colombia', 'Costa Rica',
    'Cuba', 'Ecuador', 'El Salvador', 'Guatemala', 'Haití', 'Honduras',
    'Nicaragua', 'Panamá', 'Paraguay', 'Perú', 'Puerto Rico',
    'República Dominicana', 'Uruguay', 'Venezuela',
    'Alemania', 'Australia', 'Austria', 'Bélgica', 'Canadá', 'China',
    'Corea del Sur', 'Dinamarca', 'Egipto', 'España', 'Estados Unidos',
    'Filipinas', 'Francia', 'Grecia', 'India', 'Indonesia', 'Irlanda',
    'Israel', 'Italia', 'Japón', 'Kenia', 'Marruecos', 'Nigeria',
    'Noruega', 'Nueva Zelanda', 'Países Bajos', 'Polonia', 'Portugal',
    'Reino Unido', 'Rusia', 'Sudáfrica', 'Suecia', 'Suiza', 'Tailandia',
    'Turquía', 'Vietnam', 'Otro',
  ];
}

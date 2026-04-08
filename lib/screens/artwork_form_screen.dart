import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/artwork.dart';
import '../providers/art_collection_provider.dart';
import '../utils/constants.dart';
import '../widgets/artwork_image.dart';

class ArtworkFormScreen extends StatefulWidget {
  final ArtWork? artwork;

  const ArtworkFormScreen({super.key, this.artwork});

  @override
  State<ArtworkFormScreen> createState() => _ArtworkFormScreenState();
}

class _ArtworkFormScreenState extends State<ArtworkFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _techniqueController;
  late TextEditingController _purchasePlaceController;
  late TextEditingController _localityController;
  late TextEditingController _commentsController;
  late TextEditingController _valueController;
  late TextEditingController _yearController;

  String? _formato;
  String? _rama;
  String? _country;
  String? _estadoMexico;

  /// All image paths (persisted data URIs / HTTP URLs + new temp paths)
  List<String> _imagePaths = [];
  /// Bytes for newly picked images (maps to non-persisted entries in _imagePaths)
  List<Uint8List> _newImageBytes = [];

  bool _isSaving = false;

  bool get _isEditing => widget.artwork != null;
  bool get _isArtePopular => _formato == 'Arte popular';
  bool get _isMexico => _country == 'México';

  @override
  void initState() {
    super.initState();
    final a = widget.artwork;
    _titleController = TextEditingController(text: a?.title ?? '');
    _authorController = TextEditingController(text: a?.author ?? '');
    _techniqueController = TextEditingController(text: a?.technique ?? '');
    _purchasePlaceController = TextEditingController(text: a?.purchasePlace ?? '');
    _localityController = TextEditingController(text: a?.locality ?? '');
    _commentsController = TextEditingController(text: a?.comments ?? '');
    _valueController = TextEditingController(
      text: a != null ? a.value.toStringAsFixed(2) : '',
    );
    _yearController = TextEditingController(
      text: a?.year?.toString() ?? '',
    );

    if (a != null) {
      _imagePaths = List.from(a.imagePaths);
      _formato = a.formato.isNotEmpty ? a.formato : null;
      _rama = a.rama.isNotEmpty ? a.rama : null;
      _country = a.country.isNotEmpty ? a.country : null;
      _estadoMexico = a.state.isNotEmpty ? a.state : null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _techniqueController.dispose();
    _purchasePlaceController.dispose();
    _localityController.dispose();
    _commentsController.dispose();
    _valueController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imagePaths.add(image.path);
          _newImageBytes.add(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppColors.textPrimary,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      final path = _imagePaths[index];
      // If it's a new (non-persisted) image, also remove its bytes
      final isPersisted = path.startsWith('data:') || path.startsWith('http');
      if (!isPersisted) {
        // Count how many non-persisted images are before this index
        int bytesIdx = 0;
        for (int i = 0; i < index; i++) {
          final p = _imagePaths[i];
          if (!p.startsWith('data:') && !p.startsWith('http')) bytesIdx++;
        }
        if (bytesIdx < _newImageBytes.length) {
          _newImageBytes.removeAt(bytesIdx);
        }
      }
      _imagePaths.removeAt(index);
    });
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.xl),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Agregar imagen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildImageOption(
                icon: Icons.camera_alt_outlined,
                label: 'Tomar fotografía',
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildImageOption(
                icon: Icons.photo_library_outlined,
                label: 'Seleccionar de galería',
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isDestructive ? AppColors.error : AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400,
                color: isDestructive ? AppColors.error : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  void _onFormatoChanged(String? value) {
    setState(() {
      _formato = value;
      if (!_isArtePopular) {
        _rama = null;
        _country = null;
        _estadoMexico = null;
        _localityController.clear();
      }
    });
  }

  void _onCountryChanged(String? value) {
    setState(() {
      _country = value;
      if (!_isMexico) _estadoMexico = null;
    });
  }

  Future<void> _saveArtwork() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final provider = context.read<ArtCollectionProvider>();

      final artwork = ArtWork(
        id: widget.artwork?.id,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        formato: _formato ?? '',
        technique: _techniqueController.text.trim(),
        rama: _isArtePopular ? (_rama ?? '') : '',
        country: _isArtePopular ? (_country ?? '') : '',
        state: _isArtePopular && _isMexico ? (_estadoMexico ?? '') : '',
        locality: _isArtePopular ? _localityController.text.trim() : '',
        purchasePlace: _purchasePlaceController.text.trim(),
        comments: _commentsController.text.trim(),
        year: _yearController.text.isNotEmpty
            ? int.tryParse(_yearController.text.trim()) : null,
        imagePaths: _imagePaths,
        value: double.parse(_valueController.text.trim()),
        createdAt: widget.artwork?.createdAt,
      );

      if (_isEditing) {
        await provider.updateArtwork(artwork, imageBytesList: _newImageBytes.isNotEmpty ? _newImageBytes : null);
      } else {
        await provider.addArtwork(artwork, imageBytesList: _newImageBytes.isNotEmpty ? _newImageBytes : null);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Editar obra' : 'Nueva obra',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary, letterSpacing: -0.3),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: TextButton(
              onPressed: _isSaving ? null : _saveArtwork,
              child: _isSaving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textSecondary))
                  : const Text('Guardar',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Image gallery picker
            _buildImageGallery(),
            const SizedBox(height: AppSpacing.xl),

            _buildTextField(controller: _titleController, label: 'Título',
                hint: 'Ej: La noche estrellada', validator: _requiredValidator),
            const SizedBox(height: AppSpacing.lg),

            _buildTextField(controller: _authorController, label: 'Autor',
                hint: 'Ej: Vincent van Gogh', validator: _requiredValidator),
            const SizedBox(height: AppSpacing.lg),

            _buildDropdown(label: 'Formato', value: _formato,
                items: ArtworkOptions.formatos, onChanged: _onFormatoChanged,
                validator: (v) => v == null ? 'Campo requerido' : null),
            const SizedBox(height: AppSpacing.lg),

            if (_isArtePopular) ...[
              _buildDropdown(label: 'Rama', value: _rama,
                  items: ArtworkOptions.ramas,
                  onChanged: (v) => setState(() => _rama = v),
                  validator: (v) => v == null ? 'Campo requerido' : null),
              const SizedBox(height: AppSpacing.lg),

              _buildDropdown(label: 'Comunidad (País)', value: _country,
                  items: ArtworkOptions.countries, onChanged: _onCountryChanged),
              const SizedBox(height: AppSpacing.lg),

              if (_isMexico) ...[
                _buildDropdown(label: 'Estado', value: _estadoMexico,
                    items: ArtworkOptions.estadosMexico,
                    onChanged: (v) => setState(() => _estadoMexico = v)),
                const SizedBox(height: AppSpacing.lg),
              ],

              if (_country != null && _country!.isNotEmpty) ...[
                _buildTextField(controller: _localityController,
                    label: 'Localidad', hint: 'Ej: San Bartolo Coyotepec'),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],

            _buildTextField(controller: _techniqueController, label: 'Técnica',
                hint: 'Ej: Óleo sobre lienzo, Barro negro...'),
            const SizedBox(height: AppSpacing.lg),

            _buildTextField(controller: _purchasePlaceController,
                label: 'Lugar de compra', hint: 'Ej: Galería Roma...'),
            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(flex: 2, child: _buildTextField(
                    controller: _yearController, label: 'Año', hint: 'Ej: 1889',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4)])),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 3, child: _buildTextField(
                    controller: _valueController, label: 'Valor (\$)', hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Campo requerido';
                      if (double.tryParse(v.trim()) == null) return 'Valor inválido';
                      return null;
                    })),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            _buildTextField(controller: _commentsController, label: 'Comentarios',
                hint: 'Notas adicionales sobre la obra...', maxLines: 3),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? v) =>
      v == null || v.trim().isEmpty ? 'Campo requerido' : null;

  // ─── Multi-image gallery ───

  Widget _buildImageGallery() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _imagePaths.length + 1, // +1 for "add" button
        itemBuilder: (context, index) {
          if (index == _imagePaths.length) {
            return _buildAddImageButton();
          }
          return _buildImageTile(index);
        },
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImageSourcePicker,
      child: Container(
        width: 140,
        height: 180,
        margin: EdgeInsets.only(left: _imagePaths.isEmpty ? 0 : AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.chipBackground,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.textTertiary),
            SizedBox(height: AppSpacing.sm),
            Text('Agregar foto', style: TextStyle(fontSize: 13, color: AppColors.textTertiary, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(int index) {
    final path = _imagePaths[index];
    final isPersisted = path.startsWith('data:') || path.startsWith('http') || path.startsWith('assets/');

    // Find bytes for non-persisted images
    Uint8List? bytes;
    if (!isPersisted) {
      int bytesIdx = 0;
      for (int i = 0; i < index; i++) {
        final p = _imagePaths[i];
        if (!p.startsWith('data:') && !p.startsWith('http') && !p.startsWith('assets/')) bytesIdx++;
      }
      if (bytesIdx < _newImageBytes.length) bytes = _newImageBytes[bytesIdx];
    }

    return Stack(
      children: [
        Container(
          width: 140,
          height: 180,
          margin: EdgeInsets.only(right: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: bytes != null
              ? Image.memory(bytes, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder())
              : ArtworkImage(imagePath: path, fit: BoxFit.cover),
        ),
        // Remove button
        Positioned(
          top: 6,
          right: AppSpacing.sm + 6,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
        // Counter badge
        if (_imagePaths.length > 1)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Text(
                '${index + 1}/${_imagePaths.length}',
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.chipBackground,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 32, color: AppColors.textTertiary),
      ),
    );
  }

  // ─── Form fields ───

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: AppColors.textTertiary, letterSpacing: 1.2)),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller, keyboardType: keyboardType,
          inputFormatters: inputFormatters, validator: validator,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w400),
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: AppColors.textTertiary, letterSpacing: 1.2)),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textTertiary),
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w400),
          decoration: _inputDecoration('Seleccionar'),
          hint: Text('Seleccionar $label', style: const TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w400)),
          validator: validator,
          items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 16, color: AppColors.textTertiary, fontWeight: FontWeight.w400),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      filled: true, fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: const BorderSide(color: AppColors.textPrimary, width: 1.0)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 0.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.0)),
    );
  }
}

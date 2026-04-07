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
  late TextEditingController _modalityController;
  late TextEditingController _techniqueController;
  late TextEditingController _movementController;
  late TextEditingController _purchasePlaceController;
  late TextEditingController _communityController;
  late TextEditingController _valueController;
  late TextEditingController _yearController;

  String? _imagePath;
  Uint8List? _webImageBytes;
  bool _isSaving = false;

  bool get _isEditing => widget.artwork != null;

  @override
  void initState() {
    super.initState();
    final a = widget.artwork;
    _titleController = TextEditingController(text: a?.title ?? '');
    _authorController = TextEditingController(text: a?.author ?? '');
    _modalityController = TextEditingController(text: a?.modality ?? '');
    _techniqueController = TextEditingController(text: a?.technique ?? '');
    _movementController = TextEditingController(text: a?.movement ?? '');
    _purchasePlaceController = TextEditingController(text: a?.purchasePlace ?? '');
    _communityController = TextEditingController(text: a?.community ?? '');
    _valueController = TextEditingController(
      text: a != null ? a.value.toStringAsFixed(2) : '',
    );
    _yearController = TextEditingController(
      text: a?.year?.toString() ?? '',
    );
    _imagePath = a?.imagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _modalityController.dispose();
    _techniqueController.dispose();
    _movementController.dispose();
    _purchasePlaceController.dispose();
    _communityController.dispose();
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
        // Read bytes for web reliability
        final bytes = await image.readAsBytes();
        setState(() {
          _imagePath = image.path;
          _webImageBytes = bytes;
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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Seleccionar imagen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildImageOption(
                icon: Icons.camera_alt_outlined,
                label: 'Tomar fotografía',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildImageOption(
                icon: Icons.photo_library_outlined,
                label: 'Seleccionar de galería',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_imagePath != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildImageOption(
                  icon: Icons.delete_outline,
                  label: 'Eliminar imagen',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _imagePath = null;
                      _webImageBytes = null;
                    });
                  },
                ),
              ],
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
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDestructive ? AppColors.error : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: isDestructive ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
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
        modality: _modalityController.text.trim(),
        technique: _techniqueController.text.trim(),
        movement: _movementController.text.trim(),
        purchasePlace: _purchasePlaceController.text.trim(),
        community: _communityController.text.trim(),
        year: _yearController.text.isNotEmpty
            ? int.tryParse(_yearController.text.trim())
            : null,
        imagePath: _imagePath,
        value: double.parse(_valueController.text.trim()),
        createdAt: widget.artwork?.createdAt,
      );

      if (_isEditing) {
        await provider.updateArtwork(artwork, imageBytes: _webImageBytes);
      } else {
        await provider.addArtwork(artwork, imageBytes: _webImageBytes);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
          icon: const Icon(
            Icons.close,
            color: AppColors.textPrimary,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Editar obra' : 'Nueva obra',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: TextButton(
              onPressed: _isSaving ? null : _saveArtwork,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : const Text(
                      'Guardar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Image picker
            _buildImagePicker(),

            const SizedBox(height: AppSpacing.xl),

            // Title
            _buildTextField(
              controller: _titleController,
              label: 'Título',
              hint: 'Ej: La noche estrellada',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Author
            _buildTextField(
              controller: _authorController,
              label: 'Autor',
              hint: 'Ej: Vincent van Gogh',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Modality autocomplete
            _buildAutocompleteField(
              controller: _modalityController,
              label: 'Modalidad',
              hint: 'Ej: Pintura, Escultura...',
              suggestions: ArtworkOptions.modalities,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Technique autocomplete
            _buildAutocompleteField(
              controller: _techniqueController,
              label: 'Técnica',
              hint: 'Ej: Óleo sobre lienzo',
              suggestions: ArtworkOptions.techniques,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Movement (free text)
            _buildTextField(
              controller: _movementController,
              label: 'Corriente artística',
              hint: 'Ej: Impresionismo, Arte Contemporáneo...',
            ),

            const SizedBox(height: AppSpacing.lg),

            // Purchase place
            _buildTextField(
              controller: _purchasePlaceController,
              label: 'Lugar de compra',
              hint: 'Ej: Galería Roma, Mercado de Coyoacán...',
            ),

            const SizedBox(height: AppSpacing.lg),

            // Community
            _buildTextField(
              controller: _communityController,
              label: 'Comunidad',
              hint: 'Ej: Oaxaca, San Cristóbal...',
            ),

            const SizedBox(height: AppSpacing.lg),

            // Year and Value in a row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _yearController,
                    label: 'Año',
                    hint: 'Ej: 1889',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    controller: _valueController,
                    label: 'Valor (\$)',
                    hint: '0.00',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Campo requerido';
                      }
                      if (double.tryParse(v.trim()) == null) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImageSourcePicker,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.chipBackground,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _imagePath != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  // Show from bytes if available (freshly picked), otherwise from path
                  _webImageBytes != null
                      ? Image.memory(
                          _webImageBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildImagePlaceholder(),
                        )
                      : ArtworkImage(
                          imagePath: _imagePath,
                          fit: BoxFit.cover,
                        ),
                  Positioned(
                    bottom: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.75),
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.md),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Cambiar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 40,
          color: AppColors.textTertiary,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          'Agregar fotografía',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Cámara o galería',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 16,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: 0.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(
                color: AppColors.textPrimary,
                width: 1.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 0.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required List<String> suggestions,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Autocomplete<String>(
          initialValue: controller.value,
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return suggestions;
            }
            final q = textEditingValue.text.toLowerCase();
            return suggestions
                .where((s) => s.toLowerCase().contains(q))
                .toList();
          },
          onSelected: (value) {
            controller.text = value;
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 12,
                          ),
                          child: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
            // Sync with our controller
            textController.text = controller.text;
            textController.addListener(() {
              if (controller.text != textController.text) {
                controller.text = textController.text;
              }
            });
            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              validator: validator,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                    width: 0.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                    width: 0.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: const BorderSide(
                    color: AppColors.textPrimary,
                    width: 1.0,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 0.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 1.0,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

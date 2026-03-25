import 'package:flutter/material.dart';
import '../../../core/services/image_service.dart';

/// Widget pour permettre à l'utilisateur de choisir et prévisualiser une image
/// Stockable en tant que data URL
class UserProfileImagePicker extends StatefulWidget {
  final String? initialPhotoDataUrl;
  final Function(String dataUrl)? onImagePicked;
  final double size;
  final bool readOnly;

  const UserProfileImagePicker({
    super.key,
    this.initialPhotoDataUrl,
    this.onImagePicked,
    this.size = 120,
    this.readOnly = false,
  });

  @override
  State<UserProfileImagePicker> createState() => _UserProfileImagePickerState();
}

class _UserProfileImagePickerState extends State<UserProfileImagePicker> {
  late String? _currentPhotoDataUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentPhotoDataUrl = widget.initialPhotoDataUrl;
  }

  Future<void> _pickImage() async {
    setState(() => _isLoading = true);

    try {
      final dataUrl = await ImageService.pickAndConvertToDataUrl();
      if (dataUrl != null && mounted) {
        setState(() {
          _currentPhotoDataUrl = dataUrl;
        });
        widget.onImagePicked?.call(dataUrl);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.readOnly ? null : _pickImage,
      child: Stack(
        children: [
          // Image ou Avatar par défaut
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
              border: Border.all(
                color: Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: _buildImage(),
          ),

          // Bouton d'édition (si pas readonly)
          if (!widget.readOnly)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2F5EDB),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    // Si y a une image data URL, l'afficher
    if (_currentPhotoDataUrl != null && _currentPhotoDataUrl!.isNotEmpty) {
      return ClipOval(
        child: ImageService.imageWidgetFromDataUrl(
          _currentPhotoDataUrl!,
          fit: BoxFit.cover,
        ),
      );
    }

    // Sinon, afficher une icône par défaut
    return ClipOval(
      child: Container(
        color: Colors.grey[200],
        child: Icon(
          Icons.person,
          size: widget.size * 0.5,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

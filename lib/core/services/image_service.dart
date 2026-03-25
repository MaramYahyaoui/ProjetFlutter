import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

/// Service pour gérer les uploads d'images
/// Convertit les images en base64 et crée des data URLs
class ImageService {
  /// Max taille image en MB (Firestore limit: 1MB par field)
  /// On limite à 500KB pour être safe
  static const int maxSizeMB = 5;

  /// Extensions d'images autorisées
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];

  /// Sélectionne une image depuis l'appareil
  /// Retourne une data URL (base64) si succès, null sinon
  static Future<String?> pickAndConvertToDataUrl() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('Aucune image sélectionnée');
        return null;
      }

      final file = result.files.single;

      // Vérifier la taille
      final fileSizeInMB = file.size / (1024 * 1024);
      if (fileSizeInMB > maxSizeMB) {
        debugPrint(
          'Image trop grande: ${fileSizeInMB.toStringAsFixed(2)}MB (max: ${maxSizeMB}MB)',
        );
        return null;
      }

      // Récupérer les bytes de l'image
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        debugPrint('Impossible de lire les bytes de l\'image');
        return null;
      }

      // Convertir en base64
      final base64String = base64Encode(bytes);

      // Déterminer le MIME type
      final mimeType = _getMimeType(file.extension ?? 'jpg');

      // Créer une data URL
      final dataUrl = 'data:$mimeType;base64,$base64String';

      debugPrint(
        'Image convertie en data URL - Taille: ${(dataUrl.length / 1024).toStringAsFixed(2)}KB',
      );

      return dataUrl;
    } catch (e) {
      debugPrint('Erreur lors de la conversion de l\'image: $e');
      return null;
    }
  }

  /// Convertit une image File en data URL
  static Future<String?> fileToDataUrl(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      if (bytes.isEmpty) {
        debugPrint('Impossible de lire les bytes du fichier');
        return null;
      }

      // Vérifier la taille
      final fileSizeInMB = bytes.length / (1024 * 1024);
      if (fileSizeInMB > maxSizeMB) {
        debugPrint(
          'Image trop grande: ${fileSizeInMB.toStringAsFixed(2)}MB (max: ${maxSizeMB}MB)',
        );
        return null;
      }

      // Convertir en base64
      final base64String = base64Encode(bytes);

      // Déterminer le MIME type
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      // Créer une data URL
      final dataUrl = 'data:$mimeType;base64,$base64String';

      debugPrint(
        'Fichier converti en data URL - Taille: ${(dataUrl.length / 1024).toStringAsFixed(2)}KB',
      );

      return dataUrl;
    } catch (e) {
      debugPrint('Erreur lors de la conversion du fichier: $e');
      return null;
    }
  }

  /// Obtient le MIME type basé sur l'extension
  static String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Rédimensionne une image (optionnel)
  /// Utile pour compresser les images avant conversion
  static Future<String?> pickCompressAndConvertToDataUrl({
    int maxWidth = 800,
    int maxHeight = 800,
  }) async {
    // Note: Pour la compression, il faudrait ajouter image_picker avec compression
    // ou utiliser flutter_image compressor
    // Pour maintenant, on se contente de pickAndConvertToDataUrl()
    return pickAndConvertToDataUrl();
  }

  /// Extrait les informations d'une data URL
  static Map<String, String>? parseDataUrl(String dataUrl) {
    try {
      final regex = RegExp(r'data:([^;]+);base64,(.+)');
      final match = regex.firstMatch(dataUrl);

      if (match == null) return null;

      return {
        'mimeType': match.group(1) ?? 'image/jpeg',
        'base64': match.group(2) ?? '',
      };
    } catch (e) {
      debugPrint('Erreur lors du parsing de la data URL: $e');
      return null;
    }
  }

  /// Convertit une data URL en Image Widget
  static Widget imageWidgetFromDataUrl(
    String dataUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.memory(
      base64Decode(_extractBase64(dataUrl)),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: const Color(0xFFE0E0E0),
          child: const Icon(Icons.image_not_supported),
        );
      },
    );
  }

  /// Extrait la partie base64 d'une data URL
  static String _extractBase64(String dataUrl) {
    try {
      return dataUrl.split(',').last;
    } catch (e) {
      debugPrint('Erreur lors de l\'extraction du base64: $e');
      return '';
    }
  }
}

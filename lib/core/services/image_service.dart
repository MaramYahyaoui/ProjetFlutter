import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image/image.dart' as img;

/// Service pour gérer les uploads d'images
/// Convertit les images en base64 et crée des data URLs
class ImageService {
  // NOTE: stocker une photo en base64 dans Firestore est fragile.
  // Pour éviter les crashes natifs (SQLiteBlobTooBigException), on force une
  // version compressée "thumbnail" en JPEG sous une taille sûre.

  /// Taille max acceptée du fichier source (lecture mémoire)
  static const int _maxInputBytes = 10 * 1024 * 1024; // 10MB

  /// Taille max du JPEG final (avant base64). Base64 ~ +33%.
  static const int _maxOutputBytes = 160 * 1024; // 160KB

  /// Extensions d'images autorisées
  static const List<String> allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  /// Sélectionne une image depuis l'appareil
  /// Retourne une data URL (base64) si succès, null sinon
  static Future<String?> pickAndConvertToDataUrl() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: true,
        withReadStream: true,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('Aucune image sélectionnée');
        return null;
      }

      final file = result.files.single;

      if (file.size > _maxInputBytes) {
        debugPrint(
          'Image trop grande: ${(file.size / (1024 * 1024)).toStringAsFixed(2)}MB (max: ${(_maxInputBytes / (1024 * 1024)).toStringAsFixed(0)}MB)',
        );
        return null;
      }

      // Récupérer les bytes de l'image
      Uint8List? bytes = file.bytes;

      // Fallback Android/Desktop: lire depuis le path si bytes non fournis
      if (bytes == null || bytes.isEmpty) {
        final path = file.path;
        if (path != null && path.isNotEmpty) {
          try {
            bytes = await File(path).readAsBytes();
          } catch (e) {
            debugPrint('Erreur lecture fichier image via path: $e');
          }
        }
      }

      // Fallback: lire depuis le stream si disponible
      if (bytes == null || bytes.isEmpty) {
        final stream = file.readStream;
        if (stream != null) {
          final builder = BytesBuilder(copy: false);
          await for (final chunk in stream) {
            builder.add(chunk);
          }
          bytes = builder.takeBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) {
        debugPrint('Impossible de lire les bytes de l\'image');
        return null;
      }

      // Compresser/redimensionner pour Firestore (évite base64 énorme)
      final compressedBytes = await _compressToFirestoreSafeJpeg(bytes);
      if (compressedBytes.isEmpty) {
        debugPrint('Compression image échouée');
        return null;
      }

      // Convertir en base64
      final base64String = base64Encode(compressedBytes);

      // Stocker en JPEG (compact)
      const mimeType = 'image/jpeg';

      // Créer une data URL
      final dataUrl = 'data:$mimeType;base64,$base64String';

      debugPrint(
        'Image compressée en data URL - Input: ${(bytes.length / 1024).toStringAsFixed(1)}KB, Output: ${(compressedBytes.length / 1024).toStringAsFixed(1)}KB, DataUrl: ${(dataUrl.length / 1024).toStringAsFixed(1)}KB',
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

      if (bytes.length > _maxInputBytes) {
        debugPrint(
          'Image trop grande: ${(bytes.length / (1024 * 1024)).toStringAsFixed(2)}MB (max: ${(_maxInputBytes / (1024 * 1024)).toStringAsFixed(0)}MB)',
        );
        return null;
      }

      final compressedBytes = await _compressToFirestoreSafeJpeg(bytes);
      if (compressedBytes.isEmpty) {
        debugPrint('Compression image échouée');
        return null;
      }

      final base64String = base64Encode(compressedBytes);
      const mimeType = 'image/jpeg';
      final dataUrl = 'data:$mimeType;base64,$base64String';

      debugPrint(
        'Fichier compressé en data URL - Input: ${(bytes.length / 1024).toStringAsFixed(1)}KB, Output: ${(compressedBytes.length / 1024).toStringAsFixed(1)}KB, DataUrl: ${(dataUrl.length / 1024).toStringAsFixed(1)}KB',
      );

      return dataUrl;
    } catch (e) {
      debugPrint('Erreur lors de la conversion du fichier: $e');
      return null;
    }
  }

  static Future<Uint8List> _compressToFirestoreSafeJpeg(Uint8List input) async {
    // Décode l'image (jpeg/png/webp/gif...).
    final decoded = img.decodeImage(input);
    if (decoded == null) {
      debugPrint('Impossible de décoder l\'image pour compression');
      return Uint8List(0);
    }

    // On essaye plusieurs tailles + qualités jusqu'à passer sous la limite.
    // (Ordre: resize d'abord, puis quality)
    const targetSizes = [512, 384, 320, 256, 192];
    const qualities = [85, 75, 65, 55, 45, 35];

    for (final maxSide in targetSizes) {
      final resized = _resizeKeepAspect(decoded, maxSide);
      for (final q in qualities) {
        final jpg = img.encodeJpg(resized, quality: q);
        if (jpg.length <= _maxOutputBytes) {
          return Uint8List.fromList(jpg);
        }
      }
    }

    // Dernier recours: très petit + qualité basse.
    final tiny = _resizeKeepAspect(decoded, 160);
    final jpg = img.encodeJpg(tiny, quality: 25);
    if (jpg.length <= _maxOutputBytes) {
      return Uint8List.fromList(jpg);
    }

    debugPrint(
      'Image toujours trop grosse après compression: ${(jpg.length / 1024).toStringAsFixed(1)}KB (max ${( _maxOutputBytes / 1024).toStringAsFixed(0)}KB)',
    );
    return Uint8List(0);
  }

  static img.Image _resizeKeepAspect(img.Image src, int maxSide) {
    final w = src.width;
    final h = src.height;
    if (w <= maxSide && h <= maxSide) return src;

    if (w >= h) {
      final newW = maxSide;
      final newH = (h * (maxSide / w)).round().clamp(1, maxSide);
      return img.copyResize(src, width: newW, height: newH);
    } else {
      final newH = maxSide;
      final newW = (w * (maxSide / h)).round().clamp(1, maxSide);
      return img.copyResize(src, width: newW, height: newH);
    }
  }

  /// Rédimensionne une image (optionnel)
  /// Utile pour compresser les images avant conversion
  static Future<String?> pickCompressAndConvertToDataUrl({
    int maxWidth = 800,
    int maxHeight = 800,
  }) async {
    // Conservé pour compat: désormais pickAndConvertToDataUrl() compresse déjà.
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

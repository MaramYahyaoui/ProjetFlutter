# Flutter ↔ Brand Identification API — Integration Guide

This document explains how to connect the Flutter application to the Python
inference API and display brand-identification results in the UI.

---

## 1. Architecture overview

```
┌─────────────────────┐     HTTP POST /predict     ┌──────────────────────┐
│   Flutter App       │ ─────────────────────────► │  FastAPI (Python)     │
│  (image picker UI)  │ ◄───────────────────────── │  inference_api.py     │
└─────────────────────┘     JSON response           └──────────────────────┘
                                                            │
                                                    TF SavedModel
                                                    (EfficientNetB0)
```

---

## 2. Run the API locally (development)

```bash
cd brand_identification
pip install -r requirements.txt

# Train the model first (or point MODEL_DIR to a pre-trained one)
python train_brand_classifier.py --data_dir data/fashion_brands --epochs 20

# Start the inference server
uvicorn inference_api:app --host 0.0.0.0 --port 8000
```

Test that it works:
```bash
curl http://localhost:8000/health
# {"status":"ok","num_classes":67}
```

---

## 3. Add dependencies to pubspec.yaml

```yaml
dependencies:
  http: ^1.2.0
  image_picker: ^1.1.0
```

Run `flutter pub get` after editing.

---

## 4. Dart service layer

Create `lib/services/brand_identification_service.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Represents a single brand prediction from the API.
class BrandPrediction {
  final String brand;
  final double confidence;

  const BrandPrediction({required this.brand, required this.confidence});

  factory BrandPrediction.fromJson(Map<String, dynamic> json) =>
      BrandPrediction(
        brand: json['brand'] as String,
        confidence: (json['confidence'] as num).toDouble(),
      );
}

/// Full response from POST /predict
class BrandIdentificationResult {
  final String brand;
  final double confidence;
  final List<BrandPrediction> topK;

  const BrandIdentificationResult({
    required this.brand,
    required this.confidence,
    required this.topK,
  });

  factory BrandIdentificationResult.fromJson(Map<String, dynamic> json) =>
      BrandIdentificationResult(
        brand: json['brand'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        topK: (json['top_k'] as List<dynamic>)
            .map((e) => BrandPrediction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Service that calls the brand-identification API.
class BrandIdentificationService {
  /// Change this base URL for production deployment.
  static const String _baseUrl = 'http://10.0.2.2:8000'; // Android emulator → localhost

  /// Identify the brand in [imageFile].
  /// Returns [BrandIdentificationResult] or throws on failure.
  static Future<BrandIdentificationResult> identifyBrand(File imageFile) async {
    final uri = Uri.parse('$_baseUrl/predict');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return BrandIdentificationResult.fromJson(json);
    } else {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
  }
}
```

---

## 5. Example UI widget

Create `lib/presentation/pages/brand_identification_page.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/brand_identification_service.dart';

class BrandIdentificationPage extends StatefulWidget {
  const BrandIdentificationPage({super.key});

  @override
  State<BrandIdentificationPage> createState() => _BrandIdentificationPageState();
}

class _BrandIdentificationPageState extends State<BrandIdentificationPage> {
  File? _selectedImage;
  BrandIdentificationResult? _result;
  bool _isLoading = false;
  String? _error;

  Future<void> _pickAndIdentify() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _result = null;
      _error = null;
      _isLoading = true;
    });

    try {
      final result = await BrandIdentificationService.identifyBrand(_selectedImage!);
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identification de Marque')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_selectedImage!, height: 250, fit: BoxFit.cover),
              )
            else
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image_outlined, size: 80, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndIdentify,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choisir une image'),
            ),
            const SizedBox(height: 24),
            // Loading
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            // Error
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            // Result
            if (_result != null) ...[
              Text(
                'Marque détectée : ${_result!.brand}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Confiance : ${(_result!.confidence * 100).toStringAsFixed(1)} %',
              ),
              const Divider(height: 32),
              const Text('Top prédictions :', style: TextStyle(fontWeight: FontWeight.bold)),
              ...(_result!.topK.asMap().entries.map((entry) {
                final i = entry.key;
                final pred = entry.value;
                return ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(pred.brand),
                  trailing: Text('${(pred.confidence * 100).toStringAsFixed(1)} %'),
                );
              })),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## 6. Navigate to the page

In any existing page (e.g. the main dashboard), add a button:

```dart
ElevatedButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const BrandIdentificationPage()),
  ),
  child: const Text('Identifier une marque'),
),
```

---

## 7. API base URL per environment

| Environment | URL to use in `_baseUrl` |
|---|---|
| Android emulator → local PC | `http://10.0.2.2:8000` |
| iOS simulator → local PC | `http://127.0.0.1:8000` |
| Physical device (same Wi-Fi) | `http://<your-PC-IP>:8000` |
| Deployed server | `https://your-server.com` |

---

## 8. Deployment options

| Option | Complexity | Cost |
|---|---|---|
| Local dev (uvicorn) | ★☆☆ | Free |
| Docker + any cloud VPS | ★★☆ | Low |
| Google Cloud Run | ★★☆ | Pay-per-request |
| TensorFlow Serving (gRPC) | ★★★ | Free (self-host) |

For a school project, **local uvicorn** during demos is perfectly fine.

# Brand Identification — Setup & Usage Guide

This folder contains a **minimal, reproducible TensorFlow/Keras pipeline** for
identifying fashion brand from an image, integrated as a Python micro-service
callable from the Flutter application.

---

## 📁 Folder structure

```
brand_identification/
├── README.md                    ← this file
├── DATASET_EVALUATION.md        ← analysis of the Kaggle dataset
├── FLUTTER_INTEGRATION.md       ← how to call the API from Flutter
├── requirements.txt             ← Python dependencies
├── train_brand_classifier.py    ← training script (EfficientNetB0 / MobileNetV2)
├── inference_api.py             ← FastAPI inference server
└── data/                        ← ⚠️  NOT committed — see §2 below
    └── fashion_brands/
        ├── Nike/
        ├── Adidas/
        └── ...
```

---

## 1. Prerequisites

- Python **3.9+**
- `pip` (or a virtual environment manager such as `venv` / `conda`)
- A GPU is recommended for training but not mandatory (CPU is fine for inference)

```bash
# Create and activate a virtual environment (optional but recommended)
python -m venv .venv
source .venv/bin/activate     # Linux/macOS
.venv\Scripts\activate        # Windows

# Install dependencies
pip install -r requirements.txt
```

---

## 2. Download the dataset (manual step — no files are committed)

1. Go to https://www.kaggle.com/datasets/rajatraj0502/global-fashion-brands
2. Sign in to Kaggle (free account required).
3. Click **Download** to get the dataset zip.
4. Extract the archive so that each brand folder sits directly inside
   `brand_identification/data/fashion_brands/`:

```
brand_identification/
└── data/
    └── fashion_brands/
        ├── Nike/
        │   ├── image_001.jpg
        │   └── image_002.jpg
        ├── Adidas/
        │   └── ...
        └── Gucci/
            └── ...
```

> **Note:** the `data/` directory is listed in `.gitignore` — dataset images
> are never committed to the repository.

Alternatively, use the **Kaggle CLI**:
```bash
pip install kaggle
# Place your kaggle.json API key in ~/.kaggle/kaggle.json
kaggle datasets download -d rajatraj0502/global-fashion-brands -p data/
unzip data/global-fashion-brands.zip -d data/fashion_brands/
```

---

## 3. Train the model

```bash
cd brand_identification

# Default: EfficientNetB0, 20 epochs, export to saved_model/brand_classifier/
python train_brand_classifier.py \
    --data_dir  data/fashion_brands \
    --epochs    20 \
    --backbone  efficientnetb0 \
    --export_dir saved_model/brand_classifier
```

| Argument | Default | Description |
|---|---|---|
| `--data_dir` | `data/fashion_brands` | Root directory with one sub-folder per brand |
| `--epochs` | `20` | Total training epochs (phase 1 head + phase 2 fine-tune) |
| `--backbone` | `efficientnetb0` | `efficientnetb0` or `mobilenetv2` |
| `--export_dir` | `saved_model/brand_classifier` | Where to write the SavedModel |

After training you will see:
```
saved_model/brand_classifier/
├── saved_model.pb
├── labels.json          ← list of class names in index order
└── variables/
```

Typical validation accuracy: **85–95 %** depending on dataset size and GPU time.

---

## 4. Start the inference API

```bash
cd brand_identification
uvicorn inference_api:app --host 0.0.0.0 --port 8000
```

Optional environment variables:

| Variable | Default | Description |
|---|---|---|
| `MODEL_DIR` | `saved_model/brand_classifier` | Path to SavedModel |
| `LABELS_FILE` | `<MODEL_DIR>/labels.json` | Path to labels JSON |
| `TOP_K` | `5` | Default number of top predictions |

---

## 5. Test the API

### Health check
```bash
curl http://localhost:8000/health
# {"status":"ok","num_classes":67}
```

### Predict brand from image
```bash
curl -X POST http://localhost:8000/predict \
     -F "file=@/path/to/shoe.jpg"
```

Expected JSON response:
```json
{
  "brand": "Nike",
  "confidence": 0.923,
  "top_k": [
    { "brand": "Nike",   "confidence": 0.923 },
    { "brand": "Adidas", "confidence": 0.051 },
    { "brand": "Puma",   "confidence": 0.012 },
    { "brand": "Reebok", "confidence": 0.008 },
    { "brand": "New Balance", "confidence": 0.003 }
  ]
}
```

### Interactive docs
Visit http://localhost:8000/docs for the auto-generated Swagger UI.

---

## 6. Connect Flutter to the API

See **[FLUTTER_INTEGRATION.md](FLUTTER_INTEGRATION.md)** for the full guide
including the Dart service class, example UI widget, and deployment options.

---

## 7. Dataset evaluation

See **[DATASET_EVALUATION.md](DATASET_EVALUATION.md)** for a detailed analysis
of the Kaggle "Global Fashion Brands" dataset: strengths, limitations, label
quality, generalization risks, and licensing notes.

---

## 8. Notes on accuracy and limitations

- The model works best on **clear product/logo images** similar to those in the
  training set.  Performance on blurry or heavily occluded images will be lower.
- Always display the **confidence score** to the user so they can judge the
  reliability of the prediction.
- For production use, consider collecting domain-specific photos and
  fine-tuning the model further.

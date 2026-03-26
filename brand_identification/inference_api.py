"""
inference_api.py
================
FastAPI micro-service that loads a TensorFlow SavedModel brand classifier
and returns JSON predictions from an uploaded image.

Endpoints
---------
GET  /health              — liveness check
POST /predict             — upload an image, get brand prediction
POST /predict/top_k       — same, returns top-K brands (default k=5)

Example curl
------------
    curl -X POST http://localhost:8000/predict \
         -F "file=@/path/to/shoe.jpg"

    # Response:
    {
      "brand": "Nike",
      "confidence": 0.923,
      "top_k": [
        {"brand": "Nike",   "confidence": 0.923},
        {"brand": "Adidas", "confidence": 0.051},
        ...
      ]
    }

Usage
-----
    pip install -r requirements.txt
    uvicorn inference_api:app --host 0.0.0.0 --port 8000 --reload

Environment variables
---------------------
    MODEL_DIR   Path to the exported SavedModel directory
                (default: saved_model/brand_classifier)
    LABELS_FILE Path to labels.json produced by the training script
                (default: <MODEL_DIR>/labels.json)
    TOP_K       Number of top predictions to return (default: 5)
"""

import json
import os
from io import BytesIO
from typing import List

import numpy as np
import tensorflow as tf
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
from pydantic import BaseModel

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
MODEL_DIR = os.environ.get("MODEL_DIR", "saved_model/brand_classifier")
LABELS_FILE = os.environ.get("LABELS_FILE", os.path.join(MODEL_DIR, "labels.json"))
TOP_K = int(os.environ.get("TOP_K", 5))
IMG_SIZE = 224
MAX_FILE_BYTES = 10 * 1024 * 1024  # 10 MB

# ---------------------------------------------------------------------------
# Load model and labels at startup
# ---------------------------------------------------------------------------
print(f"[INFO] Loading model from: {MODEL_DIR}")
try:
    model = tf.saved_model.load(MODEL_DIR)
    infer = model.signatures["serving_default"]
except Exception as exc:
    raise RuntimeError(
        f"Could not load SavedModel from '{MODEL_DIR}'. "
        "Run train_brand_classifier.py first."
    ) from exc

with open(LABELS_FILE, "r", encoding="utf-8") as f:
    CLASS_NAMES: List[str] = json.load(f)

print(f"[INFO] Model loaded — {len(CLASS_NAMES)} classes")

# ---------------------------------------------------------------------------
# FastAPI app
# ---------------------------------------------------------------------------
app = FastAPI(
    title="Brand Identification API",
    description="Predict fashion brand from an uploaded image using EfficientNetB0/MobileNetV2.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Pydantic response schemas
# ---------------------------------------------------------------------------
class BrandScore(BaseModel):
    brand: str
    confidence: float


class PredictionResponse(BaseModel):
    brand: str
    confidence: float
    top_k: List[BrandScore]


# ---------------------------------------------------------------------------
# Image preprocessing
# ---------------------------------------------------------------------------

def preprocess_image(image_bytes: bytes) -> tf.Tensor:
    """Decode, resize, and normalise an image for model inference."""
    try:
        image = Image.open(BytesIO(image_bytes)).convert("RGB")
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Invalid image file: {exc}") from exc

    image = image.resize((IMG_SIZE, IMG_SIZE), Image.BILINEAR)
    arr = np.array(image, dtype=np.float32)
    arr = np.expand_dims(arr, axis=0)  # (1, H, W, 3)
    return tf.constant(arr)


def run_inference(tensor: tf.Tensor, top_k: int) -> PredictionResponse:
    """Run the SavedModel signature and build the response."""
    output = infer(tensor)
    # The output key may vary; grab the first (and only) output tensor
    raw = list(output.values())[0].numpy()[0]  # shape (num_classes,)
    # Apply softmax to handle both softmax and raw-logit SavedModels safely
    exp = np.exp(raw - raw.max())
    probs = exp / exp.sum()

    top_indices = np.argsort(probs)[::-1][:top_k]
    top_brands = [
        BrandScore(brand=CLASS_NAMES[i], confidence=float(probs[i]))
        for i in top_indices
    ]

    return PredictionResponse(
        brand=top_brands[0].brand,
        confidence=top_brands[0].confidence,
        top_k=top_brands,
    )


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.get("/health", tags=["Monitoring"])
def health():
    return {"status": "ok", "num_classes": len(CLASS_NAMES)}


@app.post("/predict", response_model=PredictionResponse, tags=["Inference"])
async def predict(file: UploadFile = File(...)):
    """Upload an image and receive the top brand prediction + top-5 list."""
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=415, detail="File must be an image (jpeg/png/…).")

    contents = await file.read()
    if len(contents) > MAX_FILE_BYTES:
        raise HTTPException(status_code=413, detail="Image too large (max 10 MB).")

    tensor = preprocess_image(contents)
    return run_inference(tensor, top_k=TOP_K)


@app.post("/predict/top_k", response_model=PredictionResponse, tags=["Inference"])
async def predict_top_k(file: UploadFile = File(...), k: int = TOP_K):
    """Upload an image and receive the top-K brand predictions."""
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=415, detail="File must be an image (jpeg/png/…).")
    if k < 1 or k > len(CLASS_NAMES):
        raise HTTPException(status_code=400, detail=f"k must be between 1 and {len(CLASS_NAMES)}.")

    contents = await file.read()
    if len(contents) > MAX_FILE_BYTES:
        raise HTTPException(status_code=413, detail="Image too large (max 10 MB).")

    tensor = preprocess_image(contents)
    return run_inference(tensor, top_k=k)

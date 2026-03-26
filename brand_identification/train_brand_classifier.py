"""
train_brand_classifier.py
=========================
Train a lightweight brand classifier using EfficientNetB0 (or MobileNetV2)
on the Global Fashion Brands dataset.

Usage
-----
    python train_brand_classifier.py \
        --data_dir data/fashion_brands \
        --epochs 20 \
        --backbone efficientnetb0 \
        --export_dir saved_model/brand_classifier

Expected data layout (before running):
    data/fashion_brands/
        Nike/img1.jpg ...
        Adidas/img1.jpg ...
        Gucci/img1.jpg ...
        ...

The script performs an automatic 80/20 train/val split.
After training, the model is exported as a TensorFlow SavedModel and a
class-name mapping is saved to saved_model/brand_classifier/labels.txt.
"""

import argparse
import json
import os
import pathlib

import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

# ---------------------------------------------------------------------------
# Reproducibility
# ---------------------------------------------------------------------------
SEED = 42
tf.random.set_seed(SEED)
np.random.seed(SEED)

# ---------------------------------------------------------------------------
# Hyper-parameters (overridable via CLI)
# ---------------------------------------------------------------------------
IMG_SIZE = 224
BATCH_SIZE = 32
FINE_TUNE_AT = 100  # unfreeze layers after this index during fine-tuning


# ---------------------------------------------------------------------------
# Data loading helpers
# ---------------------------------------------------------------------------

def build_datasets(data_dir: str, img_size: int, batch_size: int):
    """Create train / validation tf.data.Dataset with augmentation."""
    data_dir = pathlib.Path(data_dir)

    train_ds = keras.utils.image_dataset_from_directory(
        data_dir,
        validation_split=0.2,
        subset="training",
        seed=SEED,
        image_size=(img_size, img_size),
        batch_size=batch_size,
        label_mode="categorical",
    )

    val_ds = keras.utils.image_dataset_from_directory(
        data_dir,
        validation_split=0.2,
        subset="validation",
        seed=SEED,
        image_size=(img_size, img_size),
        batch_size=batch_size,
        label_mode="categorical",
    )

    class_names = train_ds.class_names
    num_classes = len(class_names)
    display_names = class_names[:10] + (["..."] if num_classes > 10 else [])
    print(f"[INFO] Found {num_classes} classes: {display_names}")

    # Data augmentation pipeline (applied only on train)
    augmentation = keras.Sequential(
        [
            layers.RandomFlip("horizontal"),
            layers.RandomRotation(0.15),
            layers.RandomZoom(0.15),
            layers.RandomContrast(0.2),
            layers.RandomBrightness(0.2),
        ],
        name="augmentation",
    )

    AUTOTUNE = tf.data.AUTOTUNE

    train_ds = (
        train_ds
        .map(lambda x, y: (augmentation(x, training=True), y), num_parallel_calls=AUTOTUNE)
        .cache()
        .shuffle(1000)
        .prefetch(AUTOTUNE)
    )
    val_ds = val_ds.cache().prefetch(AUTOTUNE)

    return train_ds, val_ds, class_names


# ---------------------------------------------------------------------------
# Model builders
# ---------------------------------------------------------------------------

def build_model(backbone_name: str, num_classes: int, img_size: int) -> keras.Model:
    """Build a transfer-learning model with a frozen backbone."""
    inputs = keras.Input(shape=(img_size, img_size, 3), name="input_image")

    # Preprocessing specific to each backbone
    if backbone_name == "efficientnetb0":
        preprocess = tf.keras.applications.efficientnet.preprocess_input
        base = tf.keras.applications.EfficientNetB0(
            include_top=False, weights="imagenet", input_shape=(img_size, img_size, 3)
        )
    elif backbone_name == "mobilenetv2":
        preprocess = tf.keras.applications.mobilenet_v2.preprocess_input
        base = tf.keras.applications.MobileNetV2(
            include_top=False, weights="imagenet", input_shape=(img_size, img_size, 3)
        )
    else:
        raise ValueError(f"Unknown backbone: {backbone_name}. Choose 'efficientnetb0' or 'mobilenetv2'.")

    base.trainable = False  # freeze backbone initially

    x = preprocess(inputs)
    x = base(x, training=False)
    x = layers.GlobalAveragePooling2D(name="gap")(x)
    x = layers.Dropout(0.3, name="dropout")(x)
    outputs = layers.Dense(num_classes, activation="softmax", name="predictions")(x)

    model = keras.Model(inputs, outputs, name=f"brand_classifier_{backbone_name}")
    return model, base


# ---------------------------------------------------------------------------
# Training routine
# ---------------------------------------------------------------------------

def train(args):
    # 1. Load data
    train_ds, val_ds, class_names = build_datasets(args.data_dir, IMG_SIZE, BATCH_SIZE)
    num_classes = len(class_names)

    # 2. Build model
    model, base = build_model(args.backbone, num_classes, IMG_SIZE)
    model.summary()

    # 3. Phase 1 — train head only
    model.compile(
        optimizer=keras.optimizers.Adam(1e-3),
        loss="categorical_crossentropy",
        metrics=["accuracy", keras.metrics.TopKCategoricalAccuracy(k=5, name="top5_acc")],
    )

    callbacks = [
        keras.callbacks.EarlyStopping(patience=5, restore_best_weights=True, monitor="val_accuracy"),
        keras.callbacks.ReduceLROnPlateau(patience=3, factor=0.5, monitor="val_loss"),
        keras.callbacks.ModelCheckpoint(
            filepath=os.path.join(args.export_dir, "ckpt_phase1.keras"),
            save_best_only=True,
            monitor="val_accuracy",
        ),
    ]

    print("\n[PHASE 1] Training classification head (backbone frozen) …")
    history_phase1 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=min(args.epochs, 10),
        callbacks=callbacks,
    )

    # 4. Phase 2 — fine-tune deeper layers
    print(f"\n[PHASE 2] Fine-tuning backbone from layer {FINE_TUNE_AT} …")
    base.trainable = True
    for layer in base.layers[:FINE_TUNE_AT]:
        layer.trainable = False

    model.compile(
        optimizer=keras.optimizers.Adam(1e-5),
        loss="categorical_crossentropy",
        metrics=["accuracy", keras.metrics.TopKCategoricalAccuracy(k=5, name="top5_acc")],
    )

    callbacks[2] = keras.callbacks.ModelCheckpoint(
        filepath=os.path.join(args.export_dir, "ckpt_phase2.keras"),
        save_best_only=True,
        monitor="val_accuracy",
    )

    history_phase2 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=args.epochs,
        initial_epoch=len(history_phase1.history["loss"]),
        callbacks=callbacks,
    )

    # 5. Export SavedModel
    os.makedirs(args.export_dir, exist_ok=True)
    model.export(args.export_dir)
    print(f"[INFO] SavedModel exported to: {args.export_dir}")

    # 6. Save class-name mapping
    labels_path = os.path.join(args.export_dir, "labels.json")
    with open(labels_path, "w", encoding="utf-8") as f:
        json.dump(class_names, f, ensure_ascii=False, indent=2)
    print(f"[INFO] Class names saved to: {labels_path}")

    # 7. Print final metrics
    val_results = model.evaluate(val_ds, verbose=0)
    metric_names = model.metrics_names
    print("\n[RESULTS] Validation metrics:")
    for name, val in zip(metric_names, val_results):
        print(f"  {name}: {val:.4f}")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train brand classifier")
    parser.add_argument(
        "--data_dir",
        type=str,
        default="data/fashion_brands",
        help="Root directory with one sub-folder per brand",
    )
    parser.add_argument(
        "--epochs",
        type=int,
        default=20,
        help="Total number of training epochs (phase 1 + phase 2)",
    )
    parser.add_argument(
        "--backbone",
        type=str,
        default="efficientnetb0",
        choices=["efficientnetb0", "mobilenetv2"],
        help="CNN backbone to use",
    )
    parser.add_argument(
        "--export_dir",
        type=str,
        default="saved_model/brand_classifier",
        help="Directory where the SavedModel will be written",
    )
    args = parser.parse_args()
    os.makedirs(args.export_dir, exist_ok=True)
    train(args)

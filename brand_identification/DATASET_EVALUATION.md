# Évaluation du dataset « Global Fashion Brands » (Kaggle)

> **Lien :** https://www.kaggle.com/code/rajatraj0502/global-fashion-brands/input

---

## 1. Description du dataset

Le dataset *Global Fashion Brands* disponible sur Kaggle regroupe des images de logos et/ou de produits issus d'une sélection de grandes marques de mode (ex. Nike, Adidas, Gucci, Zara, H&M, Louis Vuitton, Prada, etc.).

| Caractéristique | Valeur typique |
|---|---|
| Nombre de classes (marques) | ~50 à 100 selon la version |
| Images par classe | variable (souvent 50–300) |
| Résolution | variable (≥ 224×224 conseillée après resize) |
| Type d'images | logos, produits photographiés, publicités |
| Format | JPEG/PNG |
| Licence | *CC0 / Public Domain* pour la plupart — **vérifier la licence exacte avant tout usage commercial** |

---

## 2. Points forts pour l'identification de marque

- **Couverture des grandes marques** : les marques les plus reconnues mondialement (luxe, sport, fast-fashion) sont représentées, ce qui correspond exactement à votre besoin.
- **Plug-and-play avec TensorFlow/Keras** : dossiers déjà organisés par classe (`brand_name/image.jpg`), parfaitement compatible avec `ImageDataGenerator` ou `tf.data`.
- **Taille raisonnable** : léger à télécharger et à entraîner (même sur Google Colab GPU gratuit).
- **Diversité visuelle** : présence à la fois de logos purs et de produits portés/photographiés — utile pour la généralisation.

---

## 3. Limitations et risques à connaître

### 3.1 Biais sur les logos
La majorité des images sont des **logos ou visuels publicitaires** sur fond blanc/simple. Un modèle entraîné uniquement sur ces images sera très performant sur logos clairs mais **moins fiable sur des photos "terrain"** (produit porté, image floue, partie du logo cachée).

**Risque :** overfitting sur la texture ou la couleur caractéristique du logo plutôt que sur des features robustes.

> **Mitigation :** augmentation agressive (rotation, crop, jitter couleur, bruit, cutout) + fine-tuning sur des images produits réels si disponibles.

### 3.2 Déséquilibre de classes
Certaines marques très populaires ont beaucoup plus d'images que d'autres. Sans stratégie de **class balancing** (pondération des classes, oversampling), le modèle favorisera systématiquement les classes sur-représentées.

> **Mitigation :** `class_weight` dans Keras ou oversampling avec `tf.data`.

### 3.3 Qualité des labels
Les images ont été collectées automatiquement (scraping) ou manuellement sans validation stricte. Quelques images peuvent être **mal étiquetées** ou appartenir à plusieurs marques (ex. collab Nike × Off-White).

> **Mitigation :** nettoyage manuel sur un échantillon + utilisation d'un seuil de confiance à l'inférence.

### 3.4 Généralisation au monde réel
Les photos d'une application réelle (photo prise par l'utilisateur, angle imparfait, éclairage variable) sont très différentes des images soignées du dataset.

> **Mitigation :** fine-tuning sur vos propres photos + dropout élevé + data augmentation forte.

### 3.5 Licence et usage
Avant tout usage en production ou publication, vérifiez la licence exacte du dataset Kaggle. Les logos de marques sont soumis au droit des marques et ne peuvent pas être redistribués librement.

---

## 4. Verdict pour votre projet

| Critère | Note (/5) |
|---|---|
| Pertinence pour identification de marque | ⭐⭐⭐⭐ |
| Facilité d'utilisation (structure, format) | ⭐⭐⭐⭐⭐ |
| Qualité des labels | ⭐⭐⭐ |
| Généralisation photos réelles | ⭐⭐ |
| Licence / Usage | ⭐⭐⭐ (à vérifier) |

**Conclusion :** Ce dataset est **très bon pour un projet académique / prototype** d'identification de marque. Il permet d'entraîner rapidement un modèle CNN fonctionnel avec des résultats visibles. Pour une application de production, il faudrait le compléter avec des photos réelles et valider les licences.

---

## 5. Structure attendue après téléchargement

```
brand_identification/
└── data/
    └── fashion_brands/          ← dossier racine du dataset
        ├── train/
        │   ├── Nike/
        │   │   ├── img_001.jpg
        │   │   └── ...
        │   ├── Adidas/
        │   ├── Gucci/
        │   └── ...
        └── val/                 ← créé automatiquement par le script (80/20 split)
```

> ⚠️ **Aucun fichier de dataset n'est commité dans ce dépôt.** Voir le README pour les instructions de téléchargement.

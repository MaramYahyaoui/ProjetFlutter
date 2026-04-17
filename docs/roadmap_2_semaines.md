# Roadmap 2 semaines — MVP validable (EduLycée)

Objectif : maximiser les points "validables" en 14 jours en évitant les gros risques (messagerie complète, FCM, bulletins complets).

## Principe

- On capitalise sur ce qui existe déjà (élève/prof/admin + notes/devoirs/emploi du temps).
- On comble les trous les plus visibles (Parent + absence hardcodée).
- On ne lance **pas** un chantier messagerie complet en fin de projet.

## Périmètre MVP (cible validation)

### Must-have (priorité 1)

1) **Espace Parent utilisable**
- Parent voit **ses enfants**
- Parent peut consulter pour un enfant : **notes + moyennes**, **emploi du temps**, **devoirs**, **profil** (lecture)

2) **Vie scolaire – Absences/retards (version simple)**
- Rôle "vie scolaire" (ou admin) : créer une absence/retard pour un élève
- Élève + parent : consulter la liste
- (Option simple) parent peut marquer "justification envoyée" (ou ajouter un texte)

3) **Cohérence des rôles & sécurité**
- Règles Firestore alignées avec les nouvelles collections
- Vérifier qu’un parent ne lit que les données de ses enfants

### Nice-to-have (priorité 2)

- Petits "Rapports" admin (ex: compteurs simples) au lieu de bulletins complets
- Notifications in-app déjà existantes : l’utiliser pour alerter parent/élève lors d’une absence ou d’une note

### À éviter en 2 semaines (trop risqué)

- Messagerie chat temps réel + threads + pièces jointes
- Push FCM (firebase_messaging) + Cloud Functions
- Bulletins complets + périodes/trimestres + génération avancée
- Compétences (LOMFR)

## Planning conseillé (J1 → J14)

### J1–J2 : Modèle de données Parent (socle)

- Ajouter dans `utilisateurs` une relation parent ↔ enfants (au choix) :
  - Option A (simple) : `enfantsIds: List<String>` sur le parent
  - Option B (plus clean) : sur l’élève `parentsIds: List<String>`
- Créer un écran Parent : sélection d’enfant + navigation vers les pages existantes (notes/emploi/devoirs).
- Adapter les queries Firestore pour filtrer par `eleveId` (enfant sélectionné) côté parent.

Livrable : parent peut ouvrir l’app et voir au moins 1 enfant, puis consulter notes/emploi/devoirs.

### J3–J5 : Espace Parent (vues réutilisées)

- Réutiliser les écrans élève en mode "read-only" pour un `studentId` passé en param.
- Ajouter une page Parent "Dashboard" (simple) :
  - moyenne + prochains cours + devoirs en retard

Livrable : parcours parent complet et démontrable.

### J6–J9 : Vie scolaire (absences/retards v1)

- Collections proposées :
  - `absences/{id}`: `eleveId`, `date`, `type` (absence/retard), `duree` (option), `motif` (option), `createdBy`, `createdAt`, `justifiee` (bool), `justificationTexte` (option)
- Écrans :
  - Vie scolaire/admin : créer + lister (filtre par classe/élève si possible)
  - Parent/élève : lister
- Mettre à jour `firestore.rules` :
  - admin/vie scolaire : read/write
  - élève : read si `eleveId == uid`
  - parent : read si `eleveId` ∈ ses enfants

Livrable : remplacer la stat "Absences" hardcodée par une vraie donnée.

### J10–J11 : Qualité + démo

- Nettoyage UX : textes, états vides, erreurs
- Vérifier les parcours clés : login par rôle, navigation, lecture des données.

### J12–J14 : Buffer + bonus

- Bonus possible :
  - Admin "Rapports" minimal (compteurs notes manquantes, devoirs, absences)
  - Notifications in-app lors création d’absence (doc dans `notifications`)

## Critères de validation (checklist)

- Parent : voit enfant(s) + notes/EDT/devoirs
- Vie scolaire : création absence/retard + visibilité parent/élève
- Règles Firestore : pas de fuite de données entre comptes

---

Si tu veux, je peux enchaîner en implémentant directement le **lot 1 (Parent)** : modèle Firestore + écran parent + adaptation des écrans notes/emploi/devoirs pour accepter un `studentId`.

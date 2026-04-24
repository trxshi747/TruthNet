# TruthNet – Social Media Intelligent Platform

## Présation du projet

TruthNet est une plateforme de réseau social intelligente permettant :

* la publication de posts (texte, images, vidéos)
* l’interaction entre utilisateurs (likes, commentaires, partages)
* la modération de contenu
* l’analyse des sentiments (objectif futur)

Le projet repose sur :

* **Frontend** : Flutter (Android Studio)
* **Backend** : Node.js (Express)
* **Base de données** : Neo4j (graph database)

---

## Architecture du projet

```
/project-root
│
├── backend/          → API Node.js (Express + Neo4j)
│    |- uploads/      → Fichiers uploadés (images, vidéos)
├── lib/              → Application Flutter

```

---

##  Installation & Lancement

###  Backend (Node.js)

####  Installer les dépendances

```bash
cd backend
npm install
```

#### Configurer Neo4j

Créer un fichier `.env` :

```env
NEO4J_USER=neo4j
NEO4J_PASSWORD=your_password
```

#### Lancer le serveur

```bash
node index.js
```

 Le serveur tourne sur :

```
http://localhost:3000
```

---

###  Base de données Neo4j

####  Démarrer Neo4j

* Neo4j Desktop ou Neo4j Server
* URL :

```
bolt://localhost:7687
```

####  Tester la connexion

Dans Neo4j Browser :

```cypher
RETURN "CONNECTED" as status;
```

---

###  Frontend (Flutter)

####  Installer les dépendances

```bash
flutter pub get
```

####  Config importante (Android Emulator)

Dans `api_service.dart` :

```dart
static const String baseUrl = "http://10.0.2.2:3000/api";
```

####  Lancer l’application

```bash
flutter run
```

---

##  Fonctionnalités implémentées

###  Authentification

* Inscription utilisateur
* Connexion
* Hash des mots de passe (bcrypt)

---

###  Gestion utilisateurs

* Profil utilisateur
* Followers / Following
* Modification profil

---

###  Posts

* Création de posts
* Modification (avec limite de temps)
* Suppression (soft delete + permanent)
* Feed global

---

###  Commentaires

* Ajouter commentaire
* Répondre à un commentaire
* Like commentaire

---

###  Interactions

* Like / Unlike
* Share
* Save

---

###  Admin – Modérateurs

* Ajouter modérateur
* Modifier modérateur
* Supprimer modérateur
* Liste dynamique (API)

---

###  Admin – Rôles

* Ajouter rôle
* Modifier rôle
* Supprimer rôle
* Liste dynamique

---

##  API principales

###  Auth

```
POST   /api/auth/register
POST   /api/auth/login
```

###  Users

```
GET    /api/users/:id/profile
PUT    /api/users/:id/profile
```

###  Posts

```
POST   /api/posts
GET    /api/feed
PUT    /api/posts/:id
DELETE /api/posts/:id/permanent
```

###  Comments

```
POST   /api/posts/comment
GET    /api/posts/:id/comments
```

###  Admin

```
GET    /api/admin/moderators
POST   /api/admin/moderators
PUT    /api/admin/moderators/:id
DELETE /api/admin/moderators/:id

GET    /api/admin/roles
POST   /api/admin/roles
DELETE /api/admin/roles/:id
```

---

##  Problèmes rencontrés & solutions

###  Erreur type:

```
type 'null' is not a subtype of type 'String'
```

  Solution :

```dart
mod['field'] ?? "N/A"
```

---

###  API retourne vide

  Solution :

* vérifier routes backend
* tester avec Postman

---

###  Backend non lancé

  Solution :
Toujours lancer :

```bash
node index.js
```

---

##  Bonnes pratiques utilisées

* Séparation Front / Back
* Architecture REST API
* Hash sécurisé des mots de passe
* Gestion des erreurs (try/catch)
* UI dynamique avec fallback mock

---

## Améliorations futures

###  Dashboard Admin (à faire)

* Nombre d’utilisateurs
* Nombre de posts
* Activité journalière
* Graphiques (charts)

---

###  IA / NLP (objectif clé)

* Analyse de sentiment
* Détection contenu toxique
* Suppression automatique

---

###  Sécurité

* JWT Authentication
* Role-based access control (RBAC)

---

###  Performances

* Pagination feed
* Optimisation requêtes Neo4j

---

##  Tests recommandés

* Postman (API)
* Flutter UI tests
* Test création utilisateur
* Test CRUD modérateur

---

##  Auteur

Projet réalisé dans le cadre d’un projet académique, réseau social intelligent.

---

##   Checklist avant exécution

- Neo4j lancé
- Backend lancé
- Flutter lancé
- API testée

---

##  Conclusion

Le projet est actuellement fonctionnel avec :

* Backend connecté à Neo4j
* Frontend Flutter dynamique
* CRUD Admin opérationnel

Prochaine étape : **Dashboard Analytics + IA**

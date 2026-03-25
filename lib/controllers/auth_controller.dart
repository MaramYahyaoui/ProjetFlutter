import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fauth;
import '../core/config/app_constants.dart';
import '../core/services/firebase_service.dart';
import '../models/user_model.dart';

/// Controller authenfication centralisé
/// Gère la connexion, déconnexion et l'état utilisateur
class AuthController extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final fauth.FirebaseAuth _auth;

  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  AuthController({
    FirebaseService? firebaseService,
    fauth.FirebaseAuth? auth,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        _auth = auth ?? fauth.FirebaseAuth.instance {
    // Vérifie l'état d'authentification au démarrage
    _initAuthState();
  }

  // ============ GETTERS ============

  /// Utilisateur actuellement authentifié
  User? get user => _user;

  /// Check si un utilisateur est connecté
  bool get isAuthenticated => _isAuthenticated;

  /// Check si une opération est en cours
  bool get isLoading => _isLoading;

  /// Message d'erreur (s'il existe)
  String? get error => _error;

  /// Le rôle de l'utilisateur conecté
  String? get userRole => _user?.role;

  /// Check si l'utilisateur est étudiant
  bool get isStudent => userRole == UserRoles.student;

  /// Check si l'utilisateur est enseignant
  bool get isTeacher => userRole == UserRoles.teacher;

  /// Check si l'utilisateur est parent
  bool get isParent => userRole == UserRoles.parent;

  /// Check si l'utilisateur est admin
  bool get isAdmin => userRole == UserRoles.admin;

  // ============ INITIALIZATION ============

  /// Initialise l'état d'authentification au démarrage
  /// Cette méthode est appelée dans le constructeur
  void _initAuthState() {
    final firebaseUser = _auth.currentUser;
    
    // Au startup, on n'essaie pas de charger le profil
    // On juste vérifie si quelqu'un est connecté à Firebase
    // Le profil sera chargé lors du login
    if (firebaseUser != null) {
      // Y a une session Firebase active, mais on fait pas de loading détaillé des données
      // Au lieu de ça, on appelle checkAuthState() au démarrage pour recharger le profil complètement
      _setLoading(true);
      checkAuthState();
    } else {
      // Pas de session Firebase → login page
      _clearAuthState();
    }
  }

  /// Vérifie manuellement l'état de l'authentification
  Future<void> checkAuthState() async {
    _setLoading(true);
    
    try {
      final firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        await _loadUserProfile(firebaseUser.uid);
      } else {
        _clearAuthState();
      }
    } finally {
      _setLoading(false);
    }
  }

  // ============ AUTHENTICATION ============

  /// Connecte l'utilisateur avec email et password
  /// Retourne true si succès, false sinon
  Future<bool> login(String email, String password, {String? expectedRole}) async {
    _setLoading(true);
    _clearError();

    try {
      // 1. Authentifier avec Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user == null) {
        _setError('Utilisateur non trouvé');
        return false;
      }

      // 2. Charger le profil utilisateur
      final user = await _firebaseService.getUserProfile(credential.user!.uid);

      if (user == null) {
        _setError('Profil utilisateur non trouvé');
        await _auth.signOut();
        return false;
      }

      // 3. Vérifier le rôle si spécifié
      if (expectedRole != null && user.role != expectedRole) {
        _setError('Ce compte n\'a pas le rôle sélectionné');
        await _auth.signOut();
        return false;
      }

      // 4. Vérifier que l'utilisateur est actif
      if (!user.isActive) {
        _setError('Ce compte a été désactivé');
        await _auth.signOut();
        return false;
      }

      _setUser(user);
      return true;
    } on fauth.FirebaseAuthException catch (e) {
      _handleFirebaseAuthError(e);
      return false;
    } catch (e) {
      _setError('Erreur de connexion: ${e.toString()}');
      if (kDebugMode) debugPrint('Login error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Déconnecte l'utilisateur
  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _auth.signOut();
      _clearAuthState();
    } catch (e) {
      _setError('Erreur lors de la déconnexion: ${e.toString()}');
      if (kDebugMode) debugPrint('Logout error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Envoie un email de réinitialisation de mot de passe
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on fauth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _setError('Aucun compte trouvé avec cet email');
      } else {
        _setError('Erreur: ${e.message}');
      }
      return false;
    } catch (e) {
      _setError('Erreur: ${e.toString()}');
      if (kDebugMode) debugPrint('Reset password error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Envoie un email de vérification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Send email verification error: $e');
    }
  }

  /// Actualise le statut de vérification d'email
  Future<void> reloadEmailVerificationStatus() async {
    try {
      await _auth.currentUser?.reload();

      if (_auth.currentUser?.emailVerified ?? false) {
        if (_user != null) {
          final updatedUser = _user!.copyWith(isEmailVerified: true);
          await _firebaseService.setUserProfile(_user!.id, updatedUser);
          _setUser(updatedUser);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Reload email verification error: $e');
    }
  }

  // ============ PRIVATE HELPERS ============

  /// Charge le profil utilisateur depuis Firestore
  Future<void> _loadUserProfile(String userId) async {
    try {
      final user = await _firebaseService.getUserProfile(userId);
      if (user != null) {
        _setUser(user);
      } else {
        _clearAuthState();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading user profile: $e');
      _clearAuthState();
    }
  }

  /// Définit l'utilisateur connecté
  void _setUser(User user) {
    _user = user;
    _isAuthenticated = true;
    _error = null;
    notifyListeners();
  }

  /// Réinitialise l'état d'authentification
  void _clearAuthState() {
    _user = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }

  /// Définit l'état de chargement
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Définit un message d'erreur
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Réinitialise le message d'erreur
  void _clearError() {
    _error = null;
  }

  /// Gère les erreurs Firebase Auth
  void _handleFirebaseAuthError(fauth.FirebaseAuthException e) {
    String message = 'Erreur de connexion';

    switch (e.code) {
      case 'user-not-found':
        message = 'Aucun compte trouvé avec cet email';
        break;
      case 'wrong-password':
        message = 'Mot de passe incorrect';
        break;
      case 'invalid-email':
        message = 'Format d\'email invalide';
        break;
      case 'user-disabled':
        message = 'Ce compte a été désactivé';
        break;
      case 'too-many-requests':
        message = 'Trop de tentatives. Réessayez plus tard';
        break;
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        message = 'Email ou mot de passe incorrect';
        break;
      case 'weak-password':
        message = 'Le mot de passe est trop faible';
        break;
      case 'email-already-in-use':
        message = 'Cet email est déjà utilisé';
        break;
      case 'operation-not-allowed':
        message = 'Opération non autorisée';
        break;
      case 'network-request-failed':
        message = 'Erreur réseau. Vérifiez votre connexion';
        break;
      default:
        message = 'Erreur: ${e.code}';
        if (kDebugMode) debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
    }

    _setError(message);
  }
}

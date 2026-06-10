import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:isar/isar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/isar_database.dart';
import '../database/schemas/meeting_models.dart';

abstract class AuthRepository {
  Stream<UserModel?> get onAuthStateChanged;
  UserModel? get currentUser;
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, String displayName);
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  final StreamController<UserModel?> _localAuthStreamController = StreamController<UserModel?>.broadcast();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  UserModel? _localUser;

  bool get _useFirebase {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAuthRepository() {
    if (_useFirebase) {
      FirebaseAuth.instance.authStateChanges().listen((firebaseUser) async {
        if (firebaseUser == null) {
          _localAuthStreamController.add(null);
        } else {
          final user = await _syncLocalUser(firebaseUser);
          _localAuthStreamController.add(user);
        }
      });
    } else {
      // Offline mode initial state - check secure storage for persistent session
      Future.delayed(const Duration(milliseconds: 500), () async {
        final sessionActive = await _secureStorage.read(key: 'offline_session_active');
        if (sessionActive == 'true') {
          final userEmail = await _secureStorage.read(key: 'offline_session_user_email');
          final isar = IsarDatabase.instance.isar;
          if (userEmail != null && userEmail.isNotEmpty) {
            _localUser = await isar.userModels.filter().emailEqualTo(userEmail).findFirst();
          }
          _localUser ??= await isar.userModels.filter().emailEqualTo('offline@meetingmind.ai').findFirst() ??
                       await isar.userModels.where().findFirst();
          _localAuthStreamController.add(_localUser);
        } else {
          _localUser = null;
          _localAuthStreamController.add(null);
        }
      });
    }
  }

  @override
  Stream<UserModel?> get onAuthStateChanged {
    if (_useFirebase) {
      return FirebaseAuth.instance.authStateChanges().asyncMap((firebaseUser) async {
        if (firebaseUser == null) return null;
        return await _getLocalUser(firebaseUser.uid);
      });
    } else {
      return _localAuthStreamController.stream;
    }
  }

  @override
  UserModel? get currentUser {
    if (_useFirebase) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return null;
      
      final isar = IsarDatabase.instance.isar;
      return isar.userModels.filter().uidEqualTo(firebaseUser.uid).findFirstSync();
    } else {
      return _localUser;
    }
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    if (_useFirebase) {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw Exception('Sign in failed: User is null');
      }
      return await _syncLocalUser(credential.user!);
    } else {
      // Mock Local authentication
      final isar = IsarDatabase.instance.isar;
      var user = await isar.userModels.filter().emailEqualTo(email).findFirst();
      if (user == null) {
        throw Exception('User not found. Use "Sign Up" to create a local account.');
      }
      await _secureStorage.write(key: 'offline_session_active', value: 'true');
      await _secureStorage.write(key: 'offline_session_user_email', value: user.email ?? '');
      _localUser = user;
      _localAuthStreamController.add(user);
      return user;
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    if (_useFirebase) {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw Exception('Registration failed: User is null');
      }
      
      await credential.user!.updateDisplayName(displayName);
      await credential.user!.reload();
      final updatedUser = FirebaseAuth.instance.currentUser ?? credential.user!;
      return await _syncLocalUser(updatedUser);
    } else {
      // Mock Local sign up
      final isar = IsarDatabase.instance.isar;
      
      var existing = await isar.userModels.filter().emailEqualTo(email).findFirst();
      if (existing != null) {
        throw Exception('User already exists with this email.');
      }

      final user = UserModel()
        ..uid = 'local_${DateTime.now().millisecondsSinceEpoch}'
        ..email = email
        ..displayName = displayName
        ..lastSynced = DateTime.now();

      await isar.writeTxn(() async {
        await isar.userModels.put(user);
      });

      await _secureStorage.write(key: 'offline_session_active', value: 'true');
      await _secureStorage.write(key: 'offline_session_user_email', value: user.email ?? '');
      _localUser = user;
      _localAuthStreamController.add(user);
      return user;
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    if (_useFirebase) {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign In cancelled by user');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw Exception('Google Sign In failed');
      }
      return await _syncLocalUser(userCredential.user!);
    } else {
      // Mock Google Login in local mode
      final isar = IsarDatabase.instance.isar;
      final existing = await isar.userModels.filter().emailEqualTo('google.demo@meetingmind.ai').findFirst();
      if (existing != null) {
        return await signInWithEmailAndPassword(
          'google.demo@meetingmind.ai',
          'password123',
        );
      } else {
        return await signUpWithEmailAndPassword(
          'google.demo@meetingmind.ai',
          'password123',
          'Google Demo User',
        );
      }
    }
  }

  @override
  Future<void> signOut() async {
    if (_useFirebase) {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } else {
      await _secureStorage.delete(key: 'offline_session_active');
      await _secureStorage.delete(key: 'offline_session_user_email');
      _localUser = null;
      _localAuthStreamController.add(null);
    }
  }

  Future<UserModel> _getLocalUser(String uid) async {
    final isar = IsarDatabase.instance.isar;
    final user = await isar.userModels.filter().uidEqualTo(uid).findFirst();
    if (user != null) return user;
    
    return UserModel()
      ..uid = uid
      ..email = FirebaseAuth.instance.currentUser?.email
      ..displayName = FirebaseAuth.instance.currentUser?.displayName;
  }

  Future<UserModel> _syncLocalUser(User firebaseUser) async {
    final isar = IsarDatabase.instance.isar;
    
    var localUser = await isar.userModels.filter().uidEqualTo(firebaseUser.uid).findFirst();
    
    localUser ??= UserModel()..uid = firebaseUser.uid;
    localUser.email = firebaseUser.email;
    localUser.displayName = firebaseUser.displayName ?? firebaseUser.email?.split('@').first;
    localUser.photoUrl = firebaseUser.photoURL;
    localUser.lastSynced = DateTime.now();

    await isar.writeTxn(() async {
      await isar.userModels.put(localUser!);
    });

    return localUser;
  }
}

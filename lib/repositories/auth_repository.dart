import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:isar/isar.dart';
import '../core/config/env_config.dart';
import '../database/isar_database.dart';
import '../database/schemas/meeting_models.dart';
import '../services/firestore_service.dart';

abstract class AuthRepository {
  Stream<UserModel?> get onAuthStateChanged;
  UserModel? get currentUser;
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  );
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  final StreamController<UserModel?> _localAuthStreamController =
      StreamController<UserModel?>.broadcast();

  FirebaseAuthRepository() {
    FirebaseAuth.instance.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        _localAuthStreamController.add(null);
      } else {
        final user = await _syncLocalUser(firebaseUser);
        _localAuthStreamController.add(user);
      }
    });
  }

  @override
  Stream<UserModel?> get onAuthStateChanged {
    return FirebaseAuth.instance.authStateChanges().asyncMap((
      firebaseUser,
    ) async {
      if (firebaseUser == null) return null;
      return await _getLocalUser(firebaseUser.uid);
    });
  }

  @override
  UserModel? get currentUser {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;

    final isar = IsarDatabase.instance.isar;
    return isar.userModels
        .filter()
        .uidEqualTo(firebaseUser.uid)
        .findFirstSync();
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user == null) {
      throw Exception('Sign in failed: User is null');
    }
    return await _syncLocalUser(credential.user!);
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    if (credential.user == null) {
      throw Exception('Registration failed: User is null');
    }

    await credential.user!.updateDisplayName(displayName);
    await credential.user!.reload();
    final updatedUser = FirebaseAuth.instance.currentUser ?? credential.user!;
    return await _syncLocalUser(updatedUser);
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    debugPrint('[AuthRepository] Google Sign-In Started');
    final String? serverClientId = EnvConfig.googleWebClientId.isNotEmpty
        ? EnvConfig.googleWebClientId
        : null;
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: serverClientId,
    );

    try {
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('[AuthRepository] Google Sign-In signOut error: $e');
    }

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign In cancelled by user');
    }
    debugPrint('[AuthRepository] Google Account Selected: ${googleUser.email}');

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    debugPrint('[AuthRepository] Firebase Credential Created');

    final UserCredential userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);
    if (userCredential.user == null) {
      throw Exception('Google Sign In failed to authenticate with Firebase');
    }
    debugPrint('[AuthRepository] Firebase Authentication Success');

    final user = await _syncLocalUser(userCredential.user!);
    return user;
  }

  @override
  Future<void> signOut() async {
    final String? serverClientId = EnvConfig.googleWebClientId.isNotEmpty
        ? EnvConfig.googleWebClientId
        : null;
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: serverClientId,
    );
    try {
      await googleSignIn.signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
    _localAuthStreamController.add(null);
  }

  Future<UserModel> _getLocalUser(String uid) async {
    final isar = IsarDatabase.instance.isar;
    var user = await isar.userModels.filter().uidEqualTo(uid).findFirst();
    if (user != null) return user;

    final profileSnap = await FirestoreService.instance.getUserProfile(uid);
    user = UserModel()..uid = uid;
    if (profileSnap != null && profileSnap.exists) {
      final data = profileSnap.data();
      if (data != null) {
        user.displayName = data['displayName'] as String?;
        user.email = data['email'] as String?;
        user.photoUrl = data['photoUrl'] as String?;
        user.phoneNumber = data['phoneNumber'] as String?;
        user.bio = data['bio'] as String?;
        user.company = data['company'] as String?;
        user.designation = data['designation'] as String?;
      }
    } else {
      user.email = FirebaseAuth.instance.currentUser?.email;
      user.displayName = FirebaseAuth.instance.currentUser?.displayName;
      user.photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    }

    await isar.writeTxn(() async {
      await isar.userModels.put(user!);
    });
    return user;
  }

  Future<UserModel> _syncLocalUser(User firebaseUser) async {
    final isar = IsarDatabase.instance.isar;

    var localUser = await isar.userModels
        .filter()
        .uidEqualTo(firebaseUser.uid)
        .findFirst();
    localUser ??= UserModel()..uid = firebaseUser.uid;

    localUser.email = firebaseUser.email;
    localUser.displayName =
        firebaseUser.displayName ?? firebaseUser.email?.split('@').first;
    localUser.photoUrl = firebaseUser.photoURL;
    localUser.lastSynced = DateTime.now();

    final doc = await FirestoreService.instance.getUserProfile(
      firebaseUser.uid,
    );
    if (doc != null && doc.exists) {
      final data = doc.data();
      if (data != null) {
        localUser.displayName =
            data['displayName'] as String? ?? localUser.displayName;
        localUser.photoUrl = data['photoUrl'] as String? ?? localUser.photoUrl;
        localUser.phoneNumber =
            data['phoneNumber'] as String? ?? localUser.phoneNumber;
        localUser.bio = data['bio'] as String? ?? localUser.bio;
        localUser.company = data['company'] as String? ?? localUser.company;
        localUser.designation =
            data['designation'] as String? ?? localUser.designation;
      }
    } else {
      await FirestoreService.instance.saveUserProfile(firebaseUser.uid, {
        'uid': firebaseUser.uid,
        'displayName': localUser.displayName,
        'email': localUser.email,
        'photoUrl': localUser.photoUrl,
        'phoneNumber': localUser.phoneNumber ?? '',
        'bio': localUser.bio ?? '',
        'company': localUser.company ?? '',
        'designation': localUser.designation ?? '',
      });
    }

    await isar.writeTxn(() async {
      await isar.userModels.put(localUser!);
    });

    return localUser;
  }
}

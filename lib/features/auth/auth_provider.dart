import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../database/schemas/meeting_models.dart';
import '../../providers/app_providers.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  AuthState({required this.status, this.user, this.errorMessage});

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(AuthState(status: AuthStatus.initial)) {
    _init();
  }

  void _init() {
    _ref.read(authRepositoryProvider).onAuthStateChanged.listen((user) {
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  String _mapExceptionToMessage(dynamic e) {
    if (e is PlatformException) {
      final code = e.code;
      final message = e.message ?? '';

      if (code == 'sign_in_failed') {
        if (message.contains('10') ||
            e.toString().contains('ApiException: 10')) {
          return 'Google Sign-In Developer Error (Status 10):\n'
              '1. Ensure GOOGLE_WEB_CLIENT_ID in your .env file matches the Firebase Web Client ID.\n'
              '2. Confirm your SHA-1 (0E:8D:FF:...) is added to the Firebase Console.';
        } else if (message.contains('12501')) {
          return 'Google Sign-In was cancelled by the user.';
        } else if (message.contains('12500')) {
          return 'Google Sign-In configuration error (Status 12500).\n'
              'Verify that Google Sign-in provider is enabled in Firebase Console and SHA-1 is correct.';
        } else if (message.contains('7')) {
          return 'Network Unavailable: Google Sign-In requires an active internet connection.';
        }
        return 'Google Sign-in configuration mismatch: $message ($code)';
      }

      if (code == 'network-request-failed') {
        return 'Network Unavailable: Please check your internet connection.';
      }

      return 'Platform Error ($code): $message';
    }

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'operation-not-allowed':
          return 'OAuth Provider Disabled: Enable Google Sign-In under Firebase Authentication settings.';
        case 'account-exists-with-different-credential':
          return 'Account Mismatch: An account already exists with a different sign-in method.';
        case 'invalid-credential':
          return 'OAuth Client Mismatch: The Google credentials could not be validated.';
        case 'user-disabled':
          return 'Account Disabled: This user account has been disabled.';
        case 'user-not-found':
          return 'Account Not Found: No account is associated with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'The password is too weak. Please use a stronger password.';
        default:
          return 'Firebase Authentication Error (${e.code}): ${e.message}';
      }
    }

    final errStr = e.toString();
    if (errStr.contains('user-not-found')) {
      return 'No account found with this email. Please check your spelling or sign up.';
    } else if (errStr.contains('wrong-password') ||
        errStr.contains('invalid-credential')) {
      return 'Incorrect password or credentials. Please try again.';
    } else if (errStr.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (errStr.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    } else if (errStr.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    } else if (errStr.contains('cancelled') || errStr.contains('Cancelled')) {
      return 'Google Sign-In was cancelled.';
    } else if (errStr.contains('ApiException: 10') ||
        errStr.contains('sign_in_failed')) {
      return 'Google Sign-In configuration error. Verify SHA-1 setup and client IDs.';
    } else if (errStr.contains('weak-password')) {
      return 'The password is too weak. Please use a stronger password.';
    } else if (errStr.startsWith('Exception:')) {
      return errStr.replaceFirst('Exception:', '').trim();
    }
    return 'Authentication failed: $errStr';
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      final user = await _ref
          .read(authRepositoryProvider)
          .signInWithEmailAndPassword(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapExceptionToMessage(e),
      );
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      final user = await _ref
          .read(authRepositoryProvider)
          .signUpWithEmailAndPassword(email, password, displayName);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapExceptionToMessage(e),
      );
    }
  }

  Future<void> loginWithGoogle() async {
    state = AuthState(status: AuthStatus.loading);
    try {
      final user = await _ref.read(authRepositoryProvider).signInWithGoogle();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapExceptionToMessage(e),
      );
    }
  }

  Future<void> logout() async {
    state = AuthState(status: AuthStatus.loading);
    try {
      await _ref.read(authRepositoryProvider).signOut();
      state = AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _mapExceptionToMessage(e),
      );
    }
  }

  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

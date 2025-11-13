import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint('--- ERRO REAL DO FIREBASE ---');
      debugPrint(e.code);
      debugPrint(e.message);
      debugPrint('-----------------------------');

      if (e.code == 'user-not-found') {
        throw Exception('Nenhum usuário encontrado para este e-mail.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Senha incorreta.');
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      debugPrint(e.toString());
      throw Exception('Ocorreu um erro. Tente novamente.');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static Future<User?> loginUser(String email, String password) async {
    try {
      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Login Error: $e');
      return null;
    }
  }
}

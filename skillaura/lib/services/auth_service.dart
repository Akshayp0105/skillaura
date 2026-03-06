import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // ================= EMAIL REGISTER =================
  Future<String?> register(String email, String password, String fullName, String university) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      // Save user data to Firestore
      if (credential.user != null) {
        await _userService.saveUser(
          uid: credential.user!.uid,
          fullName: fullName,
          email: email.trim(),
          university: university,
        );
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (_) {
      return "Something went wrong";
    }
  }

  // ================= EMAIL LOGIN =================
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (_) {
      return "Something went wrong";
    }
  }

  // ================= GOOGLE LOGIN =================
  Future<String?> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      final credential = await _auth.signInWithPopup(provider);
      
      // Save user data to Firestore if new user
      if (credential.user != null) {
        final existingUser = await _userService.getUser(credential.user!.uid);
        if (existingUser == null) {
          final displayName = credential.user!.displayName ?? 'Google User';
          final email = credential.user!.email ?? '';
          
          await _userService.saveUser(
            uid: credential.user!.uid,
            fullName: displayName,
            email: email,
            university: '',
          );
        }
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= GITHUB LOGIN =================
  Future<String?> signInWithGithub() async {
    try {
      final provider = GithubAuthProvider();
      final credential = await _auth.signInWithPopup(provider);
      
      // Save user data to Firestore if new user
      if (credential.user != null) {
        final existingUser = await _userService.getUser(credential.user!.uid);
        if (existingUser == null) {
          final displayName = credential.user!.displayName ?? 'GitHub User';
          final email = credential.user!.email ?? '';
          
          await _userService.saveUser(
            uid: credential.user!.uid,
            fullName: displayName,
            email: email,
            university: '',
          );
        }
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
  
  // ================= GET USER SERVICE =================
  UserService get userService => _userService;
}

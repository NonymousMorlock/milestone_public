import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:uuid/uuid.dart';

class MockFirebase {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockFirebaseStorage storage;

  Future<void> initAuth() async {
    final user = MockUser(
      uid: const Uuid().v1().replaceAll('-', '').substring(0, 20),
      email: 'email',
      displayName: 'displayName',
    );
    final googleSignIn = MockGoogleSignIn();
    final signInAccount = await googleSignIn.signIn();
    final googleAuth = await signInAccount!.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    auth = MockFirebaseAuth(mockUser: user);
    await auth.signInWithCredential(credential);
  }

  Future<void> initFirestore() async {
    firestore = FakeFirebaseFirestore();
  }

  Future<void> initStorage() async {
    storage = MockFirebaseStorage();
  }

  Future<void> tearDown({
    bool deleteFirestore = true,
    bool deleteStorage = true,
    bool deleteAuth = true,
  }) async {
    if (deleteFirestore) {
      await initFirestore();
    }
    if (deleteStorage) {
      await initStorage();
    }
    if (deleteAuth) {
      await initAuth();
    }
  }
}

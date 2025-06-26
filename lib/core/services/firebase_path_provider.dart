import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:milestone/core/utils/typedefs.dart';

class FirebasePathProvider {
  FirebasePathProvider({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<DataMap> get userRef =>
      _firestore.collection('users').doc(_auth.currentUser!.uid);

  DocumentReference<DataMap> projectRef(String projectId) =>
      userRef.collection('projects').doc(projectId);

  DocumentReference<DataMap> milestoneRef({
    required String projectId,
    required String milestoneId,
  }) =>
      projectRef(projectId).collection('milestones').doc(milestoneId);

  DocumentReference<DataMap> clientRef(String clientId) =>
      userRef.collection('clients').doc(clientId);
}

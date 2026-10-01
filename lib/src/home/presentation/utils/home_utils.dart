import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:milestone/app/di/injection_container.dart';

sealed class HomeUtils {
  static Stream<double> get totalEarned {
    return sl<FirebaseFirestore>()
        .collection('users')
        .doc(sl<FirebaseAuth>().currentUser!.uid)
        .snapshots()
        .map(
          (event) => (event.data()!['totalEarned'] as num?)?.toDouble() ?? 0.0,
        );
  }

  static Stream<String> get userName {
    return sl<FirebaseFirestore>()
        .collection('users')
        .doc(sl<FirebaseAuth>().currentUser!.uid)
        .snapshots()
        .map(
          (event) => event.data()!['userName'] as String? ?? 'Unknown User',
        );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/meteorological_record.dart';

class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  static DocumentReference<Map<String, dynamic>> userDoc(String uid) {
    return _users.doc(uid);
  }

  static DocumentReference<Map<String, dynamic>> latestClimateDoc(String uid) {
    return userDoc(uid).collection('climate').doc('latest');
  }

  static CollectionReference<Map<String, dynamic>> get meteorologicalRecords =>
      _db.collection('registros_meteorologicos');

  static String dayKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static Query<Map<String, dynamic>> meteorologicalRecordsQuery({
    DateTime? day,
    bool descending = true,
  }) {
    Query<Map<String, dynamic>> query = meteorologicalRecords;

    if (day != null) {
      query = query.where('fecha', isEqualTo: dayKey(day));
    }

    return query.orderBy('subido_en', descending: descending);
  }

  /// Devuelve un stream con las claves de día ("YYYY-MM-DD") que tienen
  /// registros en el rango [start, end).
  static Stream<List<String>> daysWithRecordsBetween(
      DateTime start, DateTime end) {
    // Asumimos que el campo `fecha` está en formato YYYY-MM-DD y es comparable.
    return meteorologicalRecords
        .where('fecha', isGreaterThanOrEqualTo: dayKey(start))
        .where('fecha', isLessThan: dayKey(end))
        .snapshots()
        .map((snap) {
      final set = <String>{};
      for (final doc in snap.docs) {
        final f = doc.data()['fecha'];
        if (f is String && f.isNotEmpty) set.add(f);
      }
      return set.toList();
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      meteorologicalRecordsStream({DateTime? day, bool descending = true}) {
    return meteorologicalRecordsQuery(day: day, descending: descending)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      allMeteorologicalRecordsStream({bool descending = true}) {
    return meteorologicalRecords.snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      latestMeteorologicalRecordStream() {
    return meteorologicalRecordsQuery(descending: true).limit(1).snapshots();
  }

  static MeteorologicalRecord? parseMeteorologicalRecord(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return null;
    }

    return MeteorologicalRecord.fromDoc(doc);
  }

  static Query<Map<String, dynamic>> alertsQuery(String uid,
      {String? category}) {
    Query<Map<String, dynamic>> query = userDoc(uid)
        .collection('alerts')
        .orderBy('createdAt', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query;
  }

  static Query<Map<String, dynamic>> historyForDayQuery(
      String uid, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    return userDoc(uid)
        .collection('history')
        .where('recordedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('recordedAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('recordedAt', descending: true);
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream(
      String uid) {
    return userDoc(uid).snapshots();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> latestClimateStream(
      String uid) {
    return latestClimateDoc(uid).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> alertsStream(String uid,
      {String? category}) {
    return alertsQuery(uid, category: category).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> historyStreamForDay(
      String uid, DateTime day) {
    return historyForDayQuery(uid, day).snapshots();
  }

  static Future<void> ensureUserWorkspace(User user,
      {Map<String, dynamic>? extraData}) async {
    final doc = userDoc(user.uid);
    final snapshot = await doc.get();

    final baseData = <String, dynamic>{
      'uid': user.uid,
      'displayName': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      await doc.set({
        ...baseData,
        'createdAt': FieldValue.serverTimestamp(),
        'bio': '',
        'location': '',
        'phone': '',
        'birthDate': '',
        'stats': {
          'observations': null,
          'alerts': null,
          'activeDays': null,
        },
        'preferences': {
          'notifications': true,
          'weeklyReports': true,
          'shareData': false,
        },
        ...?extraData,
      }, SetOptions(merge: true));
      return;
    }

    await doc.set({
      ...baseData,
      ...?extraData,
    }, SetOptions(merge: true));

    await latestClimateDoc(user.uid).set(
      {
        'uid': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> ensureUserDocument(User user,
      {Map<String, dynamic>? extraData}) {
    return ensureUserWorkspace(user, extraData: extraData);
  }

  static Future<void> saveProfileData(
    String uid, {
    required String displayName,
    String? bio,
    String? location,
    String? phone,
    String? birthDate,
  }) async {
    await userDoc(uid).set(
      {
        'displayName': displayName,
        'bio': bio,
        'location': location,
        'phone': phone,
        'birthDate': birthDate,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Actualiza una preferencia dentro del submapa `preferences` del documento
  /// del usuario. Usa el path con punto para actualizar sólo la clave indicada.
  static Future<void> updateUserPreference(
      String uid, String key, dynamic value) async {
    final doc = userDoc(uid);
    try {
      await doc.update({'preferences.$key': value});
    } on FirebaseException catch (e) {
      // Si el documento no existe aún, crearlo con la estructura mínima.
      if (e.code == 'not-found') {
        await doc.set({
          'preferences': {key: value},
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      }
      rethrow;
    }
  }
}

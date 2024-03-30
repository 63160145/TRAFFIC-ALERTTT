import 'package:cloud_firestore/cloud_firestore.dart';

class Database {
  static Future<List<DocumentSnapshot>> getData({required String path}) async {
    try {
      CollectionReference collection =
          FirebaseFirestore.instance.collection(path);
      QuerySnapshot querySnapshot = await collection.get();
      return querySnapshot.docs;
    } catch (e) {
      print("Error fetching data: $e");
      return [];
    }
  }
}

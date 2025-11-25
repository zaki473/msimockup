import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class FirestoreService {
  // Referensi ke koleksi 'transactions' di Firestore
  final CollectionReference _transactionsRef =
      FirebaseFirestore.instance.collection('transactions');

  // Tambah Data
  Future<void> addTransaction(TransactionModel transaction) {
    return _transactionsRef.add(transaction.toMap());
  }

  // Ambil Data (Stream) - Ini yang bikin Realtime!
  Stream<List<TransactionModel>> getTransactions() {
    return _transactionsRef
        .orderBy('date', descending: true) // Urutkan dari yang terbaru
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromSnapshot(doc);
      }).toList();
    });
  }

  // Hapus Data
  Future<void> deleteTransaction(String id) {
    return _transactionsRef.doc(id).delete();
  }
}
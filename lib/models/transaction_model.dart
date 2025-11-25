import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String id;
  final String title;
  final double amount;
  final int isIncome; // 1 = Pemasukan, 0 = Pengeluaran
  final DateTime date;

  TransactionModel({
    this.id = '',
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
  });

  // Mengubah data dari Firestore ke Object Dart
  factory TransactionModel.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      title: data['title'],
      amount: (data['amount'] as num).toDouble(), // Cegah error int vs double
      isIncome: data['isIncome'],
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  // Mengubah Object Dart ke Map untuk dikirim ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'isIncome': isIncome,
      'date': Timestamp.fromDate(date),
    };
  }
}
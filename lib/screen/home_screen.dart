import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import 'add_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Money Tracker')),
      body: StreamBuilder<List<TransactionModel>>(
        stream: FirestoreService().getTransactions(),
        builder: (context, snapshot) {
          // 1. Handle Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Handle Error
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 3. Ambil Data
          final transactions = snapshot.data ?? [];

          // 4. Hitung Total (Langsung di sini)
          double totalIncome = 0;
          double totalExpense = 0;

          for (var item in transactions) {
            if (item.isIncome == 1) {
              totalIncome += item.amount;
            } else {
              totalExpense += item.amount;
            }
          }

          return Column(
            children: [
              // Kartu Summary
              _buildSummaryCard(totalIncome, totalExpense),
              
              // List Data
              Expanded(
                child: transactions.isEmpty
                    ? const Center(child: Text("Belum ada data"))
                    : ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return ListTile(
                            leading: Icon(
                              transaction.isIncome == 1
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: transaction.isIncome == 1
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: Text(transaction.title),
                            subtitle: Text(DateFormat('dd MMM yyyy').format(transaction.date)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.grey),
                              onPressed: () {
                                FirestoreService().deleteTransaction(transaction.id);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddScreen()),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(double income, double expense) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Total Saldo", style: TextStyle(fontSize: 16)),
            Text(
              formatRupiah(income - expense),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const Text("Masuk", style: TextStyle(color: Colors.green)),
                    Text(formatRupiah(income)),
                  ],
                ),
                Column(
                  children: [
                    const Text("Keluar", style: TextStyle(color: Colors.red)),
                    Text(formatRupiah(expense)),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
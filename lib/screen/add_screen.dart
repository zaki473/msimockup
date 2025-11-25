import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  int _isIncome = 0; // 0 = Pengeluaran, 1 = Pemasukan

  void _saveTransaction() {
    // 1. Validasi Input
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi Judul dan Nominal')),
      );
      return;
    }

    // 2. Buat Object Data
    final transaction = TransactionModel(
      title: _titleController.text,
      amount: double.parse(_amountController.text),
      isIncome: _isIncome,
      date: DateTime.now(),
    );

    // 3. KIRIM KE FIREBASE DI BACKGROUND
    // Kita hapus 'await' di sini supaya tidak perlu menunggu server merespon.
    // Firebase akan mengurus pengiriman data di latar belakang.
    FirestoreService().addTransaction(transaction).then((_) {
      // (Opsional) Log jika berhasil, tapi user sudah pindah layar.
      debugPrint("Data berhasil dikirim ke server");
    }).catchError((error) {
      // (Opsional) Log jika gagal
      debugPrint("Gagal kirim data: $error");
    });

    // 4. LANGSUNG TUTUP LAYAR (INSTANT)
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input Judul
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul (cth: Beli Kopi)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Input Nominal
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Nominal (cth: 20000)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            
            // Pilihan Masuk/Keluar
            Row(
              children: [
                Expanded(
                  child: RadioListTile<int>(
                    title: const Text('Pengeluaran', style: TextStyle(fontSize: 14)),
                    value: 0,
                    groupValue: _isIncome,
                    activeColor: Colors.red,
                    onChanged: (val) => setState(() => _isIncome = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<int>(
                    title: const Text('Pemasukan', style: TextStyle(fontSize: 14)),
                    value: 1,
                    groupValue: _isIncome,
                    activeColor: Colors.green,
                    onChanged: (val) => setState(() => _isIncome = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Tombol Simpan (Tanpa Loading)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('SIMPAN', style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
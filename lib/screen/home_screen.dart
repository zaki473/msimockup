import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- VARIABEL ---
  final List<String> months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  int selectedMonthIndex = DateTime.now().month - 1; 
  int selectedYear = DateTime.now().year;

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Controller untuk Form Input
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: "1");
  String _selectedType = 'out'; // Default pengeluaran
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _categoryController.dispose();
    _descController.dispose();
    _nominalController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Firebase Money Tracker"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          
          double totalMasuk = 0;
          double totalKeluar = 0;
          List<DocumentSnapshot> filteredDocs = [];

          if (snapshot.hasData) {
            final allDocs = snapshot.data!.docs;
            
            // Filter Data Berdasarkan Bulan & Tahun
            filteredDocs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              // Handle safety jika field date null/error
              if (data['date'] == null) return false;
              
              Timestamp timestamp = data['date']; 
              DateTime date = timestamp.toDate();
              return date.month == (selectedMonthIndex + 1) && date.year == selectedYear;
            }).toList();

            // Hitung Saldo
            for (var doc in filteredDocs) {
              final data = doc.data() as Map<String, dynamic>;
              double nominal = (data['nominal'] ?? 0).toDouble();
              int qty = (data['quantity'] ?? 1).toInt();
              double total = nominal * qty;

              if (data['type'] == 'in') {
                totalMasuk += total;
              } else {
                totalKeluar += total;
              }
            }
          }
          
          double totalSaldo = totalMasuk - totalKeluar;

          // --- TAMPILAN UI ---
          return Column(
            children: [
              // 1. HEADER SALDO
              _buildHeader(totalSaldo, totalMasuk, totalKeluar),

              // 2. DROPDOWN BULAN
              _buildMonthPicker(),

              const SizedBox(height: 10),

              // 3. TABEL DATA
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: DataTable(
                          headingRowColor: MaterialStateColor.resolveWith((states) => Colors.deepPurple.shade50),
                          columns: const [
                            DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Nominal', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredDocs.isEmpty 
                            ? [] 
                            : filteredDocs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                Timestamp timestamp = data['date'];
                                DateTime date = timestamp.toDate();
                                double nominal = (data['nominal'] ?? 0).toDouble();
                                int qty = (data['quantity'] ?? 0).toInt();
                                double total = nominal * qty;
                                bool isIncome = data['type'] == 'in';

                                return DataRow(cells: [
                                  DataCell(Text(DateFormat('dd MMM yyyy', 'id_ID').format(date))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isIncome ? Colors.green[100] : Colors.red[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        data['category'] ?? '-',
                                        style: TextStyle(
                                          color: isIncome ? Colors.green[800] : Colors.red[800],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12
                                        ),
                                      ),
                                    )
                                  ),
                                  DataCell(Text(data['description'] ?? '-')),
                                  DataCell(Text(currencyFormatter.format(nominal))),
                                  DataCell(Text(qty.toString())),
                                  DataCell(
                                    Text(
                                      currencyFormatter.format(total),
                                      style: TextStyle(
                                        color: isIncome ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold
                                      ),
                                    )
                                  ),
                                  // --- REVISI BAGIAN AKSI (JADI EDIT) ---
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue), // Ikon Edit Biru
                                      tooltip: 'Edit Data',
                                      onPressed: () {
                                        // Buka form dengan membawa data yang mau diedit
                                        _showTransactionForm(docToEdit: doc);
                                      },
                                    )
                                  ),
                                ]);
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              if (filteredDocs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Belum ada data di bulan ini.", style: TextStyle(color: Colors.grey)),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTransactionForm(), // Tambah baru (tanpa parameter)
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- WIDGET UI ---

  Widget _buildMonthPicker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Pilih Bulan:", style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<int>(
            value: selectedMonthIndex,
            underline: Container(),
            items: List.generate(months.length, (index) {
              return DropdownMenuItem(
                value: index,
                child: Text("${months[index]} $selectedYear"),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedMonthIndex = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double saldo, double masuk, double keluar) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      child: Column(
        children: [
          const Text("Total Saldo (Bulan Ini)", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 5),
          Text(
            currencyFormatter.format(saldo),
            style: TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.bold, 
              color: saldo >= 0 ? Colors.black87 : Colors.red
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem("Masuk", masuk, Colors.green),
              _buildSummaryItem("Keluar", keluar, Colors.red),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          currencyFormatter.format(amount),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        )
      ],
    );
  }

  // --- LOGIKA FORM (TAMBAH / EDIT) ---

  // Fungsi ini sekarang menangani ADD dan EDIT sekaligus
  void _showTransactionForm({DocumentSnapshot? docToEdit}) {
    bool isEditing = docToEdit != null;

    if (isEditing) {
      // Jika mode EDIT, isi form dengan data yang ada
      Map<String, dynamic> data = docToEdit!.data() as Map<String, dynamic>;
      _categoryController.text = data['category'];
      _descController.text = data['description'] ?? '';
      _nominalController.text = data['nominal'].toString();
      _qtyController.text = data['quantity'].toString();
      _selectedType = data['type'];
      _selectedDate = (data['date'] as Timestamp).toDate();
    } else {
      // Jika mode TAMBAH, reset form
      _categoryController.clear();
      _descController.clear();
      _nominalController.clear();
      _qtyController.text = "1";
      _selectedType = 'out';
      _selectedDate = DateTime.now();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Text(isEditing ? "Edit Transaksi" : "Tambah Data Baru", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  // Pilihan Jenis (Masuk / Keluar)
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text("Pengeluaran")),
                          selected: _selectedType == 'out',
                          selectedColor: Colors.red[100],
                          labelStyle: TextStyle(color: _selectedType == 'out' ? Colors.red : Colors.black),
                          onSelected: (val) => setModalState(() => _selectedType = 'out'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text("Pemasukan")),
                          selected: _selectedType == 'in',
                          selectedColor: Colors.green[100],
                          labelStyle: TextStyle(color: _selectedType == 'in' ? Colors.green : Colors.black),
                          onSelected: (val) => setModalState(() => _selectedType = 'in'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("Tanggal: ${DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate)}"),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() => _selectedDate = picked);
                      }
                    },
                  ),
                  
                  TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: "Kategori (ex: Makan, Gaji)"),
                  ),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: "Deskripsi"),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _nominalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Nominal (Rp)", prefixText: "Rp "),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Qty"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEditing ? Colors.orange : Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 15)
                      ),
                      onPressed: () {
                        _saveDataToFirebase(docId: isEditing ? docToEdit!.id : null);
                        Navigator.pop(context);
                      },
                      child: Text(isEditing ? "UPDATE DATA" : "SIMPAN", style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

  // Fungsi Simpan (Mendukung Create & Update)
  Future<void> _saveDataToFirebase({String? docId}) async {
    if (_categoryController.text.isEmpty || _nominalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kategori dan Nominal harus diisi!")));
      return;
    }

    try {
      final data = {
        'date': Timestamp.fromDate(_selectedDate),
        'category': _categoryController.text,
        'description': _descController.text,
        'nominal': int.parse(_nominalController.text),
        'quantity': int.parse(_qtyController.text.isEmpty ? "1" : _qtyController.text),
        'type': _selectedType,
      };

      if (docId == null) {
        // --- CREATE BARU ---
        // Tambahkan created_at hanya saat buat baru
        data['created_at'] = FieldValue.serverTimestamp(); 
        await FirebaseFirestore.instance.collection('transactions').add(data);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data berhasil disimpan")));
      } else {
        // --- UPDATE DATA ---
        await FirebaseFirestore.instance.collection('transactions').doc(docId).update(data);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data berhasil diperbarui")));
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
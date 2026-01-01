import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/payment_method_provider.dart';
import '../providers/detail_provider.dart';
import '../models/transaction_model.dart';

/// AddTransactionScreen - Form input/edit transaksi
/// Support: detail (dropdown), amount, direction, date, category, payment method, note
class AddTransactionScreen extends StatefulWidget {
  final int accountId;
  final String accountName;
  final Transaction? transaction; // Null = add, not null = edit

  const AddTransactionScreen({
    super.key,
    required this.accountId,
    required this.accountName,
    this.transaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController(); // Note sebagai keterangan tambahan
  
  late String _direction;
  late DateTime _selectedDate;
  int? _selectedCategoryId;
  int? _selectedPaymentMethodId;
  int? _selectedDetailId; // Detail yang dipilih dari dropdown

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Load categories and payment methods
    Future.microtask(() {
      context.read<CategoryProvider>().loadCategories();
      context.read<PaymentMethodProvider>().loadMethods();
      // Jangan load semua details di awal, tunggu kategori dipilih
    });

    // Initialize form values
    if (widget.transaction != null) {
      // Edit mode
      _noteController.text = widget.transaction!.note ?? '';
      _amountController.text = widget.transaction!.amount.toString();
      _direction = widget.transaction!.direction;
      _selectedDate = widget.transaction!.date;
      _selectedCategoryId = widget.transaction!.categoryId;
      _selectedPaymentMethodId = widget.transaction!.paymentMethodId;
      _selectedDetailId = widget.transaction!.detailId;
      
      // Load details untuk kategori yang dipilih (edit mode)
      if (_selectedCategoryId != null) {
        Future.microtask(() {
          context.read<DetailProvider>().loadDetailsByCategory(_selectedCategoryId!);
        });
      }
    } else {
      // Add mode
      _direction = 'debit';
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = int.parse(_amountController.text);
      final note = _noteController.text.trim();

      final transaction = Transaction(
        id: widget.transaction?.id,
        accountId: widget.accountId,
        categoryId: _selectedCategoryId ?? 0,
        paymentMethodId: _selectedPaymentMethodId ?? 0,
        detailId: _selectedDetailId,
        amount: amount,
        direction: _direction,
        note: note.isEmpty ? null : note,
        date: _selectedDate,
      );

      if (widget.transaction == null) {
        // Add mode
        await context.read<TransactionProvider>().addTransaction(transaction);
      } else {
        // Edit mode
        await context.read<TransactionProvider>().updateTransaction(transaction);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.transaction == null
                  ? 'Transaksi berhasil ditambahkan'
                  : 'Transaksi berhasil diupdate',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Account info
            Card(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Account: ${widget.accountName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Direction (Debit/Kredit)
            const Text(
              'Jenis Transaksi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Debit (Masuk)'),
                    value: 'debit',
                    groupValue: _direction,
                    onChanged: (value) {
                      setState(() => _direction = value!);
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Kredit (Keluar)'),
                    value: 'kredit',
                    groupValue: _direction,
                    onChanged: (value) {
                      setState(() => _direction = value!);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Detail (dropdown - required, depends on category)
            if (_selectedCategoryId != null)
              Consumer<DetailProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  return DropdownButtonFormField<int>(
                    value: _selectedDetailId,
                    decoration: const InputDecoration(
                      labelText: 'Detail *',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      ...provider.details.map((detail) {
                        return DropdownMenuItem(
                          value: detail.id,
                          child: Text(detail.name),
                        );
                      }),
                      const DropdownMenuItem<int>(
                        value: -1,
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Tambah Detail Baru...', style: TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == -1) {
                        final newDetailName = await _showAddDetailDialog();
                        if (newDetailName != null && newDetailName.isNotEmpty && _selectedCategoryId != null) {
                          final detailProvider = Provider.of<DetailProvider>(context, listen: false);
                          await detailProvider.createDetail(newDetailName, _selectedCategoryId!);
                          setState(() {
                            _selectedDetailId = detailProvider.details.last.id;
                          });
                        }
                      } else {
                        setState(() => _selectedDetailId = value);
                      }
                    },
                    validator: (value) {
                      if (value == null || value == -1) {
                        return 'Detail harus dipilih';
                      }
                      return null;
                    },
                  );
                },
              ),
            if (_selectedCategoryId != null) const SizedBox(height: 16),
            
            // Hint jika kategori belum dipilih
            if (_selectedCategoryId == null)
              Card(
                color: Colors.blue.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pilih kategori terlebih dahulu untuk memilih detail',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_selectedCategoryId == null) const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Jumlah (Rp) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Jumlah tidak boleh kosong';
                }
                if (int.tryParse(value) == null) {
                  return 'Jumlah harus berupa angka';
                }
                if (int.parse(value) <= 0) {
                  return 'Jumlah harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              title: const Text('Tanggal'),
              subtitle: Text(DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 16),

            // Category (optional)
            Consumer<CategoryProvider>(
              builder: (context, provider, child) {
                return DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Kategori *',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    ...provider.categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }),
                    const DropdownMenuItem<int>(
                      value: -1,
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text('Tambah Kategori Baru...', style: TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == -1) {
                      final newCategoryName = await _showAddCategoryDialog();
                      if (newCategoryName != null && newCategoryName.isNotEmpty) {
                        final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
                        await categoryProvider.createCategory(newCategoryName);
                        final newCategoryId = categoryProvider.categories.last.id;
                        setState(() {
                          _selectedCategoryId = newCategoryId;
                          _selectedDetailId = null; // Reset detail
                        });
                        // Load details untuk kategori baru
                        if (newCategoryId != null) {
                          await Provider.of<DetailProvider>(context, listen: false)
                              .loadDetailsByCategory(newCategoryId);
                        }
                      }
                    } else if (value != null) {
                      setState(() {
                        _selectedCategoryId = value;
                        _selectedDetailId = null; // Reset detail ketika kategori berubah
                      });
                      // Load details sesuai kategori yang dipilih
                      await Provider.of<DetailProvider>(context, listen: false)
                          .loadDetailsByCategory(value);
                    }
                  },
                  validator: (value) {
                    if (value == null || value == -1) {
                      return 'Kategori harus dipilih';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Payment Method (optional)
            Consumer<PaymentMethodProvider>(
              builder: (context, provider, child) {
                return DropdownButtonFormField<int>(
                  value: _selectedPaymentMethodId,
                  decoration: const InputDecoration(
                    labelText: 'Metode Pembayaran (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                  items: provider.methods.map((method) {
                    return DropdownMenuItem(
                      value: method.id,
                      child: Text(method.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPaymentMethodId = value);
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Note (optional text field)
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Keterangan (Opsional)',
                hintText: 'Catatan tambahan',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Update' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog untuk tambah kategori baru
  Future<String?> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Kategori Baru'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nama Kategori',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  // Dialog untuk tambah detail baru
  Future<String?> _showAddDetailDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Detail Baru'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nama Detail',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }
}

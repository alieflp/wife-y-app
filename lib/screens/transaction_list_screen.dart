import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import 'add_transaction_screen.dart';

/// TransactionListScreen - List transaksi per modul
/// Filter by month, show total debit/kredit
class TransactionListScreen extends StatefulWidget {
  final int accountId;
  final String accountName;

  const TransactionListScreen({
    super.key,
    required this.accountId,
    required this.accountName,
  });

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  int? _selectedMonth;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    // Load semua transaksi untuk account ini
    Future.microtask(() {
      context.read<TransactionProvider>().loadTransactionsByAccount(
            widget.accountId,
          );
    });
  }

  void _showMonthPicker() async {
    final now = DateTime.now();
    int selectedYear = _selectedYear ?? now.year;
    int selectedMonth = _selectedMonth ?? now.month;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Bulan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: selectedYear,
              decoration: const InputDecoration(labelText: 'Tahun'),
              items: List.generate(5, (index) {
                final year = now.year - 2 + index;
                return DropdownMenuItem(value: year, child: Text('$year'));
              }),
              onChanged: (value) {
                if (value != null) selectedYear = value;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: selectedMonth,
              decoration: const InputDecoration(labelText: 'Bulan'),
              items: List.generate(12, (index) {
                final month = index + 1;
                final monthName = DateFormat.MMMM('id_ID')
                    .format(DateTime(2000, month));
                return DropdownMenuItem(
                  value: month,
                  child: Text(monthName),
                );
              }),
              onChanged: (value) {
                if (value != null) selectedMonth = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Clear filter
              setState(() {
                _selectedMonth = null;
                _selectedYear = null;
              });
              context.read<TransactionProvider>().loadTransactionsByAccount(
                    widget.accountId,
                  );
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedMonth = selectedMonth;
                _selectedYear = selectedYear;
              });
              context.read<TransactionProvider>().loadTransactionsByMonth(
                    widget.accountId,
                    selectedMonth,
                    selectedYear,
                  );
              Navigator.pop(context);
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await context
                    .read<TransactionProvider>()
                    .deleteTransaction(transaction);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaksi berhasil dihapus'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountName),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showMonthPicker,
            tooltip: 'Filter Bulan',
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedMonth != null && _selectedYear != null)
                      Text(
                        'Filter: ${DateFormat.yMMMM('id_ID').format(DateTime(_selectedYear!, _selectedMonth!))}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Debit (Masuk)'),
                            Text(
                              _currencyFormat.format(provider.totalDebit),
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Kredit (Keluar)'),
                            Text(
                              _currencyFormat.format(provider.totalCredit),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Net',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _currencyFormat.format(provider.netAmount),
                          style: TextStyle(
                            color: provider.netAmount >= 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Transaction list
              Expanded(
                child: provider.transactions.isEmpty
                    ? const Center(
                        child: Text('Belum ada transaksi'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = provider.transactions[index];
                          final isDebit = transaction.direction == 'debit';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDebit
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                                child: Icon(
                                  isDebit
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isDebit ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(transaction.note ?? 'Tanpa keterangan'),
                              subtitle: Text(
                                _dateFormat.format(transaction.date),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _currencyFormat.format(transaction.amount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDebit ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  Text(
                                    isDebit ? 'Masuk' : 'Keluar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDebit ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddTransactionScreen(
                                      accountId: widget.accountId,
                                      accountName: widget.accountName,
                                      transaction: transaction,
                                    ),
                                  ),
                                );
                              },
                              onLongPress: () =>
                                  _showDeleteConfirmation(transaction),
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(
                accountId: widget.accountId,
                accountName: widget.accountName,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';

/// ReportScreen - Laporan per bulan
/// Filter by account & month, show monthly summary
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  int? _selectedAccountId;
  int? _selectedMonth;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    // Default: bulan & tahun sekarang
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;

    Future.microtask(() {
      context.read<AccountProvider>().loadAccounts();
    });
  }

  void _loadReport() {
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih account terlebih dahulu')),
      );
      return;
    }

    if (_selectedMonth == null || _selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih bulan dan tahun terlebih dahulu')),
      );
      return;
    }

    context.read<TransactionProvider>().loadTransactionsByMonth(
          _selectedAccountId!,
          _selectedMonth!,
          _selectedYear!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Bulanan'),
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Laporan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),

                // Account dropdown
                Consumer<AccountProvider>(
                  builder: (context, provider, child) {
                    if (provider.accounts.isEmpty) {
                      return const Text('Loading accounts...');
                    }

                    return DropdownButtonFormField<int>(
                      value: _selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Account',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: provider.accounts.map((account) {
                        return DropdownMenuItem(
                          value: account.id,
                          child: Text(account.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedAccountId = value);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Month & Year
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        decoration: const InputDecoration(
                          labelText: 'Bulan',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
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
                          setState(() => _selectedMonth = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Tahun',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: List.generate(5, (index) {
                          final year = DateTime.now().year - 2 + index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          );
                        }),
                        onChanged: (value) {
                          setState(() => _selectedYear = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Load button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loadReport,
                    icon: const Icon(Icons.search),
                    label: const Text('Tampilkan Laporan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Report section
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${provider.error}'),
                      ],
                    ),
                  );
                }

                if (_selectedAccountId == null ||
                    _selectedMonth == null ||
                    _selectedYear == null) {
                  return const Center(
                    child: Text('Pilih filter dan klik "Tampilkan Laporan"'),
                  );
                }

                // Summary
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Period info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              DateFormat.yMMMM('id_ID').format(
                                DateTime(_selectedYear!, _selectedMonth!),
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${provider.transactions.length} transaksi',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Summary cards
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.green.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.arrow_downward,
                                    color: Colors.green,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Debit (Masuk)'),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currencyFormat.format(provider.totalDebit),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            color: Colors.red.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.arrow_upward,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Kredit (Keluar)'),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currencyFormat.format(provider.totalCredit),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Net amount
                    Card(
                      color: provider.netAmount >= 0
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Net (Debit - Kredit)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _currencyFormat.format(provider.netAmount),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: provider.netAmount >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Transaction list
                    if (provider.transactions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Tidak ada transaksi'),
                        ),
                      )
                    else
                      ...provider.transactions.map((transaction) {
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
                              DateFormat('dd MMM yyyy', 'id_ID')
                                  .format(transaction.date),
                            ),
                            trailing: Text(
                              _currencyFormat.format(transaction.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDebit ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

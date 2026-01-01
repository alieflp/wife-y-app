import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import 'transaction_list_screen.dart';
import 'account_list_screen.dart';
import 'report_screen.dart';
import 'category_list_screen.dart';
import 'detail_list_screen.dart';

/// HomeScreen - Dashboard & pilih modul
/// Tampilkan semua accounts dengan saldo masing-masing
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Load accounts saat screen dibuka
    Future.microtask(() {
      context.read<AccountProvider>().loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kas'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'accounts') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountListScreen(),
                  ),
                );
              } else if (value == 'categories') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryListScreen(),
                  ),
                );
              } else if (value == 'details') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DetailListScreen(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'accounts',
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet),
                    SizedBox(width: 8),
                    Text('Kelola Account'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'categories',
                child: Row(
                  children: [
                    Icon(Icons.category),
                    SizedBox(width: 8),
                    Text('Kelola Kategori'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('Kelola Detail'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportScreen(),
                ),
              );
            },
            tooltip: 'Laporan',
          ),
        ],
      ),
      body: Consumer<AccountProvider>(
        builder: (context, provider, child) {
          // Loading state
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadAccounts(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (provider.accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Belum ada account'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountListScreen(),
                        ),
                      ).then((_) => provider.loadAccounts());
                    },
                    child: const Text('Tambah Account'),
                  ),
                ],
              ),
            );
          }

          // List accounts
          return RefreshIndicator(
            onRefresh: () => provider.loadAccounts(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.accounts.length,
              itemBuilder: (context, index) {
                final account = provider.accounts[index];
                final balance = provider.getBalance(account.id!);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      account.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _currencyFormat.format(balance),
                        style: TextStyle(
                          fontSize: 16,
                          color: balance >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionListScreen(
                            accountId: account.id!,
                            accountName: account.name,
                          ),
                        ),
                      ).then((_) {
                        // Refresh balance setelah kembali dari transaction list
                        provider.refreshAllBalances();
                      });
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

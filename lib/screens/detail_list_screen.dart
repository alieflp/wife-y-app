import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/detail_provider.dart';
import '../providers/category_provider.dart';
import '../models/detail_model.dart';

/// DetailListScreen - Kelola semua details
/// CRUD operations: Create, Update, Delete details
class DetailListScreen extends StatefulWidget {
  const DetailListScreen({super.key});

  @override
  State<DetailListScreen> createState() => _DetailListScreenState();
}

class _DetailListScreenState extends State<DetailListScreen> {
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<CategoryProvider>().loadCategories();
      context.read<DetailProvider>().loadDetails();
    });
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    int? categoryId = _selectedCategoryId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Detail'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<CategoryProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<int>(
                    value: categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Kategori *',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        categoryId = value;
                      });
                    },
                    validator: (value) => value == null ? 'Pilih kategori' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Detail',
                  hintText: 'Contoh: Gaji, SPP Anak',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();

                if (categoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori harus dipilih')),
                  );
                  return;
                }

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama tidak boleh kosong')),
                  );
                  return;
                }

                try {
                  await context.read<DetailProvider>().createDetail(name, categoryId!);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Detail berhasil ditambahkan')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Detail detail) {
    final nameController = TextEditingController(text: detail.name);
    int? categoryId = detail.categoryId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Detail'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<CategoryProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<int>(
                    value: categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Kategori *',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        categoryId = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Detail',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();

                if (categoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori harus dipilih')),
                  );
                  return;
                }

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama tidak boleh kosong')),
                  );
                  return;
                }

                try {
                  final updated = Detail(
                    id: detail.id,
                    name: name,
                    categoryId: categoryId!,
                  );

                  await context.read<DetailProvider>().updateDetail(updated);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Detail berhasil diupdate')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Detail detail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Detail'),
        content: Text('Yakin ingin menghapus "${detail.name}"?'),
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
                await context.read<DetailProvider>().deleteDetail(detail.id!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Detail berhasil dihapus')),
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
        title: const Text('Kelola Detail'),
      ),
      body: Column(
        children: [
          // Filter by category
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Consumer<CategoryProvider>(
              builder: (context, provider, child) {
                return DropdownButtonFormField<int?>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Filter berdasarkan Kategori',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Semua Kategori'),
                    ),
                    ...provider.categories.map((category) {
                      return DropdownMenuItem<int?>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                    if (value == null) {
                      context.read<DetailProvider>().loadDetails();
                    } else {
                      context.read<DetailProvider>().loadDetailsByCategory(value);
                    }
                  },
                );
              },
            ),
          ),
          // List of details
          Expanded(
            child: Consumer2<DetailProvider, CategoryProvider>(
              builder: (context, detailProvider, categoryProvider, child) {
                if (detailProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (detailProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${detailProvider.error}'),
                        ElevatedButton(
                          onPressed: () {
                            if (_selectedCategoryId == null) {
                              detailProvider.loadDetails();
                            } else {
                              detailProvider.loadDetailsByCategory(_selectedCategoryId!);
                            }
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (detailProvider.details.isEmpty) {
                  return Center(
                    child: Text(
                      _selectedCategoryId == null
                          ? 'Belum ada detail'
                          : 'Belum ada detail untuk kategori ini',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: detailProvider.details.length,
                  itemBuilder: (context, index) {
                    final detail = detailProvider.details[index];
                    final category = categoryProvider.categories
                        .firstWhere((c) => c.id == detail.categoryId, orElse: () => categoryProvider.categories.first);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(detail.name),
                        subtitle: Text('Kategori: ${category.name}', style: TextStyle(color: Colors.grey.shade600)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditDialog(detail),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmation(detail),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

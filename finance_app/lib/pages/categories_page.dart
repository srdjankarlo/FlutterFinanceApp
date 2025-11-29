import 'package:flutter/material.dart';
import '../database/app_database.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = AppDatabase.instance;
    final cats = await db.db.then((d) => d.query('categories', orderBy: 'name'));
    setState(() {
      _categories = cats;
      _loading = false;
    });
  }

  Future<void> _addCategory() async {
    final text = await _openEditDialog();
    if (text == null || text.trim().isEmpty) return;

    await AppDatabase.instance.insertCategory(text.trim());
    _load();
  }

  Future<void> _editCategory(Map<String, dynamic> cat) async {
    final text = await _openEditDialog(initial: cat['name']);
    if (text == null || text.trim().isEmpty) return;

    await AppDatabase.instance.updateCategory(cat['id'], text.trim());
    _load();
  }

  Future<void> _deleteCategory(Map<String, dynamic> cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete category?"),
        content: Text("Are you sure you want to delete '${cat['name']}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await AppDatabase.instance.deleteCategory(cat['id']);
      _load();
    }
  }

  Future<String?> _openEditDialog({String? initial}) async {
    final controller = TextEditingController(text: initial ?? "");

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(initial == null ? "Add Category" : "Edit Category"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Category name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Categories")),
      floatingActionButton: FloatingActionButton(onPressed: _addCategory, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editCategory(cat)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCategory(cat)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

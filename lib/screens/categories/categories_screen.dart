import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';

class CategoriesScreen extends StatelessWidget {
  final bool embedded;
  const CategoriesScreen({super.key, this.embedded = false});

  Future<void> _showAddDialog(BuildContext context) async {
    final controller = TextEditingController();
    final provider = context.read<CategoryProvider>();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final ok = await provider.addCategory(controller.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (!ok && ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(provider.errorMessage ?? 'Failed to add category')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final c = categories[i];
          return ListTile(
            leading: const Icon(Icons.label_outline),
            title: Text(c.name),
            subtitle: c.isDefault ? const Text('Default') : null,
            trailing: c.isDefault
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          final controller = TextEditingController(text: c.name);
                          final newName = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Rename Category'),
                              content: TextField(controller: controller),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, controller.text),
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                          if (newName != null && context.mounted) {
                            context.read<CategoryProvider>().renameCategory(c.id, newName);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => context.read<CategoryProvider>().deleteCategory(c.id),
                      ),
                    ],
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// 背景色
const Color bgColor = Color(0xFFFFFDF5);

/// 禁忌项目 sub-page (CRUD).
class TabooPage extends StatefulWidget {
  const TabooPage({super.key});

  @override
  State<TabooPage> createState() => _TabooPageState();
}

class _TabooPageState extends State<TabooPage> {
  // 内存中的禁忌项目列表：name, description, emoji
  final List<Map<String, String>> _items = [
    {'name': '忌吹风', 'description': '孕期避免直接对着风扇/空调风口', 'emoji': '🌬️'},
    {'name': '忌提重物', 'description': '避免搬运超过 5kg 的重物', 'emoji': '🏋️'},
  ];

  /// 弹出新增对话框
  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedEmoji = '⚠️';
    const emojis = ['⚠️', '🚫', '🌬️', '🏋️', '🍷', '☕', '🚬', '💊'];

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('新增禁忌项目'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '名称'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: '描述'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: emojis
                      .map((e) => ChoiceChip(
                            label: Text(e),
                            selected: selectedEmoji == e,
                            onSelected: (_) => setState(() => selectedEmoji = e),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx, {
                  'name': name,
                  'description': descCtrl.text.trim(),
                  'emoji': selectedEmoji,
                });
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _items.add(result));
    }
  }

  /// 长按删除
  void _deleteItem(int index) {
    setState(() => _items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('禁忌项目'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFE67E22),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _items.isEmpty
          ? const Center(
              child: Text(
                '暂无禁忌项目',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  color: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Text(
                      item['emoji'] ?? '⚠️',
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      item['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(item['description'] ?? ''),
                    isThreeLine: (item['description'] ?? '').isNotEmpty,
                    onLongPress: () => _deleteItem(index),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteItem(index),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
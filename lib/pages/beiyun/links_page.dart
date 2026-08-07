import 'package:flutter/material.dart';

const Color _bgColor = Color(0xFFFFFDF5);
const Color _orange = Color(0xFFF5A623);
const Color _textDark = Color(0xFF333333);
const Color _textGray = Color(0xFF999999);

const List<String> _emojiOptions = [
  '🔗', '⭐', '📌', '❤️', '📖', '💡', '🎵', '🎬', '🛒', '✈️',
  '🏠', '🔥', '✅', '📚', '🎯', '🧠', '💪', '🐱', '🌸', '🍀',
];

class LinksPage extends StatefulWidget {
  const LinksPage({super.key});

  @override
  State<LinksPage> createState() => _LinksPageState();
}

class _LinksPageState extends State<LinksPage> {
  final List<Map<String, String>> _links = [];

  void _addLink() {
    _showLinkDialog(context, null);
  }

  void _editLink(Map<String, String> link) {
    _showLinkDialog(context, link);
  }

  void _deleteLink(int index) {
    setState(() => _links.removeAt(index));
  }

  Future<void> _showLinkDialog(
    BuildContext context,
    Map<String, String>? existing,
  ) async {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final urlCtrl = TextEditingController(text: existing?['url'] ?? '');
    String emoji = existing?['emoji'] ?? '🔗';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: _bgColor,
          title: Text(isEdit ? '编辑收藏' : '添加收藏'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: '标题',
                    hintText: '例如：Flutter 官网',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: '链接',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('选择图标', style: TextStyle(color: _textGray)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _emojiOptions.map((e) {
                    final selected = e == emoji;
                    return GestureDetector(
                      onTap: () => setState(() => emoji = e),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected ? _orange.withOpacity(0.15) : null,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected ? _orange : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消', style: TextStyle(color: _textGray)),
            ),
            TextButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                final url = urlCtrl.text.trim();
                if (title.isEmpty || url.isEmpty) return;
                Navigator.pop(ctx, {'title': title, 'url': url, 'emoji': emoji});
              },
              child: const Text('保存', style: TextStyle(color: _orange)),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      if (isEdit) {
        existing['title'] = result['title']!;
        existing['url'] = result['url']!;
        existing['emoji'] = result['emoji']!;
      } else {
        _links.add(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('我的收藏'),
      ),
      body: _links.isEmpty
          ? const Center(
              child: Text(
                '暂无收藏',
                style: TextStyle(fontSize: 16, color: _textGray),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _links.length,
              itemBuilder: (context, index) {
                final link = _links[index];
                return Dismissible(
                  key: ValueKey('$index-${link['title']}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteLink(index),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () => _editLink(link),
                      onLongPress: () => _deleteLink(index),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Text(
                        link['emoji'] ?? '🔗',
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(
                        link['title'] ?? '',
                        style: const TextStyle(
                          color: _textDark,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        link['url'] ?? '',
                        style: const TextStyle(color: _textGray, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLink,
        backgroundColor: _orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
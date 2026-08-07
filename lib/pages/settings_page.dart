import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../database/database_helper.dart';
import '../widgets/common.dart';
import '../main.dart';

/// 数据管理页面（导入导出 + 设置）
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _exportStatus = '';

  Future<void> _exportJson() async {
    try {
      final db = AppDatabase.instance;

      final data = {
        'app': 'hua_todo',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'data': {
          'beiyun_tasks': await db.query('beiyun_tasks'),
          'cycle_events': await db.query('cycle_events'),
          'supplement_logs': await db.query('supplement_logs'),
          'beiyun_finance': await db.query('beiyun_finance'),
          'budget_categories': await db.query('budget_categories'),
          'budget_records': await db.query('budget_records'),
          'todo_modules': await db.query('todo_modules'),
          'todo_tasks': await db.query('todo_tasks'),
        },
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/hua_todo_backup.json');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '华事务数据备份',
      );
      setState(() => _exportStatus = '✅ 导出成功');
    } catch (e) {
      setState(() => _exportStatus = '❌ 导出失败: $e');
    }
  }

  Future<void> _importJson() async {
    // 提示用户用文件选择器导入
    // 简单的实现：显示说明
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请通过文件管理器将备份文件放到 Downloads 目录，后续版本将支持文件选择')),
      );
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('这将删除所有数据，不可恢复！确定要清空吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final db = AppDatabase.instance;
    await db.delete('beiyun_tasks');
    await db.delete('cycle_events');
    await db.delete('supplement_logs');
    await db.delete('beiyun_finance');
    await db.delete('budget_categories');
    await db.delete('budget_records');
    await db.delete('todo_modules');
    await db.delete('todo_tasks');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有数据已清空')),
      );
    }
  }

  Future<void> _setWeddingDate() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString('wedding_date');
    final initial = current != null ? parseDate(current) : DateTime.now().add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      await prefs.setString('wedding_date', fmtDate(picked));
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ThemeProvider>();
    final p = prov.preset;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        leading: const DrawerMenuButton(),
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 数据导出
          _section(p, '数据管理'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                _listTile(p, Icons.upload_file, '导出数据 (JSON)', '备份所有数据到文件', _exportJson),
                const Divider(height: 1),
                _listTile(p, Icons.file_download, '导入数据', '从备份文件恢复', _importJson),
                const Divider(height: 1),
                _listTile(p, Icons.delete_forever, '清空所有数据', '不可恢复，请谨慎操作', _clearAllData,
                    color: Colors.red),
              ],
            ),
          ),
          if (_exportStatus.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_exportStatus, style: TextStyle(color: p.ink2, fontSize: 13)),
          ],

          const SizedBox(height: 24),

          // 婚礼日期
          _section(p, '备婚设置'),
          const SizedBox(height: 8),
          AppCard(
            child: _listTile(
              p,
              Icons.calendar_month,
              '设置婚礼日期',
              '',
              _setWeddingDate,
            ),
          ),

          const SizedBox(height: 24),

          // 关于
          _section(p, '关于'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('华事务 v1.0.0', style: TextStyle(color: p.ink, fontSize: 15)),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Text('备孕 · 备婚 · 事项 聚合管理',
                      style: TextStyle(color: p.ink2, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(ThemePreset p, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(title, style: TextStyle(color: p.ink2, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _listTile(ThemePreset p, IconData icon, String title, String subtitle, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? p.pri, size: 22),
      title: Text(title, style: TextStyle(color: color ?? p.ink, fontSize: 15)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: TextStyle(color: p.ink2, fontSize: 12))
          : null,
      trailing: Icon(Icons.chevron_right, color: p.ink2, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
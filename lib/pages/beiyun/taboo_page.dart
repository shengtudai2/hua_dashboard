import 'package:flutter/material.dart';

/// 禁忌项目 sub-page.
class TabooPage extends StatefulWidget {
  const TabooPage({super.key});

  @override
  State<TabooPage> createState() => _TabooPageState();
}

class _TabooPageState extends State<TabooPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFDF5),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFDF5),
        elevation: 0,
        leading: const BackButton(),
        title: const Text('禁忌项目'),
      ),
      body: const Center(
        child: Text('禁忌功能开发中'),
      ),
    );
  }
}
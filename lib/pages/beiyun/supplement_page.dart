import 'package:flutter/material.dart';

/// 营养打卡子页面
class SupplementPage extends StatefulWidget {
  const SupplementPage({super.key});

  @override
  State<SupplementPage> createState() => _SupplementPageState();
}

class _SupplementPageState extends State<SupplementPage> {
  static const Color bgColor = Color(0xFFFFFDF5);
  static const Color textDark = Color(0xFF333333);
  static const Color textGray = Color(0xFF999999);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('营养打卡',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textDark)),
        centerTitle: false,
      ),
      body: const Center(
        child: Text('营养功能开发中', style: TextStyle(fontSize: 14, color: textGray)),
      ),
    );
  }
}
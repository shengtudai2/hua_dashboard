import 'package:flutter/material.dart';

/// 主题预设 = 氛围包（配色 + 装饰 + 字体联动），不是单纯换色相
class ThemePreset {
  final String id;
  final String name;
  final String desc;
  final Color pri; // 主色
  final Color priDeep; // 主色深
  final Color accent; // 点缀色
  final Color bg; // 背景
  final Color card; // 卡片
  final Color ink; // 主文字
  final Color ink2; // 次要文字
  final Color line; // 分隔线
  final Color heroA; // hero 渐变起
  final Color heroB; // hero 渐变止
  final String? decorChar; // 页面水印字符
  final String? decorHero; // hero 角标字符
  final List<String> floaters; // 漂浮装饰粒子
  final String fontFamily;
  final String fontStyle; // rounded / modern / serif

  const ThemePreset({
    required this.id,
    required this.name,
    required this.desc,
    required this.pri,
    required this.priDeep,
    required this.accent,
    required this.bg,
    required this.card,
    required this.ink,
    required this.ink2,
    required this.line,
    required this.heroA,
    required this.heroB,
    this.decorChar,
    this.decorHero,
    this.floaters = const [],
    required this.fontFamily,
    required this.fontStyle,
  });
}

/// 多巴胺 6 色（备孕/事项/工作台默认）
class DopaminePresets {
  static const list = <ThemePreset>[
    ThemePreset(
      id: 'sakura', name: '樱花粉', desc: '温柔甜美',
      pri: Color(0xFFF48FB1), priDeep: Color(0xFFD81B60), accent: Color(0xFFFFE0B2),
      bg: Color(0xFFFDF0F5), card: Color(0xFFFFFFFF), ink: Color(0xFF4A2A3A),
      ink2: Color(0xFF9E7A8C), line: Color(0xFFF3D9E4),
      heroA: Color(0xFFFF9A9E), heroB: Color(0xFFFECFEF),
      decorChar: '🌸', decorHero: '樱', floaters: ['🌸', '💮'],
      fontFamily: 'ZCOOL KuaiLe', fontStyle: 'rounded',
    ),
    ThemePreset(
      id: 'lemon', name: '柠檬黄', desc: '清新活力',
      pri: Color(0xFFFFD54F), priDeep: Color(0xFFF9A825), accent: Color(0xFFB2FF59),
      bg: Color(0xFFFFFDF0), card: Color(0xFFFFFFFF), ink: Color(0xFF4A3F1A),
      ink2: Color(0xFF9C8F5A), line: Color(0xFFF5E9C8),
      heroA: Color(0xFFFEE140), heroB: Color(0xFFFA709A),
      decorChar: '🍋', decorHero: '柠', floaters: ['🍋', '🌟'],
      fontFamily: 'Baloo 2', fontStyle: 'rounded',
    ),
    ThemePreset(
      id: 'mint', name: '薄荷绿', desc: '清爽治愈',
      pri: Color(0xFF80DEEA), priDeep: Color(0xFF00838F), accent: Color(0xFFB2FF59),
      bg: Color(0xFFF0FDFB), card: Color(0xFFFFFFFF), ink: Color(0xFF1A3F3A),
      ink2: Color(0xFF5A8C82), line: Color(0xFFC8F0EC),
      heroA: Color(0xFF84FAB0), heroB: Color(0xFF8FD3F4),
      decorChar: '🌿', decorHero: '薄荷', floaters: ['🌿', '🍃'],
      fontFamily: 'Baloo 2', fontStyle: 'rounded',
    ),
    ThemePreset(
      id: 'peach', name: '蜜桃橙', desc: '元气暖阳',
      pri: Color(0xFFFFAB91), priDeep: Color(0xFFE64A19), accent: Color(0xFFFFE082),
      bg: Color(0xFFFFF6F0), card: Color(0xFFFFFFFF), ink: Color(0xFF4A2A1A),
      ink2: Color(0xFF9C7A5A), line: Color(0xFFF5E0D0),
      heroA: Color(0xFFFFC3A0), heroB: Color(0xFFFFAFBD),
      decorChar: '🍑', decorHero: '桃', floaters: ['🍑', '🍊'],
      fontFamily: 'ZCOOL KuaiLe', fontStyle: 'rounded',
    ),
    ThemePreset(
      id: 'taro', name: '香芋紫', desc: '静谧梦幻',
      pri: Color(0xFFB39DDB), priDeep: Color(0xFF6A1B9A), accent: Color(0xFFF8BBD0),
      bg: Color(0xFFF6F0FB), card: Color(0xFFFFFFFF), ink: Color(0xFF2A1A4A),
      ink2: Color(0xFF7A6A9C), line: Color(0xFFE3D5F0),
      heroA: Color(0xFFC1A6F0), heroB: Color(0xFFF6C6E6),
      decorChar: '💜', decorHero: '芋', floaters: ['💜', '✨'],
      fontFamily: 'Baloo 2', fontStyle: 'rounded',
    ),
    ThemePreset(
      id: 'lake', name: '湖心蓝', desc: '澄澈宁静',
      pri: Color(0xFF81D4FA), priDeep: Color(0xFF0277BD), accent: Color(0xFFB2EBF2),
      bg: Color(0xFFF0F8FD), card: Color(0xFFFFFFFF), ink: Color(0xFF1A2A4A),
      ink2: Color(0xFF5A7A9C), line: Color(0xFFC8E0F5),
      heroA: Color(0xFF89F7FE), heroB: Color(0xFF66A6FF),
      decorChar: '🌊', decorHero: '湖', floaters: ['🌊', '💧'],
      fontFamily: 'Baloo 2', fontStyle: 'rounded',
    ),
  ];
}

/// 喜庆红系 6 色（备婚默认）
class RedsPresets {
  static const list = <ThemePreset>[
    ThemePreset(
      id: 'xiqing', name: '囍庆朱红', desc: '经典喜庆',
      pri: Color(0xFFE53935), priDeep: Color(0xFFB71C1C), accent: Color(0xFFFFD54F),
      bg: Color(0xFFFFF6F3), card: Color(0xFFFFFFFF), ink: Color(0xFF4A1A1A),
      ink2: Color(0xFF9C5A5A), line: Color(0xFFF5D5D0),
      heroA: Color(0xFFFF6A5A), heroB: Color(0xFFFFC3A0),
      decorChar: '囍', decorHero: '囍', floaters: ['囍', '❤'],
      fontFamily: 'Noto Serif SC', fontStyle: 'serif',
    ),
    ThemePreset(
      id: 'qiangwei', name: '蔷薇初绽', desc: '甜美浪漫',
      pri: Color(0xFFE91E63), priDeep: Color(0xFF880E4F), accent: Color(0xFFFFC0CB),
      bg: Color(0xFFFFF0F5), card: Color(0xFFFFFFFF), ink: Color(0xFF4A1A2A),
      ink2: Color(0xFF9C5A72), line: Color(0xFFF5D5E0),
      heroA: Color(0xFFFF7EA8), heroB: Color(0xFFF8BBD0),
      decorChar: '❀', decorHero: '蔷薇', floaters: ['🌸', '💮', '❀'],
      fontFamily: 'ZCOOL KuaiLe', fontStyle: 'rounded',
    ),
    ThemePreset(
      id: 'dousha', name: '豆沙温存', desc: '温柔典雅',
      pri: Color(0xFFAD5A6A), priDeep: Color(0xFF6E2A3A), accent: Color(0xFFE8C3C8),
      bg: Color(0xFFFAF3F4), card: Color(0xFFFFFFFF), ink: Color(0xFF3A2A2A),
      ink2: Color(0xFF8A6A6A), line: Color(0xFFEAD5D8),
      heroA: Color(0xFFC97A8A), heroB: Color(0xFFEFD0D8),
      decorChar: '✿', decorHero: '豆沙', floaters: ['✿', '❁'],
      fontFamily: 'Noto Serif SC', fontStyle: 'serif',
    ),
    ThemePreset(
      id: 'shanhu', name: '珊瑚暖光', desc: '温柔治愈',
      pri: Color(0xFFFF7F7F), priDeep: Color(0xFFB8383A), accent: Color(0xFFFFE0B2),
      bg: Color(0xFFFFF6F2), card: Color(0xFFFFFFFF), ink: Color(0xFF4A2A22),
      ink2: Color(0xFF9C7262), line: Color(0xFFF5DCD2),
      heroA: Color(0xFFFFB199), heroB: Color(0xFFFFD1A9),
      decorChar: '🪸', decorHero: '珊瑚', floaters: ['⭐', '🐚'],
      fontFamily: 'Baloo 2', fontStyle: 'rounded',
    ),
    ThemePreset(
      id: 'cheli', name: '车厘子红', desc: '浓郁深邃',
      pri: Color(0xFFB71C3C), priDeep: Color(0xFF6E0E22), accent: Color(0xFFE8A0B0),
      bg: Color(0xFFFBF0F2), card: Color(0xFFFFFFFF), ink: Color(0xFF2A1A1E),
      ink2: Color(0xFF8A5A66), line: Color(0xFFF0D5DC),
      heroA: Color(0xFFC2185B), heroB: Color(0xFF8E1E3C),
      decorChar: '🍒', decorHero: '车厘子', floaters: ['🍒', '❤'],
      fontFamily: 'Noto Serif SC', fontStyle: 'serif',
    ),
    ThemePreset(
      id: 'fengtang', name: '枫糖秋意', desc: '温暖秋日',
      pri: Color(0xFFD84315), priDeep: Color(0xFF8C2A0A), accent: Color(0xFFFFCC80),
      bg: Color(0xFFFBF3EC), card: Color(0xFFFFFFFF), ink: Color(0xFF3A2418),
      ink2: Color(0xFF8C6A4E), line: Color(0xFFF0DFCE),
      heroA: Color(0xFFE8703A), heroB: Color(0xFFF5B26A),
      decorChar: '🍂', decorHero: '枫糖', floaters: ['🍁', '🍂'],
      fontFamily: 'Noto Serif SC', fontStyle: 'serif',
    ),
  ];
}

typedef PresetList = List<ThemePreset>;

/// 应用主题引擎：把预设应用到 MaterialTheme
class AppTheme {
  static final Map<String, PresetList> collections = {
    'DOPAMINE': DopaminePresets.list,
    'REDS': RedsPresets.list,
  };

  static ThemeData build(ThemePreset p) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.pri,
        primary: p.pri,
        secondary: p.accent,
        surface: p.card,
      ),
      fontFamily: _familyFor(p.fontStyle),
      scaffoldBackgroundColor: p.bg,
      cardColor: p.card,
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        elevation: 0,
        foregroundColor: p.ink,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _familyFor(p.fontStyle),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: p.ink,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: p.ink,
        displayColor: p.ink,
        fontFamily: _familyFor(p.fontStyle),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.pri,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.pri, width: 2),
        ),
      ),
      dividerColor: p.line,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static String _familyFor(String style) {
    switch (style) {
      case 'rounded':
        return 'ZCOOL KuaiLe';
      case 'serif':
        return 'Noto Serif SC';
      default:
        return 'Baloo 2';
    }
  }

  /// 打包字体方案（离线可用，不依赖 Google CDN）
  static TextStyle? displayFont(String style, {double size = 20, FontWeight? weight, Color? color}) {
    final family = _familyFor(style);
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight ?? FontWeight.w600,
      color: color,
    );
  }
}

/// 主题状态（切换 + 持久化）
class ThemeController {
  ThemePreset preset;
  final String collectionId;

  ThemeController(this.preset, this.collectionId);

  void setPreset(ThemePreset p) {
    preset = p;
  }
}
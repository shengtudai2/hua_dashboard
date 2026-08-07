import 'package:flutter/material.dart';

/// Web 版设计系统常量（对应 shared/base.css 的 CSS 变量）
class WebTheme {
  // 默认配色（备孕 sakura）
  static const Color pri = Color(0xFFE8638C);
  static const Color priDeep = Color(0xFFC74B74);
  static const Color priSoft = Color(0xFFFBDCE6);
  static const Color priSofter = Color(0xFFFFF0F5);
  static const Color bg = Color(0xFFFFF6F8);
  static const Color bg2 = Color(0xFFFBE9EF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF4A2B36);
  static const Color ink2 = Color(0xFF9A7383);
  static const Color line = Color(0xFFF3D7E0);
  static const Color heroA = Color(0xFFF9A8C0);
  static const Color heroB = Color(0xFFEF6D94);
  static const Color accent = Color(0xFF5FA980);
  static const Color accentSoft = Color(0xFFE2F2E9);
  static const Color danger = Color(0xFFD95555);

  // 事件颜色
  static const Color evRed = Color(0xFFE88A8A);
  static const Color evPink = Color(0xFFE887A4);
  static const Color evGold = Color(0xFFD9A85A);
  static const Color evPurple = Color(0xFFB59AD9);
  static const Color evGreen = Color(0xFF5FA980);
  static const Color evBlue = Color(0xFF8AB3E0);
  static const Color evOrange = Color(0xFFF09577);

  // 尺寸
  static const double rCard = 18.0;
  static const double rCardInner = 14.0;
  static const double rBtn = 999.0;
  static const double rModal = 24.0;

  // 阴影
  static final BoxShadow shadowCard = BoxShadow(
    color: const Color(0xFF965A6E).withValues(alpha: 0.08),
    blurRadius: 10,
    offset: const Offset(0, 2),
  );
  static final BoxShadow shadowPop = BoxShadow(
    color: const Color(0xFF964664).withValues(alpha: 0.22),
    blurRadius: 34,
    offset: const Offset(0, 10),
  );
}

/// 卡片组件（对应 .card）
class WebCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  const WebCard({super.key, required this.child, this.padding, this.margin, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color ?? WebTheme.card,
        borderRadius: BorderRadius.circular(WebTheme.rCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(WebTheme.rCard),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: WebTheme.line),
              borderRadius: BorderRadius.circular(WebTheme.rCard),
              boxShadow: [WebTheme.shadowCard],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Hero 卡（对应 .hero）
class WebHeroCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const WebHeroCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: WebTheme.card,
          border: Border.all(color: WebTheme.priSoft),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [WebTheme.shadowCard],
        ),
        child: Stack(
          children: [
            // 右上角装饰圆
            Positioned(
              right: -52, top: -62,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: WebTheme.priSofter.withValues(alpha: 0.75),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// 底部弹窗（对应 .modal-card）
class WebBottomSheet extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  const WebBottomSheet({super.key, required this.title, required this.child, this.actions});

  static Future<T?> show<T>(BuildContext context, {required String title, required Widget child, List<Widget>? actions}) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => WebBottomSheet(title: title, child: child, actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WebTheme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(WebTheme.rModal)),
        boxShadow: [WebTheme.shadowPop],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽条
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Container(
                width: 38, height: 4,
                decoration: BoxDecoration(
                  color: WebTheme.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 头部
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(
                    fontFamily: 'ZCOOL KuaiLe',
                    fontSize: 17,
                    color: WebTheme.ink,
                  )),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: WebTheme.bg2,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.close, size: 15, color: WebTheme.ink2),
                    ),
                  ),
                ],
              ),
            ),
            // 内容
            Flexible(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 16),
              child: child,
            )),
            // 底部按钮
            if (actions != null) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: WebTheme.line)),
                  color: WebTheme.card,
                ),
                child: Row(children: actions!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 渐变按钮（对应 .btn）
class WebGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool ghost;
  final bool small;
  final bool danger;
  final IconData? icon;
  const WebGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.ghost = false,
    this.small = false,
    this.danger = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = ghost
        ? Colors.transparent
        : danger
            ? WebTheme.card
            : const LinearGradient(colors: [WebTheme.heroA, WebTheme.heroB]);
    final fg = ghost
        ? WebTheme.priDeep
        : danger
            ? WebTheme.danger
            : Colors.white;
    final border = ghost
        ? Border.all(color: WebTheme.pri)
        : danger
            ? Border.all(color: const Color(0xFFEFB9B9))
            : null;

    return Container(
      height: small ? 34 : 44,
      decoration: BoxDecoration(
        gradient: bg is Gradient ? bg : null,
        color: bg is Color ? bg : null,
        borderRadius: BorderRadius.circular(WebTheme.rBtn),
        border: border,
        boxShadow: ghost || danger
            ? null
            : [BoxShadow(
                color: WebTheme.heroB.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(WebTheme.rBtn),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: small ? 13 : 18, vertical: small ? 6 : 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: small ? 14 : 18, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(label, style: TextStyle(
                  color: fg,
                  fontSize: small ? 12 : 14,
                  fontWeight: FontWeight.w700,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 待办行（对应 .todo-row）
class WebTodoRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool done;
  final String? dueText;
  final Color? dueColor;
  final VoidCallback? onTap;
  const WebTodoRow({
    super.key,
    required this.title,
    this.subtitle,
    this.done = false,
    this.dueText,
    this.dueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: WebTheme.line, style: BorderStyle.solid)),
        ),
        child: Row(
          children: [
            // 勾选圆点
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? WebTheme.accent : WebTheme.card,
                border: Border.all(
                  color: done ? WebTheme.accent : WebTheme.pri,
                  width: 2,
                ),
              ),
              child: done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: done ? WebTheme.ink2 : WebTheme.ink,
                    decoration: done ? TextDecoration.lineThrough : null,
                  )),
                  if (subtitle != null)
                    Text(subtitle!, style: const TextStyle(fontSize: 11, color: WebTheme.ink2)),
                ],
              ),
            ),
            if (dueText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: dueColor?.withValues(alpha: 0.15) ?? WebTheme.bg2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(dueText!, style: TextStyle(
                  fontFamily: 'ZCOOL KuaiLe',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: dueColor ?? WebTheme.ink2,
                )),
              ),
          ],
        ),
      ),
    );
  }
}

/// 统计网格（对应 .stats / .stat）
class WebStatsGrid extends StatelessWidget {
  final List<WebStatItem> items;
  const WebStatsGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: WebTheme.card,
        border: Border.all(color: WebTheme.line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [WebTheme.shadowCard],
      ),
      child: Row(
        children: items.asMap().entries.map((e) {
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                border: e.key > 0 ? const Border(left: BorderSide(color: WebTheme.line)) : null,
              ),
              child: Column(
                children: [
                  Text(e.value.number, style: const TextStyle(
                    fontFamily: 'ZCOOL KuaiLe',
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: WebTheme.ink,
                  )),
                  Text(e.value.label, style: const TextStyle(fontSize: 10.5, color: WebTheme.ink2)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class WebStatItem {
  final String number;
  final String label;
  const WebStatItem(this.number, this.label);
}

/// 阶段组（对应 .stage-group）
class WebStageGroup extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String badge;
  final Color badgeColor;
  final double progress;
  final Widget child;
  final VoidCallback? onAdd;
  const WebStageGroup({
    super.key,
    required this.name,
    this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.progress,
    required this.child,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 9, 9, 9),
            decoration: BoxDecoration(
              color: WebTheme.bg2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [badgeColor.withValues(alpha: 0.8), badgeColor],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(badge, style: const TextStyle(
                    fontFamily: 'ZCOOL KuaiLe', fontSize: 15, color: Colors.white,
                  ))),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name, style: const TextStyle(
                            fontFamily: 'ZCOOL KuaiLe', fontSize: 14.5,
                          )),
                          if (subtitle != null) ...[
                            const SizedBox(width: 6),
                            Text(subtitle!, style: const TextStyle(
                              fontSize: 10.5, color: WebTheme.ink2,
                            )),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Container(
                          height: 5,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0x11000000),
                            valueColor: AlwaysStoppedAnimation(badgeColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onAdd != null)
                  GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: WebTheme.pri, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('+', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: WebTheme.priDeep,
                      )),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          child,
        ],
      ),
    );
  }
}

/// 任务行（对应 .task-row）
class WebTaskRow extends StatelessWidget {
  final String title;
  final String? meta;
  final bool done;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback? onTap;
  const WebTaskRow({
    super.key,
    required this.title,
    this.meta,
    this.done = false,
    this.badge,
    this.badgeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        margin: const EdgeInsets.only(bottom: 7),
        decoration: BoxDecoration(
          color: WebTheme.card,
          border: Border.all(color: WebTheme.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // 状态圆
            Container(
              width: 27, height: 27,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? WebTheme.accent : WebTheme.card,
                border: Border.all(
                  color: done ? WebTheme.accent : WebTheme.line,
                  width: 2,
                ),
              ),
              child: done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: done ? WebTheme.ink2 : WebTheme.ink,
                    decoration: done ? TextDecoration.lineThrough : null,
                  )),
                  if (meta != null)
                    Text(meta!, style: const TextStyle(fontSize: 10.5, color: WebTheme.ink2)),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                decoration: BoxDecoration(
                  color: (badgeColor ?? WebTheme.ink2).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(badge!, style: TextStyle(
                  fontFamily: 'ZCOOL KuaiLe',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: badgeColor ?? WebTheme.ink2,
                )),
              ),
          ],
        ),
      ),
    );
  }
}

/// 页面标题（对应 .page-title）
class WebPageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const WebPageTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
      child: Row(
        children: [
          Text(title, style: const TextStyle(
            fontFamily: 'ZCOOL KuaiLe',
            fontSize: 19,
            color: WebTheme.ink,
          )),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Text(subtitle!, style: const TextStyle(
              fontSize: 11, color: WebTheme.ink2,
            )),
          ],
        ],
      ),
    );
  }
}

/// 筛选 chip（对应 .chip）
class WebChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const WebChip({super.key, required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? WebTheme.pri : WebTheme.bg2,
          borderRadius: BorderRadius.circular(999),
          border: active ? Border.all(color: Colors.transparent) : null,
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : WebTheme.ink2,
        )),
      ),
    );
  }
}

/// 表单字段（对应 .field）
class WebFormField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool required;
  const WebFormField({super.key, required this.label, required this.child, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(
            text: label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: WebTheme.ink2),
            children: required ? [const TextSpan(
              text: ' *', style: TextStyle(color: WebTheme.danger),
            )] : null,
          )),
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
  }
}

/// 输入框（对应 .field input）
class WebInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  const WebInput({super.key, this.controller, this.hint, this.keyboardType, this.maxLines = 1, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: WebTheme.ink2, fontSize: 14),
        filled: true,
        fillColor: WebTheme.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WebTheme.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WebTheme.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: WebTheme.pri, width: 1.5),
        ),
      ),
    );
  }
}

/// 卡片标题行（对应 .card-head + .card-title）
class WebCardTitle extends StatelessWidget {
  final String title;
  final String? linkText;
  final VoidCallback? onLink;
  const WebCardTitle({super.key, required this.title, this.linkText, this.onLink});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(
            fontFamily: 'ZCOOL KuaiLe',
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: WebTheme.ink,
          )),
          if (linkText != null)
            GestureDetector(
              onTap: onLink,
              child: Text(linkText!, style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: WebTheme.priDeep,
              )),
            ),
        ],
      ),
    );
  }
}

/// 空状态（对应 Web 风格）
class WebEmptyState extends StatelessWidget {
  final String icon;
  final String text;
  const WebEmptyState({super.key, this.icon = '📋', required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(fontSize: 13, color: WebTheme.ink2)),
          ],
        ),
      ),
    );
  }
}
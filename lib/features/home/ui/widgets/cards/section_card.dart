import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final String actionText;
  final Widget dragHandle;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    required this.actionText,
    required this.dragHandle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final hasTitle = title.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTitle)
            Row(
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                if (actionText.isNotEmpty)
                  Text(
                    actionText,
                    style: const TextStyle(
                      color: Color(0xFF3AA7FF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(width: 8),
                dragHandle,
              ],
            )
          else
            Align(alignment: Alignment.centerRight, child: dragHandle),
          if (hasTitle) const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

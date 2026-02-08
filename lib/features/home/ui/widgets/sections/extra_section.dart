import 'package:flutter/material.dart';

class ExtraSection extends StatelessWidget {
  final bool modeOn;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const ExtraSection({
    super.key,
    required this.modeOn,
    required this.onModeChanged,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SoftBox(
                child: Row(
                  children: const [
                    Text('text', style: TextStyle(fontWeight: FontWeight.w700)),
                    Spacer(),
                    Text('— —', style: TextStyle(color: Colors.black26, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SoftBox(
                child: Row(
                  children: [
                    const Text('Mode?', style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Switch(value: modeOn, onChanged: onModeChanged),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SoftBox(
          child: Row(
            children: [
              IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_rounded)),
              const Expanded(child: Divider(thickness: 1, height: 1)),
              IconButton(onPressed: onPlus, icon: const Icon(Icons.add_rounded)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SoftBox extends StatelessWidget {
  final Widget child;
  const _SoftBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

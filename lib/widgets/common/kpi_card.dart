import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String unit;

  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B274D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF143B70),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFFAAB7CD),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (unit.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFFAAB7CD),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

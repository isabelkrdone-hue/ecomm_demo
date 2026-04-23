import 'package:flutter/material.dart';

import 'app_ui.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: const [
        ShimmerBlock(height: 54, borderRadius: 18),
        SizedBox(height: 16),
        ShimmerBlock(height: 160, borderRadius: 24),
        SizedBox(height: 24),
        ShimmerBlock(width: 120, height: 20),
        SizedBox(height: 12),
        SizedBox(
          height: 102,
          child: Row(
            children: [
              Expanded(child: ShimmerBlock(height: 102, borderRadius: 18)),
              SizedBox(width: 12),
              Expanded(child: ShimmerBlock(height: 102, borderRadius: 18)),
              SizedBox(width: 12),
              Expanded(child: ShimmerBlock(height: 102, borderRadius: 18)),
            ],
          ),
        ),
        SizedBox(height: 24),
        ShimmerBlock(width: 110, height: 20),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: ShimmerBlock(height: 280, borderRadius: 20)),
            SizedBox(width: 12),
            Expanded(child: ShimmerBlock(height: 280, borderRadius: 20)),
          ],
        ),
      ],
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, size: 46, color: const Color(0xFF2563EB)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF64748B),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

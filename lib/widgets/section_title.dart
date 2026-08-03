import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    required this.action,
    this.onActionTap,
  });

  final String title;
  final String action;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: K.dark, fontSize: 20, fontWeight: FontWeight.w600),
            ),
            if (action.isNotEmpty)
              InkWell(
                onTap: onActionTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    action,
                    style: const TextStyle(color: K.limeText, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Text('Coming soon', style: TextStyle(color: K.dark, fontSize: 22, fontWeight: FontWeight.w700)),
      );
}

import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';

class ApiErrorView extends StatelessWidget {
  const ApiErrorView({super.key, required this.error});
  final Object error;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, color: K.green, size: 44), const SizedBox(height: 12), const Text('Unable to load news', style: TextStyle(color: K.dark, fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('$error', textAlign: TextAlign.center, style: const TextStyle(color: K.body))])));
}

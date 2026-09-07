import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveSessionsScreen extends ConsumerWidget {
  const ActiveSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Sessions'), centerTitle: true),
      body: const Center(
        child: Text(
          'Active Sessions Data will appear here.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

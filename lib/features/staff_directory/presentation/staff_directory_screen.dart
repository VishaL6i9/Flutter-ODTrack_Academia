import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StaffDirectoryScreen extends ConsumerWidget {
  const StaffDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Directory'),
      ),
      body: const Center(
        child: Text(
          'Staff Directory Screen\n(To be implemented)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class BatchHistoryScreen extends StatefulWidget {
  const BatchHistoryScreen({super.key});

  @override
  State<BatchHistoryScreen> createState() => _BatchHistoryScreenState();
}

class _BatchHistoryScreenState extends State<BatchHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch History'),
      ),
      body: const Center(
        child: Text(
          'Batch History Screen\n(Under Construction)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
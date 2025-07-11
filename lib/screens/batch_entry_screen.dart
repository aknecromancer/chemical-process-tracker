import 'package:flutter/material.dart';

class BatchEntryScreen extends StatefulWidget {
  final DateTime date;
  
  const BatchEntryScreen({super.key, required this.date});

  @override
  State<BatchEntryScreen> createState() => _BatchEntryScreenState();
}

class _BatchEntryScreenState extends State<BatchEntryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Batch Entry - ${widget.date.day}/${widget.date.month}/${widget.date.year}'),
      ),
      body: const Center(
        child: Text(
          'Batch Entry Screen\n(Under Construction)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
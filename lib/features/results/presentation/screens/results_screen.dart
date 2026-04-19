import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Résultats')),
      body: const Center(child: Text('À venir')),
    );
  }
}

import 'package:flutter/material.dart';

class SquarePage extends StatelessWidget {
  const SquarePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Square')),
      body: const Center(child: Text('Square module placeholder.')),
    );
  }
}

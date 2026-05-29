import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/home_content.dart';
import 'widgets/home_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DigiPlayers')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            HomeContent.tagline,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/learn'),
            icon: const Icon(Icons.school_outlined),
            label: const Text('开始学习'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 32),
          const FraudSummarySection(),
          const SizedBox(height: 32),
          const TimelineSection(),
          const SizedBox(height: 32),
          const GlossarySection(),
          const SizedBox(height: 32),
          const FlowOverviewSection(),
          const SizedBox(height: 32),
          const LearnMapSection(),
          const SizedBox(height: 32),
          const ExternalLinksSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

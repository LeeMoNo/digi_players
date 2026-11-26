import 'package:flutter/material.dart';

import '../../core/layout/reading_width.dart';
import '../../core/router/app_back_button.dart';
import 'legal_text.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    final sections = legalSections(doc);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: appBarLeading(context),
        title: Text(legalTitle(doc)),
      ),
      body: ReadingWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            for (var i = 0; i < sections.length; i++) ...[
              if (i > 0) const SizedBox(height: 20),
              Text(
                sections[i].heading,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                sections[i].body,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

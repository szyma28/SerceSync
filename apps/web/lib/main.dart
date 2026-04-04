import 'package:flutter/material.dart';

void main() {
  runApp(const SerceSyncWebApp());
}

class SerceSyncWebApp extends StatelessWidget {
  const SerceSyncWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SerceSync Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF335C81)),
      ),
      home: const _FoundationScreen(
        title: 'SerceSync Web',
        subtitle: 'Foundation scaffold for the manager web app.',
      ),
    );
  }
}

class _FoundationScreen extends StatelessWidget {
  const _FoundationScreen({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sercesync_mobile/widgets/data_freshness_indicator.dart';
import 'package:sercesync_mobile/widgets/resume_refresh_mixin.dart';

void main() {
  testWidgets('resume refresh fires once and debounces rapid resumes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: _ResumeRefreshHarness()),
    );

    expect(find.text('Refreshes 0'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('Refreshes 1'), findsOneWidget);
    expect(find.text('Visible content'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('Refreshes 1'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 20));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));

    expect(find.text('Refreshes 2'), findsOneWidget);
  });

  testWidgets('silent resume refresh keeps visible content on screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: _ResumeRefreshHarness()),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('Visible content'), findsOneWidget);
    expect(find.text('Refreshing…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 40));

    expect(find.text('Visible content'), findsOneWidget);
    expect(find.textContaining('Updated 22/04 10:30'), findsOneWidget);
  });
}

class _ResumeRefreshHarness extends StatefulWidget {
  const _ResumeRefreshHarness();

  @override
  State<_ResumeRefreshHarness> createState() => _ResumeRefreshHarnessState();
}

class _ResumeRefreshHarnessState extends State<_ResumeRefreshHarness>
    with WidgetsBindingObserver, ResumeRefreshStateMixin {
  int _refreshCount = 0;
  bool _isRefreshing = false;

  @override
  Duration get resumeRefreshDebounce => const Duration(milliseconds: 10);

  @override
  bool get hasVisibleContentForResumeRefresh => true;

  @override
  Future<void> refreshAfterResume() async {
    setState(() {
      _refreshCount += 1;
      _isRefreshing = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (!mounted) {
      return;
    }
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DataFreshnessIndicator(
            lastUpdatedAt: DateTime.utc(2026, 4, 22, 10, 30),
            isRefreshing: _isRefreshing,
            label: 'Live workspace',
          ),
          Text('Refreshes $_refreshCount'),
          const Text('Visible content'),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/widgets.dart';

mixin ResumeRefreshStateMixin<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  bool _isResumeRefreshInFlight = false;
  DateTime? _lastResumeRefreshAt;

  @protected
  Duration get resumeRefreshDebounce => const Duration(seconds: 2);

  @protected
  bool get canTriggerResumeRefresh => true;

  @protected
  bool get hasVisibleContentForResumeRefresh;

  @protected
  Future<void> refreshAfterResume();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    final lastResumeRefreshAt = _lastResumeRefreshAt;
    if (_isResumeRefreshInFlight ||
        !canTriggerResumeRefresh ||
        !hasVisibleContentForResumeRefresh ||
        (lastResumeRefreshAt != null &&
            DateTime.now().difference(lastResumeRefreshAt) <
                resumeRefreshDebounce)) {
      return;
    }

    _isResumeRefreshInFlight = true;
    _lastResumeRefreshAt = DateTime.now();
    unawaited(_runResumeRefresh());
  }

  Future<void> _runResumeRefresh() async {
    try {
      await refreshAfterResume();
    } finally {
      _isResumeRefreshInFlight = false;
    }
  }
}

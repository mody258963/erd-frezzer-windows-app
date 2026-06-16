import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tabbed hub that groups related entity screens (suppliers, customers, …).
class EntityHubScreen extends StatefulWidget {
  const EntityHubScreen({
    required this.tabs,
    this.initialTabId,
    super.key,
  });

  final List<EntityHubTab> tabs;
  final String? initialTabId;

  @override
  State<EntityHubScreen> createState() => _EntityHubScreenState();
}

class EntityHubTab {
  const EntityHubTab({
    required this.id,
    required this.label,
    required this.child,
  });

  final String id;
  final String label;
  final Widget child;
}

class _EntityHubScreenState extends State<EntityHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    final initialIndex = _indexForTabId(widget.initialTabId);
    _controller = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: initialIndex.clamp(0, widget.tabs.length - 1),
    );
  }

  @override
  void didUpdateWidget(EntityHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) {
      _controller.dispose();
      final initialIndex = _indexForTabId(widget.initialTabId);
      _controller = TabController(
        length: widget.tabs.length,
        vsync: this,
        initialIndex: initialIndex.clamp(0, widget.tabs.length - 1),
      );
    } else if (widget.initialTabId != oldWidget.initialTabId &&
        widget.initialTabId != null) {
      final idx = _indexForTabId(widget.initialTabId);
      if (idx >= 0 && idx < widget.tabs.length) {
        _controller.index = idx;
      }
    }
  }

  int _indexForTabId(String? id) {
    if (id == null) return 0;
    return widget.tabs.indexWhere((t) => t.id == id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.surfaceContainerHighest,
          child: TabBar(
            controller: _controller,
            isScrollable: widget.tabs.length > 3,
            tabAlignment: widget.tabs.length > 3
                ? TabAlignment.start
                : TabAlignment.fill,
            tabs: [for (final t in widget.tabs) Tab(text: t.label)],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: [for (final t in widget.tabs) t.child],
          ),
        ),
      ],
    );
  }
}

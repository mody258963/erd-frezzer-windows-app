import 'package:flutter/material.dart';

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.actions,
    this.scrollable = true,
    this.padding = const EdgeInsets.all(24),
    this.dense = false,
  });

  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget child;
  final bool scrollable;
  final EdgeInsets padding;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final header = (title != null || subtitle != null || actions != null)
        ? Padding(
            padding: EdgeInsets.fromLTRB(
              padding.left,
              padding.top,
              padding.right,
              0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: Directionality.of(context),
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          maxLines: dense ? 1 : null,
                          overflow: dense ? TextOverflow.ellipsis : null,
                          style: dense
                              ? Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  )
                              : Theme.of(context).textTheme.headlineSmall,
                        ),
                      if (subtitle != null && !dense) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          )
        : null;

    final body = Padding(
      padding: EdgeInsets.fromLTRB(
        padding.left,
        header != null ? (dense ? 8 : 16) : padding.top,
        padding.right,
        padding.bottom,
      ),
      child: child,
    );

    if (!scrollable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) header,
          Expanded(child: body),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) header,
          body,
        ],
      ),
    );
  }
}

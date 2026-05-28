import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/api_labels.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/theme/app_colors.dart';
import '../../../router/route_paths.dart';
import '../product_analysis.dart';

class ProductRankingPanel extends StatelessWidget {
  const ProductRankingPanel({
    required this.products,
    super.key,
  });

  final List<ProductAnalysisItem> products;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final top = products.take(6).toList();
    if (top.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(l10n.noProductData)),
        ),
      );
    }

    final maxRev = top.map((p) => p.revenue).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.productAnalysisTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        l10n.productAnalysisSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(RoutePaths.parts),
                  child: Text(l10n.viewAllProducts),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < top.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _RankRow(
                rank: i + 1,
                product: top[i],
                share: maxRev > 0 ? top[i].revenue / maxRev : 0,
                onTap: top[i].partId.isNotEmpty
                    ? () => context.push(
                          RoutePaths.partAnalysis(top[i].partId),
                        )
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.product,
    required this.share,
    this.onTap,
  });

  final int rank;
  final ProductAnalysisItem product;
  final double share;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: Directionality.of(context),
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '$rank',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '${l10n.unitsSold}: ${product.quantitySold} · ${l10n.revenue}: ${formatMoney(context, product.revenue)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: share,
                  minHeight: 5,
                  backgroundColor: AppColors.outline.withValues(alpha: 0.25),
                ),
              ),
            ],
          ),
        ),
        if (product.lowStock)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 8),
            child: Icon(Icons.warning_amber_rounded,
                size: 20, color: AppColors.warning),
          ),
        if (onTap != null)
          Icon(
            Icons.chevron_left,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      ],
    ),
    );
  }
}

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/images/part_image_cache.dart';

/// Opens a full-screen viewer with pinch/zoom. Tap outside or close to dismiss.
Future<void> showImageLightbox(
  BuildContext context, {
  String? networkUrl,
  File? file,
  String? assetPath,
}) async {
  final hasNetwork = networkUrl != null && networkUrl.isNotEmpty;
  final hasFile = file != null;
  final hasAsset = assetPath != null && assetPath.isNotEmpty;
  if (!hasNetwork && !hasFile && !hasAsset) return;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.94),
    barrierDismissible: true,
    useSafeArea: false,
    builder: (ctx) => _ImageLightboxDialog(
      networkUrl: hasNetwork ? networkUrl : null,
      file: hasFile ? file : null,
      assetPath: hasAsset ? assetPath : null,
    ),
  );
}

class _ImageLightboxDialog extends StatelessWidget {
  const _ImageLightboxDialog({
    this.networkUrl,
    this.file,
    this.assetPath,
  });

  final String? networkUrl;
  final File? file;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final imageWidth = size.width * 0.96;
    final imageHeight = size.height * 0.92;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              Navigator.of(context).pop();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Dialog.fullscreen(
            backgroundColor: Colors.transparent,
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: InteractiveViewer(
                        minScale: 0.75,
                        maxScale: 6,
                        boundaryMargin: const EdgeInsets.all(48),
                        child: SizedBox(
                          width: imageWidth,
                          height: imageHeight,
                          child: _buildImage(imageWidth, imageHeight),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 8,
                    right: 12,
                    child: IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 28),
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(double width, double height) {
    if (file != null) {
      return Image.file(
        file!,
        width: width,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }
    if (networkUrl != null) {
      return CachedNetworkImage(
        imageUrl: networkUrl!,
        cacheManager: PartImageCache.manager,
        width: width,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        placeholder: (_, __) => _LoadingPlaceholder(width: width, height: height),
        errorWidget: (_, __, ___) =>
            _ErrorPlaceholder(width: width, height: height),
      );
    }
    return Image.asset(
      assetPath!,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) =>
          _ErrorPlaceholder(width: width, height: height),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, size: 80, color: Colors.white54),
      ),
    );
  }
}

/// Wraps [child] so a tap opens the lightbox when [onTap] is set.
class LightboxTapTarget extends StatelessWidget {
  const LightboxTapTarget({
    required this.child,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled || onTap == null) return child;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );
  }
}

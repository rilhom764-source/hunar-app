import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Универсальный виджет для отображения изображений:
/// - http/https URL → CachedNetworkImage
/// - data:image/...;base64,... → Image.memory (декодирует base64)
/// Используйте ВЕЗДЕ вместо CachedNetworkImage!
class SmartImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (imageUrl.startsWith('data:')) {
      image = _buildDataUrlImage();
    } else {
      image = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (ctx, url) => placeholder ?? _defaultPlaceholder(),
        errorWidget: (ctx, url, error) => errorWidget ?? _defaultError(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _buildDataUrlImage() {
    try {
      final commaIndex = imageUrl.indexOf(',');
      if (commaIndex == -1) return errorWidget ?? _defaultError();
      final base64Data = imageUrl.substring(commaIndex + 1);
      final bytes = base64Decode(base64Data);
      return Image.memory(
        Uint8List.fromList(bytes),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, err, stack) => errorWidget ?? _defaultError(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SmartImage: Error decoding data URL: $e');
      }
      return errorWidget ?? _defaultError();
    }
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _defaultError() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image, color: Colors.grey, size: 24),
    );
  }
}

/// Универсальный ImageProvider: CachedNetworkImageProvider для http(s),
/// MemoryImage для data: URL
ImageProvider smartImageProvider(String url) {
  if (url.startsWith('data:')) {
    try {
      final commaIndex = url.indexOf(',');
      if (commaIndex != -1) {
        final base64Data = url.substring(commaIndex + 1);
        final bytes = base64Decode(base64Data);
        return MemoryImage(Uint8List.fromList(bytes));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('smartImageProvider: Error decoding data URL: $e');
      }
    }
    // Fallback — transparent pixel
    return MemoryImage(Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00,
      0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
      0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89,
      0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x62,
      0x00, 0x00, 0x00, 0x02, 0x00, 0x01, 0xE5, 0x27, 0xDE, 0xFC, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]));
  }
  return CachedNetworkImageProvider(url);
}

/// Улучшенный виджет для отображения сетевых изображений
/// с лучшей обработкой ошибок и логированием
class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const NetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Отладочный вывод URL
    if (kDebugMode) {
      debugPrint('🖼️ NetworkImageWidget: Loading $imageUrl');
    }

    final defaultPlaceholder = Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );

    final defaultError = Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.grey.shade400, size: 32),
          const SizedBox(height: 4),
          Text(
            'Ошибка загрузки',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      // Добавляем заголовки для Firebase Storage
      httpHeaders: const {
        'Accept': 'image/*',
      },
      // Настройки кэширования
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
      placeholder: (context, url) => placeholder ?? defaultPlaceholder,
      errorWidget: (context, url, error) {
        if (kDebugMode) {
          debugPrint('❌ NetworkImageWidget Error: $error for URL: $url');
        }
        return errorWidget ?? defaultError;
      },
      // Логирование процесса загрузки
      progressIndicatorBuilder: (context, url, downloadProgress) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              value: downloadProgress.progress,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}

/// Провайдер изображений для CircleAvatar с улучшенной обработкой
class SafeNetworkImageProvider extends CachedNetworkImageProvider {
  SafeNetworkImageProvider(super.url)
      : super(
          headers: const {
            'Accept': 'image/*',
          },
          errorListener: (error) {
            if (kDebugMode) {
              debugPrint('❌ SafeNetworkImageProvider Error: $error');
            }
          },
        );
}

/// Простой виджет Image.network с fallback
class SimpleNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const SimpleNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('🖼️ SimpleNetworkImage: Loading $imageUrl');
    }

    Widget image = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          debugPrint('❌ SimpleNetworkImage Error: $error');
          debugPrint('URL: $imageUrl');
        }
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.grey.shade400, size: 32),
              const SizedBox(height: 4),
              Text(
                'Не удалось загрузить',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}

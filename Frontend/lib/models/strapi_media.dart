import 'package:Arena/core/config.dart';

class StrapiMedia {
  final int id;
  final String url;
  final String? name;
  final String? mime;
  // size comes as a double from Strapi (e.g. 68.37 KB)
  final double? size;

  const StrapiMedia({
    required this.id,
    required this.url,
    this.name,
    this.mime,
    this.size,
  });

  factory StrapiMedia.fromJson(Map<String, dynamic> json) => StrapiMedia(
        id: json['id'] as int,
        url: json['url'] as String,
        name: json['name'] as String?,
        mime: json['mime'] as String?,
        size: json['size'] != null ? (json['size'] as num).toDouble() : null,
      );

  // Single place to update when switching between local / remote hosting.
  // Prepends the server origin when the path is relative.
  String get fullUrl => url.startsWith('http') ? url : '$kServerOrigin$url';
}

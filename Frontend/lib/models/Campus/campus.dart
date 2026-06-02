import 'package:Arena/models/strapi_media.dart';
import 'package:Arena/models/summaries.dart';

class Campus {
  final int id;
  final String name;
  final String? description;
  final String address;
  final int? nbTerrains;
  final double? lat;
  final double? long;
  final String? phone;
  final StrapiMedia? mainImage;
  final List<StrapiMedia> gallery;
  final ManagerSummary? manager;
  final List<TerrainSummary> terrains;
  final DateTime? publishedAt;

  const Campus({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    this.nbTerrains,
    this.lat,
    this.long,
    this.phone,
    this.mainImage,
    this.gallery = const [],
    this.manager,
    this.terrains = const [],
    this.publishedAt,
  });

  factory Campus.fromJson(Map<String, dynamic> json) => Campus(
        id: json['id'] as int,
        name: json['Name'] as String,
        description: json['Description'] as String?,
        address: json['Address'] as String,
        nbTerrains: json['NbTerrains'] as int?,
        // Lat/Long come as String from the API despite being float in the schema.
        lat: json['Lat'] != null ? double.tryParse(json['Lat'].toString()) : null,
        long: json['Long'] != null ? double.tryParse(json['Long'].toString()) : null,
        phone: json['phone'] as String?,
        mainImage: json['main_image'] != null
            ? StrapiMedia.fromJson(json['main_image'] as Map<String, dynamic>)
            : null,
        gallery: (json['gallery'] as List<dynamic>? ?? [])
            .map((e) => StrapiMedia.fromJson(e as Map<String, dynamic>))
            .toList(),
        manager: json['manager'] != null
            ? ManagerSummary.fromJson(json['manager'] as Map<String, dynamic>)
            : null,
        terrains: (json['terrains'] as List<dynamic>? ?? [])
            .map((e) => TerrainSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        publishedAt: json['publishedAt'] != null
            ? DateTime.parse(json['publishedAt'] as String)
            : null,
      );
}

class CampusRequest {
  final String name;
  final String? description;
  final String address;
  final String? phone;
  final int? nbTerrains;
  final int? mainImageId;
  final List<int> galleryIds;

  const CampusRequest({
    required this.name,
    this.description,
    required this.address,
    this.phone,
    this.nbTerrains,
    this.mainImageId,
    this.galleryIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        'address': address,
        if (phone != null) 'phone': phone,
        if (nbTerrains != null) 'nbTerrains': nbTerrains,
        if (mainImageId != null) 'mainImage': mainImageId,
        if (galleryIds.isNotEmpty) 'galleryImages': galleryIds,
      };
}

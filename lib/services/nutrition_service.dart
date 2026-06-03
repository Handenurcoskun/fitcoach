import 'dart:convert';
import 'package:http/http.dart' as http;

class FoodSearchResult {
  final String name;
  final String brand;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final String? imageUrl;

  const FoodSearchResult({
    required this.name,
    required this.brand,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.imageUrl,
  });

  String get displayName => brand.isNotEmpty ? '$name ($brand)' : name;
}

class NutritionService {
  static const _baseUrl = 'https://world.openfoodfacts.org/cgi/search.pl';
  static const _headers = {
    'User-Agent': 'FitCoach - Android - com.fitcoach.fitcoach',
  };

  Future<List<FoodSearchResult>> searchFood(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'search_terms': query.trim(),
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '20',
        'fields': 'product_name,brands,nutriments,image_front_thumb_url',
        'sort_by': 'unique_scans_n',
      });
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final products = (data['products'] as List?) ?? [];
      return products
          .map((p) => _parse(p as Map<String, dynamic>))
          .whereType<FoodSearchResult>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  FoodSearchResult? _parse(Map<String, dynamic> p) {
    try {
      final name = (p['product_name'] as String?)?.trim() ?? '';
      if (name.isEmpty) return null;

      final n = (p['nutriments'] as Map<String, dynamic>?) ?? {};

      double calories = 0;
      if (n.containsKey('energy-kcal_100g')) {
        calories = (n['energy-kcal_100g'] as num).toDouble();
      } else if (n.containsKey('energy_100g')) {
        calories = (n['energy_100g'] as num).toDouble() / 4.184;
      }
      if (calories <= 0) return null;

      return FoodSearchResult(
        name: name,
        brand: (p['brands'] as String?)?.split(',').first.trim() ?? '',
        caloriesPer100g: calories,
        proteinPer100g: (n['proteins_100g'] as num?)?.toDouble() ?? 0,
        carbsPer100g: (n['carbohydrates_100g'] as num?)?.toDouble() ?? 0,
        fatPer100g: (n['fat_100g'] as num?)?.toDouble() ?? 0,
        imageUrl: p['image_front_thumb_url'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

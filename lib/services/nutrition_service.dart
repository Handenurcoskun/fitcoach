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
  final bool isLocal;
  final double? servingGrams;
  final String? servingLabel;

  const FoodSearchResult({
    required this.name,
    required this.brand,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.imageUrl,
    this.isLocal = false,
    this.servingGrams,
    this.servingLabel,
  });

  String get displayName => brand.isNotEmpty ? '$name ($brand)' : name;
}

// Yerel Türkçe gıda veritabanı
// Her kayıt: (isim, kcal/100g, protein/100g, karb/100g, yağ/100g, porsiyon_gr, porsiyon_etiket, arama_anahtar_kelimeler)
const _localFoods = [
  // ===== YUMURTA =====
  _F('Yumurta (haşlanmış)', 155, 13.0, 1.1, 11.0, sg: 60, sl: '1 adet', kw: 'yumurta haşlanmış'),
  _F('Yumurta (sahanda)', 196, 13.6, 0.4, 15.3, sg: 60, sl: '1 adet', kw: 'yumurta sahanda kızarmış'),
  _F('Yumurta beyazı', 52, 10.9, 0.7, 0.2, sg: 33, sl: '1 adet', kw: 'yumurta beyaz ak'),
  _F('Yumurta sarısı', 322, 15.9, 3.6, 26.5, sg: 17, sl: '1 adet', kw: 'yumurta sarı'),
  // ===== ZEYTİN =====
  _F('Zeytin (siyah)', 115, 0.8, 6.3, 10.7, sg: 5, sl: '1 adet', kw: 'zeytin siyah'),
  _F('Zeytin (yeşil)', 145, 1.0, 3.8, 15.3, sg: 5, sl: '1 adet', kw: 'zeytin yeşil'),
  // ===== SEBZELER =====
  _F('Domates', 18, 0.9, 3.9, 0.2, sg: 120, sl: '1 adet (orta)', kw: 'domates taze'),
  _F('Salatalık', 16, 0.7, 3.6, 0.1, sg: 200, sl: '1 adet', kw: 'salatalık hıyar'),
  _F('Biber (yeşil)', 20, 0.9, 4.6, 0.2, sg: 80, sl: '1 adet', kw: 'biber yeşil sivri'),
  _F('Soğan', 40, 1.1, 9.3, 0.1, sg: 80, sl: '1 adet (orta)', kw: 'soğan kuru'),
  _F('Ispanak', 23, 2.9, 3.6, 0.4, kw: 'ıspanak ispanak'),
  _F('Marul', 15, 1.4, 2.9, 0.2, kw: 'marul yeşillik'),
  _F('Havuç', 41, 0.9, 9.6, 0.2, sg: 80, sl: '1 adet (orta)', kw: 'havuç'),
  _F('Patates (haşlanmış)', 87, 1.9, 20.1, 0.1, sg: 150, sl: '1 adet (orta)', kw: 'patates haşlanmış'),
  _F('Patates (kızartma)', 312, 3.4, 41.4, 15.0, kw: 'patates kızartma'),
  _F('Kabak', 17, 1.2, 3.1, 0.3, kw: 'kabak zucchini'),
  _F('Patlıcan', 25, 1.0, 5.9, 0.2, kw: 'patlıcan'),
  _F('Brokoli', 34, 2.8, 6.6, 0.4, kw: 'brokoli'),
  _F('Karnabahar', 25, 1.9, 5.0, 0.3, kw: 'karnabahar'),
  _F('Bezelye', 81, 5.4, 14.5, 0.4, kw: 'bezelye'),
  _F('Mısır', 86, 3.2, 19.0, 1.2, kw: 'mısır'),
  _F('Mantar', 22, 3.1, 3.3, 0.3, kw: 'mantar'),
  // ===== MEYVELER =====
  _F('Elma', 52, 0.3, 13.8, 0.2, sg: 150, sl: '1 adet (orta)', kw: 'elma'),
  _F('Muz', 89, 1.1, 22.8, 0.3, sg: 120, sl: '1 adet (orta)', kw: 'muz'),
  _F('Portakal', 47, 0.9, 11.8, 0.1, sg: 180, sl: '1 adet (orta)', kw: 'portakal'),
  _F('Üzüm', 69, 0.7, 18.1, 0.2, kw: 'üzüm'),
  _F('Çilek', 32, 0.7, 7.7, 0.3, kw: 'çilek'),
  _F('Karpuz', 30, 0.6, 7.6, 0.2, kw: 'karpuz'),
  _F('Kavun', 34, 0.8, 8.2, 0.2, kw: 'kavun'),
  _F('Armut', 57, 0.4, 15.2, 0.1, sg: 150, sl: '1 adet (orta)', kw: 'armut'),
  _F('Şeftali', 39, 0.9, 9.5, 0.3, sg: 150, sl: '1 adet', kw: 'şeftali'),
  // ===== ET VE TAVUK =====
  _F('Tavuk göğsü (haşlanmış)', 165, 31.0, 0.0, 3.6, kw: 'tavuk göğüs haşlanmış'),
  _F('Tavuk göğsü (ızgara)', 170, 30.5, 0.0, 4.5, kw: 'tavuk göğüs ızgara'),
  _F('Tavuk but (fırın)', 219, 22.0, 0.0, 14.0, kw: 'tavuk but fırın'),
  _F('Dana kıyma (yağlı)', 254, 17.2, 0.0, 20.0, kw: 'dana kıyma et'),
  _F('Dana kıyma (yağsız)', 215, 21.4, 0.0, 14.0, kw: 'dana kıyma yağsız'),
  _F('Dana biftek', 271, 26.1, 0.0, 18.0, kw: 'biftek dana et'),
  _F('Kuzu eti', 294, 24.5, 0.0, 21.0, kw: 'kuzu et'),
  _F('Hindi göğsü', 157, 29.9, 0.0, 3.3, kw: 'hindi göğüs'),
  // ===== ET YEMEKLERİ =====
  _F('Et sote', 180, 18.0, 5.0, 10.0, kw: 'et sote'),
  _F('Köfte (ızgara)', 220, 17.0, 8.0, 14.0, sg: 50, sl: '1 adet (orta)', kw: 'köfte ızgara'),
  _F('Köfte (haşlanmış)', 190, 16.5, 7.5, 11.5, sg: 50, sl: '1 adet', kw: 'köfte haşlanmış'),
  _F('Tavuk sote', 165, 20.0, 4.0, 8.0, kw: 'tavuk sote'),
  _F('Döner (tavuk)', 195, 18.0, 8.0, 10.0, kw: 'döner tavuk'),
  _F('Döner (et)', 225, 20.0, 8.0, 13.0, kw: 'döner et'),
  // ===== BALIKLAR =====
  _F('Somon', 208, 20.4, 0.0, 13.4, kw: 'somon balık'),
  _F('Levrek (fırın)', 97, 18.4, 0.0, 2.4, kw: 'levrek balık fırın'),
  _F('Çipura (ızgara)', 100, 18.5, 0.0, 2.8, kw: 'çipura balık'),
  _F('Ton balığı (konserve)', 128, 26.5, 0.0, 2.1, kw: 'ton balığı konserve'),
  _F('Hamsi', 131, 13.6, 0.0, 8.4, kw: 'hamsi balık'),
  // ===== SÜT VE SÜTLE ÜRÜNLER =====
  _F('Süt (tam yağlı)', 61, 3.2, 4.8, 3.3, sg: 200, sl: '1 su bardağı', kw: 'süt tam yağlı'),
  _F('Süt (yarım yağlı)', 46, 3.3, 4.8, 1.5, sg: 200, sl: '1 su bardağı', kw: 'süt yarım yağlı'),
  _F('Yoğurt (tam yağlı)', 61, 3.5, 4.7, 3.3, sg: 200, sl: '1 kase', kw: 'yoğurt tam yağlı'),
  _F('Yoğurt (light)', 36, 4.0, 5.0, 0.1, sg: 200, sl: '1 kase', kw: 'yoğurt light az yağlı'),
  _F('Ayran', 36, 1.8, 2.8, 1.8, sg: 250, sl: '1 bardak', kw: 'ayran'),
  _F('Peynir (beyaz)', 264, 17.5, 1.2, 21.0, sg: 30, sl: '1 dilim', kw: 'peynir beyaz'),
  _F('Kaşar peyniri', 375, 26.0, 1.3, 30.0, sg: 20, sl: '1 dilim ince', kw: 'kaşar peynir'),
  _F('Lor peyniri', 98, 12.4, 3.4, 4.2, kw: 'lor peynir'),
  _F('Kefir', 53, 3.7, 5.0, 1.6, sg: 200, sl: '1 bardak', kw: 'kefir'),
  // ===== EKMEK VE TAHILLAR =====
  _F('Ekmek (tam buğday)', 247, 9.7, 48.3, 3.4, sg: 30, sl: '1 dilim', kw: 'ekmek tam buğday'),
  _F('Ekmek (beyaz)', 265, 9.0, 53.4, 1.6, sg: 30, sl: '1 dilim', kw: 'ekmek beyaz'),
  _F('Bulgur (pişmiş)', 83, 3.1, 18.6, 0.2, kw: 'bulgur'),
  _F('Pirinç (pişmiş)', 130, 2.7, 28.7, 0.3, kw: 'pirinç pilav'),
  _F('Makarna (pişmiş)', 158, 5.8, 30.9, 0.9, kw: 'makarna'),
  _F('Yulaf ezmesi', 389, 16.9, 66.3, 6.9, sg: 40, sl: '1 porsiyon', kw: 'yulaf ezmesi'),
  _F('Müsli', 368, 9.5, 66.3, 7.4, sg: 50, sl: '1 porsiyon', kw: 'müsli granola'),
  // ===== BAKLAGİLLER =====
  _F('Mercimek çorbası', 60, 3.5, 9.0, 1.2, sg: 250, sl: '1 kase', kw: 'mercimek çorbası'),
  _F('Mercimek (haşlanmış)', 116, 9.0, 20.1, 0.4, kw: 'mercimek'),
  _F('Nohut (haşlanmış)', 164, 8.9, 27.4, 2.6, kw: 'nohut'),
  _F('Fasulye (haşlanmış)', 127, 8.7, 22.8, 0.5, kw: 'fasulye kuru'),
  _F('Kuru fasulye yemeği', 130, 7.0, 20.0, 2.5, sg: 250, sl: '1 porsiyon', kw: 'kuru fasulye yemek'),
  // ===== TÜRK YEMEKLERİ =====
  _F('Dolma (zeytinyağlı)', 150, 3.5, 24.0, 5.0, sg: 40, sl: '1 adet', kw: 'dolma zeytinyağlı yaprak'),
  _F('Dolma (etli)', 95, 5.0, 10.0, 4.0, sg: 40, sl: '1 adet', kw: 'dolma etli biber'),
  _F('İmam bayıldı', 90, 1.5, 8.0, 6.0, kw: 'imam bayıldı patlıcan'),
  _F('Menemen', 120, 6.5, 5.0, 8.5, sg: 200, sl: '1 porsiyon', kw: 'menemen'),
  _F('Çorba (sebze)', 45, 1.5, 7.5, 1.0, sg: 250, sl: '1 kase', kw: 'çorba sebze'),
  _F('Çorba (tavuk)', 55, 5.0, 5.0, 1.5, sg: 250, sl: '1 kase', kw: 'çorba tavuk'),
  _F('Çorba (ezogelin)', 70, 3.5, 11.5, 1.2, sg: 250, sl: '1 kase', kw: 'ezogelin çorba'),
  _F('Cacık', 35, 1.8, 2.8, 1.8, sg: 150, sl: '1 kase', kw: 'cacık'),
  _F('Pilav (pirinç)', 130, 2.4, 27.0, 1.8, sg: 150, sl: '1 porsiyon', kw: 'pilav pirinç'),
  _F('Pilav (bulgur)', 90, 3.2, 17.5, 1.0, sg: 150, sl: '1 porsiyon', kw: 'pilav bulgur'),
  // ===== KAHVALTI =====
  _F('Bal', 304, 0.3, 82.4, 0.0, sg: 20, sl: '1 çorba kaşığı', kw: 'bal'),
  _F('Tereyağı', 717, 0.9, 0.1, 81.1, sg: 10, sl: '1 çay kaşığı', kw: 'tereyağı'),
  _F('Zeytinyağı', 884, 0.0, 0.0, 100.0, sg: 10, sl: '1 çorba kaşığı', kw: 'zeytinyağı'),
  _F('Tahin', 595, 17.0, 21.2, 53.8, sg: 15, sl: '1 çorba kaşığı', kw: 'tahin'),
  _F('Pekmez', 300, 0.8, 78.0, 0.2, sg: 20, sl: '1 çorba kaşığı', kw: 'pekmez'),
  // ===== KURUYEMIŞLER =====
  _F('Ceviz', 654, 15.2, 13.7, 65.2, sg: 30, sl: '1 avuç (~4 adet)', kw: 'ceviz'),
  _F('Badem', 579, 21.2, 21.6, 49.9, sg: 20, sl: '1 avuç (~15 adet)', kw: 'badem'),
  _F('Fındık', 628, 15.0, 16.7, 60.8, sg: 20, sl: '1 avuç', kw: 'fındık'),
  _F('Kaju', 553, 18.2, 30.2, 43.9, sg: 20, sl: '1 avuç', kw: 'kaju'),
  // ===== TATLILAR =====
  _F('Baklava', 417, 7.7, 40.0, 29.0, sg: 60, sl: '1 dilim', kw: 'baklava'),
  _F('Sütlaç', 124, 3.5, 23.0, 2.2, sg: 150, sl: '1 porsiyon', kw: 'sütlaç'),
];

class _F {
  final String name;
  final double kcal;
  final double p;
  final double c;
  final double f;
  final double? sg;
  final String? sl;
  final String kw;
  const _F(this.name, this.kcal, this.p, this.c, this.f,
      {this.sg, this.sl, required this.kw});
}

class NutritionService {
  static const _baseUrl = 'https://world.openfoodfacts.org/cgi/search.pl';
  static const _headers = {
    'User-Agent': 'FitCoach - Android - com.fitcoach.fitcoach',
  };

  List<FoodSearchResult> searchLocalFood(String query) {
    if (query.trim().isEmpty) return [];
    final q = _normalize(query.trim());
    final scored = <(int, _F)>[];
    for (final f in _localFoods) {
      final nameLower = _normalize(f.name);
      final kwLower = _normalize(f.kw);
      int score = 0;
      if (nameLower.startsWith(q)) {
        score = 100;
      } else if (nameLower.contains(q)) {
        score = 80;
      } else {
        for (final word in q.split(' ')) {
          if (word.length < 2) continue;
          if (nameLower.contains(word)) score += 40;
          if (kwLower.contains(word)) score += 20;
        }
      }
      if (score > 0) scored.add((score, f));
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return scored
        .take(10)
        .map((e) => FoodSearchResult(
              name: e.$2.name,
              brand: '',
              caloriesPer100g: e.$2.kcal,
              proteinPer100g: e.$2.p,
              carbsPer100g: e.$2.c,
              fatPer100g: e.$2.f,
              isLocal: true,
              servingGrams: e.$2.sg,
              servingLabel: e.$2.sl,
            ))
        .toList();
  }

  String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u');
  }

  Future<List<FoodSearchResult>> searchFood(String query) async {
    if (query.trim().isEmpty) return [];

    // Önce yerel veritabanında ara
    final localResults = searchLocalFood(query);

    // API'yi de paralel çalıştır
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'search_terms': query.trim(),
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '15',
        'fields': 'product_name,brands,nutriments,image_front_thumb_url',
        'sort_by': 'unique_scans_n',
        'lc': 'tr',
        'countries_tags': 'en:turkey',
      });
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final products = (data['products'] as List?) ?? [];
        final apiResults = products
            .map((p) => _parse(p as Map<String, dynamic>))
            .whereType<FoodSearchResult>()
            .toList();

        // Yerel sonuçlar önce, API sonuçları arkada (duplicate isim varsa atla)
        final localNames =
            localResults.map((r) => _normalize(r.name)).toSet();
        final filteredApi = apiResults
            .where((r) => !localNames.contains(_normalize(r.name)))
            .toList();
        return [...localResults, ...filteredApi];
      }
    } catch (_) {}

    return localResults;
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

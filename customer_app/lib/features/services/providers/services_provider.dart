import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/features/services/models/service_models.dart';

final staticCategoriesProvider = Provider<List<ServiceCategory>>((ref) {
  return staticCategories;
});

final staticServicesProvider = Provider<List<MarketplaceService>>((ref) {
  return staticServices;
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredServicesProvider = Provider<List<MarketplaceService>>((ref) {
  final services = ref.watch(staticServicesProvider);
  final category = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return services.where((service) {
    final matchesCategory = category == null || service.categoryId == category;
    final matchesQuery = service.title.toLowerCase().contains(query) ||
        service.description.toLowerCase().contains(query) ||
        service.tagline.toLowerCase().contains(query);
    return matchesCategory && matchesQuery;
  }).toList();
});

final serviceByIdProvider = Provider.family<MarketplaceService?, String>((ref, id) {
  final services = ref.watch(staticServicesProvider);
  try {
    final parsedId = int.parse(id);
    return services.firstWhere((s) => s.id == parsedId);
  } catch (_) {
    // If not int, search by slug
    return services.firstWhere((s) => s.slug == id);
  }
});

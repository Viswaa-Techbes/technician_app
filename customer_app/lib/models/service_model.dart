class ServiceCategory {
  final String id;
  final String title;
  final String description;
  final String servicesLabel;
  final String gradient;

  ServiceCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.servicesLabel,
    required this.gradient,
  });
}

class FaqItem {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});
}

class Review {
  final int id;
  final String user;
  final String role;
  final double rating;
  final String comment;
  final String date;

  Review({
    required this.id,
    required this.user,
    required this.role,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class MarketplaceService {
  final int id;
  final String slug;
  final String title;
  final String categoryId;
  final String category;
  final String tagline;
  final String description;
  final String price;
  final double priceValue;
  final double rating;
  final int reviewCount;
  final String duration;
  final int durationMinutes;
  final String image;
  final List<String> gallery;
  final String? badge;
  final List<String> features;
  final List<String> includes;
  final List<String> steps;
  final List<FaqItem> faqs;
  final List<Review> reviews;
  final List<String> recommendedFor;
  final List<String> timeSlots;
  final String? configurableType;
  final String? overview;

  MarketplaceService({
    required this.id,
    required this.slug,
    required this.title,
    required this.categoryId,
    required this.category,
    required this.tagline,
    required this.description,
    required this.price,
    required this.priceValue,
    required this.rating,
    required this.reviewCount,
    required this.duration,
    required this.durationMinutes,
    required this.image,
    required this.gallery,
    this.badge,
    required this.features,
    required this.includes,
    required this.steps,
    required this.faqs,
    required this.reviews,
    required this.recommendedFor,
    required this.timeSlots,
    this.configurableType,
    this.overview,
  });
}

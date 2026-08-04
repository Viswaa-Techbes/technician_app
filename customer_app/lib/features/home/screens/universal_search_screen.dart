import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../repositories/service_repository.dart';

class UniversalSearchScreen extends ConsumerStatefulWidget {
  const UniversalSearchScreen({super.key});

  @override
  ConsumerState<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends ConsumerState<UniversalSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  // Mock index for products, brands, articles, FAQs
  final List<Map<String, dynamic>> _faqs = [
    {'q': 'What is the warranty on CCTV installation?', 'a': 'We offer a standard 30-day service warranty on installation. Hardware replacement carries respective brand warranties.', 'cat': 'FAQ'},
    {'q': 'Difference between DVR and NVR?', 'a': 'DVR systems process analog camera data at the recorder, while NVR systems encrypt and process video data at each camera before sending to the recorder.', 'cat': 'FAQ'},
    {'q': 'How do I schedule an AMC maintenance check?', 'a': 'You can book directly from your Active AMC card on the dashboard or by contacting support.', 'cat': 'FAQ'},
  ];

  final List<Map<String, dynamic>> _articles = [
    {'title': 'Top 5 Security System Best Practices in 2026', 'excerpt': 'A comprehensive guide to protecting your smart home network and optimizing camera placement.', 'cat': 'Articles'},
    {'title': 'Understanding PoE (Power over Ethernet) Networking', 'excerpt': 'Learn how PoE reduces cabling requirements for corporate IP camera and switch networks.', 'cat': 'Articles'},
  ];

  final List<Map<String, dynamic>> _products = [
    {'name': 'Hikvision Dome 4MP IP Camera', 'desc': 'High quality outdoor night vision surveillance.', 'cat': 'Products', 'price': '₹2,499'},
    {'name': 'CP Plus Bullet 4MP Analog Camera', 'desc': 'Perfect for entryways and driveway alignment monitoring.', 'cat': 'Products', 'price': '₹1,999'},
    {'name': 'TP-Link TL-SG1008P PoE Switch', 'desc': 'Gigabit Desktop Switch with 4-Port PoE support.', 'cat': 'Products', 'price': '₹4,299'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter matching objects
    final q = _query.toLowerCase().trim();

    final filteredServices = q.isEmpty
        ? []
        : ServiceRepository.services.where((s) {
            return s.title.toLowerCase().contains(q) ||
                s.description.toLowerCase().contains(q) ||
                s.category.toLowerCase().contains(q);
          }).toList();

    final filteredProducts = q.isEmpty
        ? []
        : _products.where((p) {
            return p['name'].toLowerCase().contains(q) || p['desc'].toLowerCase().contains(q);
          }).toList();

    final filteredFaqs = q.isEmpty
        ? []
        : _faqs.where((f) {
            return f['q'].toLowerCase().contains(q) || f['a'].toLowerCase().contains(q);
          }).toList();

    final filteredArticles = q.isEmpty
        ? []
        : _articles.where((a) {
            return a['title'].toLowerCase().contains(q) || a['excerpt'].toLowerCase().contains(q);
          }).toList();

    final totalResults = filteredServices.length + filteredProducts.length + filteredFaqs.length + filteredArticles.length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (val) => setState(() => _query = val),
              decoration: InputDecoration(
                hintText: 'Search services, products, FAQs, articles...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondaryColor, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: q.isEmpty
          ? _buildPopularSuggestions()
          : totalResults == 0
              ? _buildNoResultsState()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Found $totalResults results for "$_query"',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
                    ),
                    const SizedBox(height: 16),

                    // Services Group
                    if (filteredServices.isNotEmpty) ...[
                      _buildHeaderGroup('Services & Bookings'),
                      ...filteredServices.map((s) => _buildServiceResultTile(s)),
                      const SizedBox(height: 16),
                    ],

                    // Products Group
                    if (filteredProducts.isNotEmpty) ...[
                      _buildHeaderGroup('Products & Accessories'),
                      ...filteredProducts.map((p) => _buildProductResultTile(p)),
                      const SizedBox(height: 16),
                    ],

                    // FAQs Group
                    if (filteredFaqs.isNotEmpty) ...[
                      _buildHeaderGroup('Frequently Asked Questions'),
                      ...filteredFaqs.map((f) => _buildFaqResultTile(f)),
                      const SizedBox(height: 16),
                    ],

                    // Articles Group
                    if (filteredArticles.isNotEmpty) ...[
                      _buildHeaderGroup('Knowledge Hub & Blogs'),
                      ...filteredArticles.map((a) => _buildArticleResultTile(a)),
                    ],
                  ],
                ),
    );
  }

  Widget _buildPopularSuggestions() {
    final tags = ['CCTV Installation', 'Router Setup', 'AMC Plans', 'NVR vs DVR', 'Hikvision', 'Support'];
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POPULAR SEARCHES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: tags.map((t) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = t;
                  setState(() => _query = t);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    t,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderGroup(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.primaryColor, letterSpacing: 0.5)),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: AppTheme.borderColor)),
        ],
      ),
    );
  }

  Widget _buildServiceResultTile(dynamic s) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.videocam, color: AppTheme.primaryColor, size: 22),
        ),
        title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        subtitle: Text(s.tagline, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () {
          context.push('/services/${s.slug}');
        },
      ),
    );
  }

  Widget _buildProductResultTile(dynamic p) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.secondaryColor.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.shopping_bag, color: AppTheme.secondaryColor, size: 22),
        ),
        title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        subtitle: Text(p['desc'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)),
        trailing: Text(p['price'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.primaryColor)),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product: ${p['name']} added to selection!')));
        },
      ),
    );
  }

  Widget _buildFaqResultTile(dynamic f) {
    return ExpansionTile(
      title: Text(f['q'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimaryColor)),
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(f['a'], style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, height: 1.4)),
      ],
    );
  }

  Widget _buildArticleResultTile(dynamic a) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        title: Text(a['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimaryColor)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(a['excerpt'], style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryColor, height: 1.35)),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loading article: ${a['title']}')));
        },
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 54, color: Colors.blueGrey.shade200),
            const SizedBox(height: 16),
            const Text(
              'No matches found',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try adjusting your search keywords or explore categories on the dashboard.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

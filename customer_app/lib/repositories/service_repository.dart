import '../models/service_model.dart';

class ServiceRepository {
  static final List<ServiceCategory> categories = [
    ServiceCategory(
      id: "cctv",
      title: "CCTV",
      description: "Smart surveillance, remote monitoring, and office security.",
      servicesLabel: "20 services",
      gradient: "from-cyan-500 via-sky-500 to-blue-600",
    ),
    ServiceCategory(
      id: "networking",
      title: "Networking",
      description: "Wi-Fi, structured cabling, routers, and enterprise rollout.",
      servicesLabel: "Coming Soon",
      gradient: "from-emerald-500 via-teal-500 to-cyan-600",
    ),
    ServiceCategory(
      id: "laptop",
      title: "Laptop",
      description: "Laptop repair, parts upgrade, and software support.",
      servicesLabel: "Coming Soon",
      gradient: "from-blue-600 via-indigo-600 to-purple-600",
    ),
    ServiceCategory(
      id: "desktop",
      title: "Desktop",
      description: "Desktop repairs, diagnosis, and hardware builds.",
      servicesLabel: "Coming Soon",
      gradient: "from-purple-500 via-indigo-500 to-blue-600",
    ),
    ServiceCategory(
      id: "server",
      title: "Server",
      description: "Server hardware setup, administration, and support.",
      servicesLabel: "Coming Soon",
      gradient: "from-slate-700 via-blue-700 to-cyan-600",
    ),
    ServiceCategory(
      id: "electronic-contracts",
      title: "Electronic Contracts",
      description: "E-contracts and digital agreements automation.",
      servicesLabel: "Coming Soon",
      gradient: "from-teal-500 via-emerald-500 to-lime-500",
    ),
    ServiceCategory(
      id: "home-automation",
      title: "Home Automation",
      description: "Smart home hubs, locks, and automatic controls.",
      servicesLabel: "Coming Soon",
      gradient: "from-orange-500 via-amber-500 to-rose-500",
    ),
    ServiceCategory(
      id: "website-development",
      title: "Website Development",
      description: "Custom web development and hosting.",
      servicesLabel: "Coming Soon",
      gradient: "from-rose-500 via-pink-500 to-red-600",
    ),
    ServiceCategory(
      id: "software-licensing",
      title: "Software Licensing",
      description: "Enterprise software licensing and audits.",
      servicesLabel: "Coming Soon",
      gradient: "from-teal-500 via-emerald-500 to-green-600",
    ),
    ServiceCategory(
      id: "cyber-security",
      title: "Cyber Security",
      description: "Firewalls, audits, endpoint security, and threat hardening.",
      servicesLabel: "Coming Soon",
      gradient: "from-red-500 via-orange-500 to-amber-600",
    ),
  ];

  static final List<FaqItem> defaultFaqs = [
    FaqItem(
      question: "Are technicians verified before assignment?",
      answer: "Yes. Every partner goes through KYC verification, technical screening, and service quality checks before going live.",
    ),
    FaqItem(
      question: "Can I reschedule after booking?",
      answer: "You can reschedule from the booking flow or dashboard up to 2 hours before the slot, subject to availability.",
    ),
    FaqItem(
      question: "Do you provide post-service support?",
      answer: "All services include post-service support windows, and selected services include an extended workmanship warranty.",
    ),
  ];

  static final List<Review> cctvReviews = [
    Review(
      id: 1,
      user: "Rahul S.",
      role: "Office Admin",
      rating: 5,
      comment: "CCTV Installation was handled smoothly. The technician arrived on time, explained each step clearly, and cleaned up after the job.",
      date: "12 Mar 2026",
    ),
    Review(
      id: 2,
      user: "Aisha K.",
      role: "Store Owner",
      rating: 5,
      comment: "Fast booking, transparent pricing, and no surprises during installation. I would book again for our next branch.",
      date: "02 Mar 2026",
    ),
  ];

  static final List<MarketplaceService> services = [
    MarketplaceService(
      id: 1000,
      slug: "cctv-installation",
      title: "CCTV Installation",
      categoryId: "cctv",
      category: "CCTV Installation",
      tagline: "Configurable CCTV service with step-by-step booking and material selection.",
      description: "CCTV Installation includes site review, camera placement, installation, cabling, recorder setup, and handover testing. Configure camera type, materials, and schedule in the booking flow.",
      price: "From Rs. 499",
      priceValue: 499,
      rating: 4.8,
      reviewCount: 2400,
      duration: "2-6 hrs",
      durationMinutes: 360,
      image: "https://images.unsplash.com/photo-1505691723518-36a9a0b5f6b5?w=1200&h=900&fit=crop",
      gallery: [
        "https://images.unsplash.com/photo-1505691723518-36a9a0b5f6b5?w=1200&h=900&fit=crop",
      ],
      badge: "Configurable",
      features: [
        "Single unified booking flow for all CCTV types",
        "Material selection with per-meter pricing",
        "Live price calculation",
        "Add to cart or continue to checkout",
      ],
      includes: [
        "Site inspection and placement guidance",
        "Camera mounting and alignment",
        "Basic DVR/NVR or mobile viewing setup",
        "Workmanship warranty",
      ],
      steps: [
        "Select service type and camera model",
        "Choose required materials and quantities",
        "Provide location",
        "Pick preferred date and time",
        "Add any special notes",
      ],
      faqs: defaultFaqs,
      reviews: cctvReviews,
      recommendedFor: ["Homes", "Offices", "Retail shops"],
      timeSlots: ["09:00", "11:30", "14:00", "16:30"],
      configurableType: "cctv",
      overview: "Unified CCTV Installation service. Use the booking flow to pick the service type, required materials, location, schedule, and add notes. All pricing is computed live.",
    ),
    MarketplaceService(
      id: 2,
      slug: "office-network-deployment",
      title: "Office Network Deployment",
      categoryId: "network",
      category: "Network Setup",
      tagline: "Secure LAN, Wi-Fi planning, switching, and structured cabling.",
      description: "A full network deployment for growing teams with router configuration, switch setup, Wi-Fi planning, VLAN design, and performance checks for stable office connectivity.",
      price: "From Rs. 5,499",
      priceValue: 5499,
      rating: 4.8,
      reviewCount: 1820,
      duration: "4-6 hrs",
      durationMinutes: 360,
      image: "https://images.unsplash.com/photo-1544197150-b99a580bb7a8?w=1200&h=900&fit=crop",
      gallery: [],
      features: [
        "Structured cabling audit and deployment plan",
        "Router, firewall, and switch configuration",
        "Access point placement and guest Wi-Fi setup",
      ],
      includes: [
        "Coverage assessment",
        "Basic network documentation",
      ],
      steps: [
        "Choose your office size and preferred service date.",
        "Technician audits the current setup and scope.",
      ],
      faqs: defaultFaqs,
      reviews: [],
      recommendedFor: ["Offices", "Coworking spaces"],
      timeSlots: ["10:00 AM", "01:30 PM", "04:00 PM"],
    ),
    MarketplaceService(
      id: 3,
      slug: "managed-firewall-setup",
      title: "Managed Firewall Setup",
      categoryId: "security",
      category: "Cyber Security",
      tagline: "Threat prevention, access rules, VPN, and policy hardening.",
      description: "Protect your business network with a professionally configured firewall, segmented access policies, VPN setup, and baseline security hardening.",
      price: "From Rs. 12,999",
      priceValue: 12999,
      rating: 4.9,
      reviewCount: 894,
      duration: "3-5 hrs",
      durationMinutes: 300,
      image: "https://images.unsplash.com/photo-1563986768609-322da13575f3?w=1200&h=900&fit=crop",
      gallery: [],
      features: [
        "Access control rules and segmentation",
        "VPN and secure remote access setup",
      ],
      includes: [
        "Security checklist review",
      ],
      steps: [
        "Tell us your network size and current firewall brand.",
      ],
      faqs: defaultFaqs,
      reviews: [],
      recommendedFor: ["SMBs"],
      timeSlots: ["09:00 AM", "02:00 PM"],
    ),
    MarketplaceService(
      id: 5,
      slug: "business-amc-plan",
      title: "Business AMC Plan",
      categoryId: "amc",
      category: "AMC Plans",
      tagline: "Annual preventive maintenance with priority IT support.",
      description: "Keep your business IT healthy year-round with preventive visits, device audits, remote support, and incident response coverage designed for small and mid-sized teams.",
      price: "From Rs. 18,999 / year",
      priceValue: 18999,
      rating: 4.8,
      reviewCount: 3210,
      duration: "Yearly plan",
      durationMinutes: 0,
      image: "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=1200&h=900&fit=crop",
      gallery: [],
      features: [
        "Quarterly preventive maintenance visits",
        "Unlimited remote support tickets",
      ],
      includes: [
        "Monthly health report",
      ],
      steps: [
        "Tell us how many devices and sites you manage.",
      ],
      faqs: defaultFaqs,
      reviews: [],
      recommendedFor: ["SMBs", "Schools"],
      timeSlots: ["10:00 AM", "03:00 PM"],
    ),
    MarketplaceService(
      id: 6,
      slug: "laptop-desktop-repair",
      title: "Laptop & Desktop Repair",
      categoryId: "hardware",
      category: "Hardware Repair",
      tagline: "Diagnosis, part replacement, OS fixes, and tune-ups.",
      description: "On-site repair and maintenance for workstations, laptops, printers, and office devices with clear diagnosis, service estimates, and performance optimization.",
      price: "From Rs. 499",
      priceValue: 499,
      rating: 4.6,
      reviewCount: 4510,
      duration: "1-3 hrs",
      durationMinutes: 180,
      image: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=1200&h=900&fit=crop",
      gallery: [],
      features: [
        "Issue diagnosis and resolution guidance",
        "SSD upgrades and cleanup",
      ],
      includes: [
        "Basic troubleshooting",
      ],
      steps: [
        "Describe the issue and choose your visit slot.",
      ],
      faqs: defaultFaqs,
      reviews: [],
      recommendedFor: ["Remote workers", "Offices"],
      timeSlots: ["09:00 AM", "12:00 PM", "03:00 PM"],
    ),
    MarketplaceService(
      id: 7,
      slug: "rupee-one-test-service",
      title: "₹1 Payment Test Service",
      categoryId: "cctv",
      category: "CCTV Installation",
      tagline: "Test Razorpay integration with exactly ₹1 advance payment.",
      description: "This is a dummy service designed to test the end-to-end booking and Razorpay payment flow. The total price is ₹2, which results in a 50% advance payment of exactly ₹1.",
      price: "Rs. 2 (₹1 Advance)",
      priceValue: 2,
      rating: 5.0,
      reviewCount: 1,
      duration: "10 mins",
      durationMinutes: 10,
      image: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=1200&h=900&fit=crop",
      gallery: [],
      features: [
        "End-to-end integration test",
        "Razorpay payment of exactly ₹1",
      ],
      includes: [
        "Full test flow verification",
      ],
      steps: [
        "Select this service.",
        "Proceed to book.",
      ],
      faqs: defaultFaqs,
      reviews: [],
      recommendedFor: ["Developers"],
      timeSlots: ["09:00 AM", "12:00 PM", "03:00 PM"],
    ),
  ];

  static MarketplaceService? getServiceBySlug(String slug) {
    try {
      return services.firstWhere((s) => s.slug == slug);
    } catch (_) {
      return null;
    }
  }

  static List<MarketplaceService> getServicesByCategory(String categoryId) {
    return services.where((s) => s.categoryId == categoryId).toList();
  }
}

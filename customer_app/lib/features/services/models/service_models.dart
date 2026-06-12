class Review {
  final int id;
  final String user;
  final double rating;
  final String comment;
  final String role;
  final String date;

  const Review({
    required this.id,
    required this.user,
    required this.rating,
    required this.comment,
    required this.role,
    required this.date,
  });
}

class FaqItem {
  final String question;
  final String answer;

  const FaqItem({
    required this.question,
    required this.answer,
  });
}

class ServiceCategory {
  final String id;
  final String title;
  final String description;
  final String servicesLabel;
  final String gradient;

  const ServiceCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.servicesLabel,
    required this.gradient,
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
  final List<String>? excludedServices;
  final List<String>? supportedProducts;
  final List<String>? supportedAddons;
  final List<String>? supportedSpareParts;

  const MarketplaceService({
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
    this.excludedServices,
    this.supportedProducts,
    this.supportedAddons,
    this.supportedSpareParts,
  });
}

final List<ServiceCategory> staticCategories = [
  const ServiceCategory(
    id: "cctv",
    title: "CCTV Installation",
    description: "Smart surveillance, remote monitoring, and office security.",
    servicesLabel: "1 service",
    gradient: "from-cyan-500 via-sky-500 to-blue-600",
  ),
  const ServiceCategory(
    id: "network",
    title: "Network Setup",
    description: "Wi-Fi, structured cabling, routers, and enterprise rollout.",
    servicesLabel: "1 service",
    gradient: "from-emerald-500 via-teal-500 to-cyan-600",
  ),
  const ServiceCategory(
    id: "security",
    title: "Cyber Security",
    description: "Firewalls, audits, endpoint security, and threat hardening.",
    servicesLabel: "1 service",
    gradient: "from-slate-700 via-blue-700 to-cyan-600",
  ),
  const ServiceCategory(
    id: "hardware",
    title: "Hardware Repair",
    description: "Laptop, desktop, printer, and workplace device support.",
    servicesLabel: "2 services",
    gradient: "from-teal-500 via-emerald-500 to-lime-500",
  ),
  const ServiceCategory(
    id: "amc",
    title: "AMC Plans",
    description: "Preventive maintenance contracts for teams and branches.",
    servicesLabel: "1 plan",
    gradient: "from-emerald-500 via-green-500 to-teal-600",
  ),
];

final List<FaqItem> defaultFaqs = [
  const FaqItem(
    question: "Are technicians verified before assignment?",
    answer: "Yes. Every partner goes through KYC verification, technical screening, and service quality checks before going live.",
  ),
  const FaqItem(
    question: "Can I reschedule after booking?",
    answer: "You can reschedule from the booking flow or dashboard up to 2 hours before the slot, subject to availability.",
  ),
  const FaqItem(
    question: "Do you provide post-service support?",
    answer: "All services include post-service support windows, and selected services include an extended workmanship warranty.",
  ),
];

List<Review> getStaticReviews(String serviceName) {
  return [
    Review(
      id: 1,
      user: "Rahul S.",
      role: "Office Admin",
      rating: 5,
      comment: "$serviceName was handled smoothly. The technician arrived on time, explained each step clearly, and cleaned up after the job.",
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
    Review(
      id: 3,
      user: "Vikram P.",
      role: "Facility Manager",
      rating: 4.5,
      comment: "Good technician and excellent communication from the operations team. The service summary was especially helpful.",
      date: "24 Feb 2026",
    ),
  ];
}

final List<MarketplaceService> staticServices = [
  MarketplaceService(
    id: 1000,
    slug: "cctv-installation",
    title: "CCTV Installation",
    categoryId: "cctv",
    category: "CCTV Installation",
    tagline: "Configurable CCTV service with step-by-step booking and material selection.",
    description: "CCTV Installation includes site review, camera placement, installation, cabling, recorder setup, and handover testing. Configure camera type, materials, and schedule in the booking flow.",
    price: "From ₹499",
    priceValue: 499.0,
    rating: 4.8,
    reviewCount: 2400,
    duration: "2-6 hrs",
    durationMinutes: 360,
    image: "https://images.unsplash.com/photo-1505691723518-36a9a0b5f6b5?w=1200&h=900&fit=crop",
    gallery: [
      "https://images.unsplash.com/photo-1505691723518-36a9a0b5f6b5?w=1200&h=900&fit=crop",
      "https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?w=1200&h=900&fit=crop",
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
    overview: "Unified CCTV Installation service. Use the booking flow to pick the service type, required materials, location, schedule, and add notes. All pricing is computed live.",
    excludedServices: ["Third-party device warranty", "Structural modifications"],
    supportedProducts: ["Dome Camera", "Bullet Camera", "PTZ Camera", "DVR", "NVR", "Hard Disk", "SMPS"],
    supportedAddons: ["Connector Set", "PVC Casing", "Junction Box", "PoE Switch"],
    supportedSpareParts: ["Connector Kit", "Power Adapter", "SMPS", "Hard Disk"],
    steps: [
      "Select service type and camera model",
      "Choose required materials and quantities",
      "Provide location",
      "Pick preferred date and time",
      "Add any special notes",
    ],
    faqs: defaultFaqs,
    reviews: getStaticReviews("CCTV Installation"),
    recommendedFor: ["Homes", "Offices", "Retail shops", "Apartments", "Warehouses"],
    timeSlots: ["09:00", "11:30", "14:00", "16:30"],
    configurableType: "cctv",
  ),
  MarketplaceService(
    id: 2,
    slug: "office-network-deployment",
    title: "Office Network Deployment",
    categoryId: "network",
    category: "Network Setup",
    tagline: "Secure LAN, Wi-Fi planning, switching, and structured cabling.",
    description: "A full network deployment for growing teams with router configuration, switch setup, Wi-Fi planning, VLAN design, and performance checks for stable office connectivity.",
    price: "From ₹5,499",
    priceValue: 5499.0,
    rating: 4.8,
    reviewCount: 1820,
    duration: "4-6 hrs",
    durationMinutes: 360,
    image: "https://images.unsplash.com/photo-1544197150-b99a580bb7a8?w=1200&h=900&fit=crop",
    gallery: [
      "https://images.unsplash.com/photo-1544197150-b99a580bb7a8?w=1200&h=900&fit=crop",
      "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=1200&h=900&fit=crop",
    ],
    badge: "Business Favorite",
    features: [
      "Structured cabling audit and deployment plan",
      "Router, firewall, and switch configuration",
      "Access point placement and guest Wi-Fi setup",
      "Speed and stability validation after install",
    ],
    includes: [
      "Coverage assessment",
      "Basic network documentation",
      "Secure password handover",
      "14-day support window",
    ],
    steps: [
      "Choose your office size and preferred service date.",
      "Technician audits the current setup and scope.",
      "Network hardware and cabling are configured on-site.",
      "Team receives credentials and connection walkthrough.",
    ],
    faqs: defaultFaqs,
    reviews: getStaticReviews("Office Network Deployment"),
    recommendedFor: ["Coworking spaces", "Studios", "Branch offices"],
    timeSlots: ["10:00", "12:30", "15:00", "17:00"],
  ),
  MarketplaceService(
    id: 3,
    slug: "managed-firewall-setup",
    title: "Managed Firewall Setup",
    categoryId: "security",
    category: "Cyber Security",
    tagline: "Threat prevention, access rules, VPN, and policy hardening.",
    description: "Protect your business network with a professionally configured firewall, segmented access policies, VPN setup, and baseline security hardening.",
    price: "From ₹12,999",
    priceValue: 12999.0,
    rating: 4.9,
    reviewCount: 894,
    duration: "3-5 hrs",
    durationMinutes: 300,
    image: "https://images.unsplash.com/photo-1563986768609-322da13575f3?w=1200&h=900&fit=crop",
    gallery: [
      "https://images.unsplash.com/photo-1563986768609-322da13575f3?w=1200&h=900&fit=crop",
      "https://images.unsplash.com/photo-1516321497487-e288fb19713f?w=1200&h=900&fit=crop",
    ],
    badge: "Top Rated",
    features: [
      "Access control rules and segmentation",
      "VPN and secure remote access setup",
      "Threat prevention baseline hardening",
      "Traffic and alert policy configuration",
    ],
    includes: [
      "Security checklist review",
      "Rule set documentation",
      "Validation testing",
      "Admin handover session",
    ],
    steps: [
      "Tell us your network size and current firewall brand.",
      "We validate scope and recommend configuration approach.",
      "Firewall rules, VPN, and segmentation are implemented.",
      "You receive a hardened baseline and support guidance.",
    ],
    faqs: defaultFaqs,
    reviews: getStaticReviews("Managed Firewall Setup"),
    recommendedFor: ["SMBs", "Warehouses", "Multi-branch teams"],
    timeSlots: ["09:30", "13:00", "15:30"],
  ),
  MarketplaceService(
    id: 5,
    slug: "business-amc-plan",
    title: "Business AMC Plan",
    categoryId: "amc",
    category: "AMC Plans",
    tagline: "Annual preventive maintenance with priority IT support.",
    description: "Keep your business IT healthy year-round with preventive visits, device audits, remote support, and incident response coverage designed for small and mid-sized teams.",
    price: "From ₹18,999 / yr",
    priceValue: 18999.0,
    rating: 4.8,
    reviewCount: 3210,
    duration: "Yearly plan",
    durationMinutes: 0,
    image: "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=1200&h=900&fit=crop",
    gallery: [
      "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=1200&h=900&fit=crop",
    ],
    badge: "Best Value",
    features: [
      "Quarterly preventive maintenance visits",
      "Unlimited remote support tickets",
      "Device health and performance checks",
      "Priority escalation for downtime events",
    ],
    includes: [
      "Monthly health report",
      "Preventive maintenance checklist",
      "Asset tagging guidance",
      "SLA-oriented support workflow",
    ],
    steps: [
      "Tell us how many devices and sites you manage.",
      "Select the contract type and billing preference.",
      "We onboard your assets and support contacts.",
      "Quarterly visits and remote support begin immediately.",
    ],
    faqs: defaultFaqs,
    reviews: getStaticReviews("Business AMC Plan"),
    recommendedFor: ["SMBs", "Schools", "Clinics"],
    timeSlots: ["10:00", "13:30", "16:00"],
  ),
  MarketplaceService(
    id: 6,
    slug: "laptop-desktop-repair",
    title: "Laptop & Desktop Repair",
    categoryId: "hardware",
    category: "Hardware Repair",
    tagline: "Diagnosis, part replacement, OS fixes, and tune-ups.",
    description: "On-site repair and maintenance for workstations, laptops, printers, and office devices with clear diagnosis, service estimates, and performance optimization.",
    price: "From ₹499",
    priceValue: 499.0,
    rating: 4.6,
    reviewCount: 4510,
    duration: "1-3 hrs",
    durationMinutes: 180,
    image: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=1200&h=900&fit=crop",
    gallery: [
      "https://images.unsplash.com/photo-1518770660439-4636190af475?w=1200&h=900&fit=crop",
      "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=1200&h=900&fit=crop",
    ],
    badge: "Quick Fix",
    features: [
      "Issue diagnosis and resolution guidance",
      "RAM, SSD, and peripheral replacement support",
      "OS repair, software cleanup, and tune-up",
      "Device health report after completion",
    ],
    includes: [
      "Basic troubleshooting",
      "Transparent estimates",
      "Device optimization",
      "Service summary note",
    ],
    steps: [
      "Describe the issue and choose your visit slot.",
      "Technician diagnoses the device and confirms scope.",
      "Repair or optimization is performed on-site.",
      "You receive a quick summary with next-step guidance.",
    ],
    faqs: defaultFaqs,
    reviews: getStaticReviews("Laptop & Desktop Repair"),
    recommendedFor: ["Remote teams", "Students", "Small offices"],
    timeSlots: ["09:30", "11:00", "14:30", "18:00"],
  ),
  MarketplaceService(
    id: 7,
    slug: "rupee-one-test-service",
    title: "₹1 Payment Test Service",
    categoryId: "hardware",
    category: "Hardware Repair",
    tagline: "Test Razorpay integration with exactly ₹1 advance payment.",
    description: "This is a dummy service designed to test the end-to-end booking and Razorpay payment flow. The total price is ₹2, which results in a 50% advance payment of exactly ₹1.",
    price: "₹2 (₹1 Advance)",
    priceValue: 2.0,
    rating: 5.0,
    reviewCount: 1,
    duration: "10 mins",
    durationMinutes: 10,
    image: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=1200&h=900&fit=crop",
    gallery: [
      "https://images.unsplash.com/photo-1518770660439-4636190af475?w=1200&h=900&fit=crop",
    ],
    badge: "Testing Only",
    features: [
      "End-to-end integration test",
      "Razorpay payment of exactly ₹1",
      "Real-time database recording",
      "Technician notification simulation",
    ],
    includes: [
      "Full test flow verification",
      "Zero impact on real operations",
    ],
    steps: [
      "Select this service.",
      "Proceed to book and select address & time.",
      "Complete the payment of ₹1 through Razorpay.",
      "Check the Booking in Dashboard.",
    ],
    faqs: defaultFaqs,
    reviews: getStaticReviews("₹1 Payment Test Service"),
    recommendedFor: ["Developers", "Admins", "QA Team"],
    timeSlots: ["09:00", "11:00", "13:00", "15:00", "17:00"],
  ),
];

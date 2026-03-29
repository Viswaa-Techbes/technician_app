import 'package:flutter/material.dart';
import 'widgets.dart';

class CustomerReviewScreen extends StatefulWidget {
  const CustomerReviewScreen({super.key});

  @override
  State<CustomerReviewScreen> createState() => _CustomerReviewScreenState();
}

class _CustomerReviewScreenState extends State<CustomerReviewScreen> {
  int rating = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.star_rounded, size: 80, color: Color(0xFFF59E0B)),
              const SizedBox(height: 24),
              const Text("HOW WAS THE SERVICE?", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              const Text("Your feedback helps us improve", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 40,
                    color: const Color(0xFFF59E0B),
                  ),
                  onPressed: () => setState(() => rating = index + 1),
                )),
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Add your comments...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(20),
                  ),
                ),
              ),
              const Spacer(),
              CustomButton(
                label: "SUBMIT REVIEW",
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thank you for your review!")));
                  Navigator.pop(context);
                },
                color: const Color(0xFF1E3A8A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

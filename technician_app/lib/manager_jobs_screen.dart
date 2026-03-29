import 'package:flutter/material.dart';
import 'widgets.dart';
import 'project_detail_screen.dart';
import 'demo_data.dart';

class ManagerJobsScreen extends StatelessWidget {
  const ManagerJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("PROJECT REPOSITORY")),
      body: ListenableBuilder(
        listenable: DemoData.instance,
        builder: (context, _) {
          final allJobs = DemoData.instance.jobs;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            itemCount: allJobs.length,
            itemBuilder: (context, index) {
              final job = allJobs[index];
              return JobCard(
                job: job,
                index: index,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProjectDetailScreen(job: job)),
                ),
              );
            },
          );
        }
      ),
    );
  }
}

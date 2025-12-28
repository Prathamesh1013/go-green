import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:gogreen_admin/widgets/responsive_layout.dart';
import 'package:gogreen_admin/widgets/status_badge.dart';
import 'package:gogreen_admin/widgets/glass_card.dart';
import 'package:gogreen_admin/providers/job_provider.dart';
import 'package:gogreen_admin/models/maintenance_job.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class JobManagementPage extends StatefulWidget {
  final String? jobId;

  const JobManagementPage({
    super.key,
    this.jobId,
  });

  @override
  State<JobManagementPage> createState() => _JobManagementPageState();
}

class _JobManagementPageState extends State<JobManagementPage> {
  // Removed unused fields - can be added back when implementing form wizard

  @override
  void initState() {
    super.initState();
    if (widget.jobId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<JobProvider>().loadJobs();
      });
    }
  }

  @override
  void dispose() {
    // PageController removed - no longer needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.jobId != null) {
      return _buildJobDetailView();
    }

    return ResponsiveLayout(
      currentRoute: '/jobs',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Job Management'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const JobManagementPage(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<JobProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final jobs = provider.jobs;

            if (jobs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.build, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No jobs found',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Job'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return _JobCard(job: job);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildJobDetailView() {
    return ResponsiveLayout(
      currentRoute: '/jobs',
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/jobs'),
          ),
          title: const Text('Job Details'),
        ),
        body: Consumer<JobProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.jobs.isEmpty) {
              return const Center(
                child: Text('Job not found'),
              );
            }

            MaintenanceJob job;
            try {
              job = provider.jobs.firstWhere(
                (j) => j.jobId == widget.jobId,
              );
            } catch (e) {
              return const Center(
                child: Text('Job not found'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Job Header
                  _buildJobHeader(job),
                  const SizedBox(height: 24),
                  
                  // Status Timeline
                  _buildStatusTimeline(job),
                  const SizedBox(height: 24),
                  
                  // Photo Gallery
                  _buildPhotoGallery(),
                  const SizedBox(height: 24),
                  
                  // Job Details
                  _buildJobDetails(job),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildJobHeader(MaintenanceJob job) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.displayJobType,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${job.jobCategory} • ${DateFormat('MMM dd, yyyy').format(job.diagnosisDate)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: job.status, isJobStatus: true),
            ],
          ),
          if (job.totalCost != null) ...[
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CostItem(
                  label: 'Total Cost',
                  value: '₹${NumberFormat('#,###').format(job.totalCost)}',
                ),
                if (job.partsCost != null)
                  _CostItem(
                    label: 'Parts',
                    value: '₹${NumberFormat('#,###').format(job.partsCost)}',
                  ),
                if (job.labourCost != null)
                  _CostItem(
                    label: 'Labour',
                    value: '₹${NumberFormat('#,###').format(job.labourCost)}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(MaintenanceJob job) {
    final statuses = [
      'pending_diagnosis',
      'in_progress',
      'completed',
    ];

    final currentIndex = statuses.indexOf(job.status);

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Timeline',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          ...statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;

            return _TimelineItem(
              status: status,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              isLast: index == statuses.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    // Mock photos
    final photos = List.generate(6, (index) => 'photo_$index.jpg');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo Gallery',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        MasonryGridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          itemCount: photos.length,
          itemBuilder: (context, index) {
            return Container(
              height: (index % 3) * 50 + 150,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 48, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text(
                      photos[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildJobDetails(MaintenanceJob job) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Details',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          if (job.diagnosisNotes != null) ...[
            _DetailSection(
              title: 'Diagnosis Notes',
              content: job.diagnosisNotes!,
            ),
            const SizedBox(height: 16),
          ],
          if (job.repairNotes != null) ...[
            _DetailSection(
              title: 'Repair Notes',
              content: job.repairNotes!,
            ),
            const SizedBox(height: 16),
          ],
          if (job.customerNotes != null)
            _DetailSection(
              title: 'Customer Notes',
              content: job.customerNotes!,
            ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final MaintenanceJob job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.go('/jobs/${job.jobId}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
                CircleAvatar(
                  backgroundColor: AppColors.getStatusColor(job.status, context).withOpacity(0.1),
                  child: Icon(
                    Icons.build,
                    color: AppColors.getStatusColor(job.status, context),
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.displayJobType,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${job.jobCategory} • ${DateFormat('MMM dd, yyyy').format(job.diagnosisDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: job.status, isJobStatus: true),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _CostItem extends StatelessWidget {
  final String label;
  final String value;

  const _CostItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String status;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;

  const _TimelineItem({
    required this.status,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? AppColors.success : AppColors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent
                    ? AppColors.primary
                    : isCompleted
                        ? AppColors.success
                        : Colors.grey.shade300,
                border: Border.all(
                  color: isCurrent
                      ? AppColors.primary
                      : isCompleted
                          ? AppColors.success
                          : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? AppColors.success : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.split('_').map((word) =>
                    word[0].toUpperCase() + word.substring(1)
                  ).join(' '),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    color: color,
                  ),
                ),
                if (isCurrent)
                  Text(
                    'Current status',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final String content;

  const _DetailSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:odtrack_academia/shared/widgets/skeleton_loading.dart';

/// Skeleton screen for dashboard content
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Section
          const SkeletonText(width: 120, height: 20),
          const SizedBox(height: 12),
          Row(
            children: List.generate(3, (index) => const Expanded(
              child: SkeletonCard(
                height: 100,
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    SkeletonLoading(width: 32, height: 32, borderRadius: BorderRadius.all(Radius.circular(16))),
                    SizedBox(height: 8),
                    SkeletonText(width: 40, height: 24),
                    SizedBox(height: 4),
                    SkeletonText(width: 60, height: 12),
                  ],
                ),
              ),
            )),
          ),
          const SizedBox(height: 24),

          // Quick Actions Section
          const SkeletonText(width: 140, height: 20),
          const SizedBox(height: 12),
          ...List.generate(4, (index) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: SkeletonCard(
              height: 72,
              child: Row(
                children: [
                  SkeletonAvatar(radius: 20),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkeletonText(width: 150, height: 16),
                        SizedBox(height: 4),
                        SkeletonText(width: 200, height: 12),
                      ],
                    ),
                  ),
                  SkeletonLoading(width: 16, height: 16),
                ],
              ),
            ),
          )),
          const SizedBox(height: 24),

          // Recent Requests Section
          const SkeletonText(width: 160, height: 20),
          const SizedBox(height: 12),
          ...List.generate(3, (index) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: SkeletonCard(
              height: 80,
              child: Row(
                children: [
                  SkeletonAvatar(radius: 20),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SkeletonText(width: 120, height: 16),
                        SizedBox(height: 4),
                        SkeletonText(width: 180, height: 12),
                      ],
                    ),
                  ),
                  SkeletonButton(width: 80, height: 24),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

/// Skeleton screen for staff inbox
class StaffInboxSkeleton extends StatelessWidget {
  const StaffInboxSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16), // Add some bottom padding
      child: Column(
        children: [
          // Filter tabs skeleton
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(4, (index) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: const SkeletonButton(height: 32),
                ),
              )),
            ),
          ),

          // Stats skeleton
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(3, (index) => const Expanded(
                child: SkeletonCard(
                  height: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SkeletonText(width: 30, height: 24),
                      SizedBox(height: 4),
                      SkeletonText(width: 50, height: 12),
                    ],
                  ),
                ),
              )),
            ),
          ),

          // Request list skeleton
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling since it's in a SingleChildScrollView
            padding: const EdgeInsets.all(16),
            itemCount: 6,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: RequestCardSkeleton(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for individual request cards
class RequestCardSkeleton extends StatelessWidget {
  const RequestCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          const Row(
            children: [
              SkeletonAvatar(radius: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 150, height: 16),
                    SizedBox(height: 4),
                    SkeletonText(width: 100, height: 12),
                  ],
                ),
              ),
              SkeletonButton(width: 80, height: 24),
            ],
          ),
          const SizedBox(height: 12),

          // Info rows
          ...List.generate(4, (index) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SkeletonLoading(width: 16, height: 16),
                SizedBox(width: 8),
                SkeletonText(width: 60, height: 12),
                SizedBox(width: 8),
                Expanded(child: SkeletonText(height: 12)),
              ],
            ),
          )),

          const SizedBox(height: 16),

          // Action buttons
          const Row(
            children: [
              Expanded(child: SkeletonButton(height: 36)),
              SizedBox(width: 12),
              Expanded(child: SkeletonButton(height: 36)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for analytics dashboard
class AnalyticsSkeleton extends StatelessWidget {
  const AnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const SkeletonText(width: 200, height: 24),
          const SizedBox(height: 16),

          // Filter section
          const Row(
            children: [
              Expanded(child: SkeletonButton(height: 40)),
              SizedBox(width: 12),
              Expanded(child: SkeletonButton(height: 40)),
              SizedBox(width: 12),
              SkeletonButton(width: 100, height: 40),
            ],
          ),
          const SizedBox(height: 24),

          // Chart placeholders
          ...List.generate(3, (index) => const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: SkeletonCard(
              height: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonText(width: 180, height: 18),
                  SizedBox(height: 16),
                  SkeletonLoading(), // Removed Expanded to avoid overflow
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

/// Skeleton for list items (generic)
class ListItemSkeleton extends StatelessWidget {
  final bool showAvatar;
  final bool showTrailing;
  final int subtitleLines;

  const ListItemSkeleton({
    super.key,
    this.showAvatar = true,
    this.showTrailing = true,
    this.subtitleLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: showAvatar ? const SkeletonAvatar() : null,
      title: const SkeletonText(width: 150, height: 16),
      subtitle: subtitleLines > 0 ? const SkeletonText(
        width: 200,
        height: 12,
        lines: 1,
      ) : null,
      trailing: showTrailing ? const SkeletonLoading(width: 24, height: 24) : null,
    );
  }
}

/// Skeleton for form fields
class FormFieldSkeleton extends StatelessWidget {
  final String? label;
  final double height;

  const FormFieldSkeleton({
    super.key,
    this.label,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          const SkeletonText(width: 100, height: 14),
          const SizedBox(height: 8),
        ],
        const SkeletonButton(height: 56),
      ],
    );
  }
}
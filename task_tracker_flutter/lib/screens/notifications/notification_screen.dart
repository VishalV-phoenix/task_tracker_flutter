// =============================================
// NOTIFICATION_SCREEN.DART
// Shows all active notifications
// Tap to navigate to task, swipe to dismiss
// =============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../core/utils.dart';
import '../../providers/notification_provider.dart';
import '../../providers/task_provider.dart';

import '../../widgets/empty_state.dart';
import '../tasks/task_detail_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.activeNotifications;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.pop(context),
        ),
        title: Text(
          '🔔 Notifications (${notifications.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => notifProvider.clearAll(),
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: '✨',
              title: 'All clear!',
              subtitle: 'No notifications right now',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];

                // Recalculate urgency in case time passed
                final urgency = AppUtils.getUrgency(notif.dueDate);
                final urgencyIcon = AppUtils.getUrgencyIcon(urgency);
                final urgencyText = AppUtils.getUrgencyText(notif.dueDate);
                final urgencyColor = AppTheme.urgencyColor(urgency);
                final bgColor = AppTheme.urgencyBgColor(urgency);

                return Dismissible(
                  key: Key(notif.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.overdue,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    notifProvider.dismiss(notif.id);
                  },
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to the task
                      final task = context.read<TaskProvider>().getById(notif.taskId);
                      if (task != null) {
                        AppRouter.push(
                          context,
                          TaskDetailScreen(
                            categoryId: task.categoryId,
                            taskId: task.id,
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border(
                          left: BorderSide(color: urgencyColor, width: 4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(urgencyIcon,
                                  style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notif.taskTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  urgencyText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: urgencyColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (notif.dueDate != null)
                                  Text(
                                    'Due: ${AppUtils.formatDateTime(notif.dueDate!)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textTertiary,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Dismiss button
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            color: AppTheme.textTertiary,
                            onPressed: () => notifProvider.dismiss(notif.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
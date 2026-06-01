enum NotificationType {
  newTask,       // Новое задание (мастерам)
  newBid,
  bidAccepted,
  bidRejected,
  taskCompleted,
  taskCancelled,
  taskUpdate,
  newReview,
  newMessage,
  paymentReceived,
  taskAssigned,
  system,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String? relatedTaskId;
  final String? relatedUserId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.relatedTaskId,
    this.relatedUserId,
    this.isRead = false,
    required this.createdAt,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      relatedTaskId: relatedTaskId,
      relatedUserId: relatedUserId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  String get iconEmoji {
    switch (type) {
      case NotificationType.newTask:
        return '📋';
      case NotificationType.newBid:
        return '🔨';
      case NotificationType.bidAccepted:
        return '✅';
      case NotificationType.bidRejected:
        return '❌';
      case NotificationType.taskCompleted:
        return '🎉';
      case NotificationType.taskCancelled:
        return '🚫';
      case NotificationType.taskUpdate:
        return '🔄';
      case NotificationType.newReview:
        return '⭐';
      case NotificationType.newMessage:
        return '💬';
      case NotificationType.paymentReceived:
        return '💰';
      case NotificationType.taskAssigned:
        return '📋';
      case NotificationType.system:
        return '🔔';
    }
  }
}

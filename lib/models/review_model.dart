class ReviewModel {
  final String id;
  final String taskId;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerAvatar;
  final String targetUserId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.taskId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerAvatar,
    required this.targetUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskId': taskId,
    'reviewerId': reviewerId,
    'reviewerName': reviewerName,
    'reviewerAvatar': reviewerAvatar,
    'targetUserId': targetUserId,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    id: json['id'] as String,
    taskId: json['taskId'] as String,
    reviewerId: json['reviewerId'] as String,
    reviewerName: json['reviewerName'] as String,
    reviewerAvatar: json['reviewerAvatar'] as String?,
    targetUserId: json['targetUserId'] as String,
    rating: (json['rating'] as num).toDouble(),
    comment: json['comment'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

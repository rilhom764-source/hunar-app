enum BidStatus { pending, accepted, rejected }

class BidModel {
  final String id;
  final String taskId;
  final String workerId;
  final String workerName;
  final String? workerAvatar;
  final double workerRating;
  final int workerReviewsCount;
  final double amount;
  final String message;
  final String estimatedTime;
  final BidStatus status;
  final DateTime createdAt;

  const BidModel({
    required this.id,
    required this.taskId,
    required this.workerId,
    required this.workerName,
    this.workerAvatar,
    this.workerRating = 0.0,
    this.workerReviewsCount = 0,
    required this.amount,
    required this.message,
    required this.estimatedTime,
    this.status = BidStatus.pending,
    required this.createdAt,
  });

  BidModel copyWith({BidStatus? status}) {
    return BidModel(
      id: id,
      taskId: taskId,
      workerId: workerId,
      workerName: workerName,
      workerAvatar: workerAvatar,
      workerRating: workerRating,
      workerReviewsCount: workerReviewsCount,
      amount: amount,
      message: message,
      estimatedTime: estimatedTime,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskId': taskId,
    'workerId': workerId,
    'workerName': workerName,
    'workerAvatar': workerAvatar,
    'workerRating': workerRating,
    'workerReviewsCount': workerReviewsCount,
    'amount': amount,
    'message': message,
    'estimatedTime': estimatedTime,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BidModel.fromJson(Map<String, dynamic> json) => BidModel(
    id: json['id'] as String,
    taskId: json['taskId'] as String,
    workerId: json['workerId'] as String,
    workerName: json['workerName'] as String,
    workerAvatar: json['workerAvatar'] as String?,
    workerRating: (json['workerRating'] as num?)?.toDouble() ?? 0.0,
    workerReviewsCount: json['workerReviewsCount'] as int? ?? 0,
    amount: (json['amount'] as num).toDouble(),
    message: json['message'] as String,
    estimatedTime: json['estimatedTime'] as String,
    status: BidStatus.values.firstWhere((e) => e.name == json['status']),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

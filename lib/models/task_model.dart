enum TaskStatus { 
  open,               // Открыт (мастера могут откликаться)
  inProgress,         // В работе (принят мастером)
  completed,          // Завершён
  cancelled           // Отменён
}

enum TaskCategory {
  // Ремонт и строительство
  plumbing,
  electrical,
  repair,
  painting,
  construction,
  tiling,
  welding,
  roofing,
  windows,
  // Уборка и быт
  cleaning,
  garden,
  laundry,
  cooking,
  pestControl,
  // Грузоперевозки и переезд
  moving,
  delivery,
  courier,
  cargoTransport,
  groceryDelivery,  // Доставка продуктов
  toolRental,       // Аренда инструментов
  // Установка и ремонт техники
  applianceRepair,
  furnitureAssembly,
  acRepair,
  // Компьютерная помощь
  computerRepair,
  phoneRepair,
  networkSetup,
  // Авто
  autoRepair,
  carWash,
  tireService,
  // Красота и здоровье
  beauty,
  massage,
  fitness,
  // Обучение
  tutoring,
  musicLessons,
  languageLessons,
  drivingLessons,
  // Удалённая работа / IT
  remoteWork,
  webDevelopment,
  design,
  copywriting,
  photoVideo,
  smmMarketing,
  translation,
  // Юр. и бух. помощь
  legalHelp,
  accounting,
  // Мероприятия
  events,
  entertainment,
  // Другое
  other,
}

class TaskModel {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientAvatar;
  final String title;
  final String description;
  final TaskCategory category;
  final double budget;
  final String location;
  final double latitude;
  final double longitude;
  final DateTime deadline;
  final TaskStatus status;
  final List<String> imageUrls; // 📸 Фото заказа
  final String? voiceMessageUrl;
  final String? assignedWorkerId;
  final bool workStarted; // Master marked "started work"
  final DateTime? workStartedAt;
  final int bidsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientAvatar,
    required this.title,
    required this.description,
    required this.category,
    required this.budget,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.deadline,
    this.status = TaskStatus.open,
    this.imageUrls = const [], // 📸 По умолчанию пустой список
    this.voiceMessageUrl,
    this.assignedWorkerId,
    this.workStarted = false,
    this.workStartedAt,
    this.bidsCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  TaskModel copyWith({
    String? title,
    String? description,
    TaskCategory? category,
    double? budget,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? deadline,
    TaskStatus? status,
    List<String>? imageUrls, // 📸 Добавлено
    String? voiceMessageUrl,
    String? assignedWorkerId,
    bool? workStarted,
    DateTime? workStartedAt,
    int? bidsCount,
  }) {
    return TaskModel(
      id: id,
      clientId: clientId,
      clientName: clientName,
      clientAvatar: clientAvatar,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      budget: budget ?? this.budget,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      voiceMessageUrl: voiceMessageUrl ?? this.voiceMessageUrl,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      workStarted: workStarted ?? this.workStarted,
      workStartedAt: workStartedAt ?? this.workStartedAt,
      bidsCount: bidsCount ?? this.bidsCount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'clientName': clientName,
    'clientAvatar': clientAvatar,
    'title': title,
    'description': description,
    'category': category.name,
    'budget': budget,
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'deadline': deadline.toIso8601String(),
    'status': status.name,
    'imageUrls': imageUrls, // 📸 Добавлено
    'voiceMessageUrl': voiceMessageUrl,
    'assignedWorkerId': assignedWorkerId,
    'workStarted': workStarted,
    'workStartedAt': workStartedAt?.toIso8601String(),
    'bidsCount': bidsCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: json['id'] as String,
    clientId: json['clientId'] as String,
    clientName: json['clientName'] as String,
    clientAvatar: json['clientAvatar'] as String?,
    title: json['title'] as String,
    description: json['description'] as String,
    category: TaskCategory.values.firstWhere((e) => e.name == json['category']),
    budget: (json['budget'] as num).toDouble(),
    location: json['location'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    deadline: DateTime.parse(json['deadline'] as String),
    status: TaskStatus.values.firstWhere((e) => e.name == json['status']),
    imageUrls: (json['imageUrls'] as List?)?.cast<String>() ?? [], // 📸 Добавлено
    voiceMessageUrl: json['voiceMessageUrl'] as String?,
    assignedWorkerId: json['assignedWorkerId'] as String?,
    workStarted: json['workStarted'] as bool? ?? false,
    workStartedAt: json['workStartedAt'] != null ? DateTime.tryParse(json['workStartedAt'] as String) : null,
    bidsCount: json['bidsCount'] as int? ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  String get categoryIcon {
    switch (category) {
      case TaskCategory.plumbing: return '🔧';
      case TaskCategory.electrical: return '⚡';
      case TaskCategory.repair: return '🛠️';
      case TaskCategory.painting: return '🎨';
      case TaskCategory.construction: return '🏗️';
      case TaskCategory.tiling: return '🧱';
      case TaskCategory.welding: return '🔥';
      case TaskCategory.roofing: return '🏠';
      case TaskCategory.windows: return '🪟';
      case TaskCategory.cleaning: return '🧹';
      case TaskCategory.garden: return '🌿';
      case TaskCategory.laundry: return '👕';
      case TaskCategory.cooking: return '🍳';
      case TaskCategory.pestControl: return '🐛';
      case TaskCategory.moving: return '📦';
      case TaskCategory.delivery: return '🚚';
      case TaskCategory.courier: return '🏃';
      case TaskCategory.cargoTransport: return '🚛';
      case TaskCategory.groceryDelivery: return '🛒';
      case TaskCategory.toolRental: return '🔨';
      case TaskCategory.applianceRepair: return '🔌';
      case TaskCategory.furnitureAssembly: return '🪑';
      case TaskCategory.acRepair: return '❄️';
      case TaskCategory.computerRepair: return '💻';
      case TaskCategory.phoneRepair: return '📱';
      case TaskCategory.networkSetup: return '🌐';
      case TaskCategory.autoRepair: return '🚗';
      case TaskCategory.carWash: return '🧼';
      case TaskCategory.tireService: return '🛞';
      case TaskCategory.beauty: return '💇';
      case TaskCategory.massage: return '💆';
      case TaskCategory.fitness: return '🏋️';
      case TaskCategory.tutoring: return '📚';
      case TaskCategory.musicLessons: return '🎵';
      case TaskCategory.languageLessons: return '🗣️';
      case TaskCategory.drivingLessons: return '🚘';
      case TaskCategory.remoteWork: return '🏠';
      case TaskCategory.webDevelopment: return '👨‍💻';
      case TaskCategory.design: return '🎯';
      case TaskCategory.copywriting: return '✍️';
      case TaskCategory.photoVideo: return '📸';
      case TaskCategory.smmMarketing: return '📢';
      case TaskCategory.translation: return '🌍';
      case TaskCategory.legalHelp: return '⚖️';
      case TaskCategory.accounting: return '📊';
      case TaskCategory.events: return '🎉';
      case TaskCategory.entertainment: return '🎭';
      case TaskCategory.other: return '📋';
    }
  }
}

import 'package:flutter/material.dart';

/// Типы подписок для клиентов
enum SubscriptionFrequency {
  once,      // Разовый заказ
  weekly,    // Каждую неделю
  biweekly,  // Каждые 2 недели
  monthly,   // Раз в месяц
}

/// Статус подписки
enum SubscriptionStatus {
  active,    // Активна
  paused,    // Приостановлена
  cancelled, // Отменена
  expired,   // Истекла
}

/// Доступные тарифы абонемента (для клиентов)
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double priceMonthly;     // Цена в месяц (TJS)
  final int tasksIncluded;       // Заданий в месяц (0 = безлимит)
  final int discountPercent;     // Скидка на каждое задание
  final bool priorityWorker;     // Один и тот же мастер
  final bool expressBooking;     // Срочное бронирование
  final String badge;            // Иконка тарифа
  final List<Color> gradient;    // Цвета карточки

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceMonthly,
    required this.tasksIncluded,
    required this.discountPercent,
    required this.priorityWorker,
    required this.expressBooking,
    required this.badge,
    required this.gradient,
  });
}

/// Активная подписка пользователя
class SubscriptionModel {
  final String id;
  final String userId;
  final String planId;
  final String planName;
  final String? assignedWorkerId;    // Закреплённый мастер
  final String? assignedWorkerName;
  final String? assignedWorkerAvatar;
  final SubscriptionFrequency frequency;
  final SubscriptionStatus status;
  final String serviceCategory;      // Категория услуги
  final String serviceDescription;   // Описание (напр. "Уборка 2-комн. квартиры")
  final String preferredTime;        // Удобное время (напр. "Пятница, 14:00")
  final double pricePerVisit;        // Цена за визит
  final int tasksUsed;               // Использовано заданий
  final int tasksTotal;              // Всего заданий
  final DateTime startDate;
  final DateTime nextVisit;
  final DateTime? lastVisit;
  final DateTime createdAt;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.planId,
    required this.planName,
    this.assignedWorkerId,
    this.assignedWorkerName,
    this.assignedWorkerAvatar,
    required this.frequency,
    required this.status,
    required this.serviceCategory,
    required this.serviceDescription,
    required this.preferredTime,
    required this.pricePerVisit,
    required this.tasksUsed,
    required this.tasksTotal,
    required this.startDate,
    required this.nextVisit,
    this.lastVisit,
    required this.createdAt,
  });

  SubscriptionModel copyWith({
    String? assignedWorkerId,
    String? assignedWorkerName,
    String? assignedWorkerAvatar,
    SubscriptionStatus? status,
    int? tasksUsed,
    DateTime? nextVisit,
    DateTime? lastVisit,
  }) {
    return SubscriptionModel(
      id: id,
      userId: userId,
      planId: planId,
      planName: planName,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      assignedWorkerName: assignedWorkerName ?? this.assignedWorkerName,
      assignedWorkerAvatar: assignedWorkerAvatar ?? this.assignedWorkerAvatar,
      frequency: frequency,
      status: status ?? this.status,
      serviceCategory: serviceCategory,
      serviceDescription: serviceDescription,
      preferredTime: preferredTime,
      pricePerVisit: pricePerVisit,
      tasksUsed: tasksUsed ?? this.tasksUsed,
      tasksTotal: tasksTotal,
      startDate: startDate,
      nextVisit: nextVisit ?? this.nextVisit,
      lastVisit: lastVisit ?? this.lastVisit,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'planId': planId,
    'planName': planName,
    'assignedWorkerId': assignedWorkerId,
    'assignedWorkerName': assignedWorkerName,
    'assignedWorkerAvatar': assignedWorkerAvatar,
    'frequency': frequency.name,
    'status': status.name,
    'serviceCategory': serviceCategory,
    'serviceDescription': serviceDescription,
    'preferredTime': preferredTime,
    'pricePerVisit': pricePerVisit,
    'tasksUsed': tasksUsed,
    'tasksTotal': tasksTotal,
    'startDate': startDate.toIso8601String(),
    'nextVisit': nextVisit.toIso8601String(),
    'lastVisit': lastVisit?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        planId: json['planId'] as String,
        planName: json['planName'] as String,
        assignedWorkerId: json['assignedWorkerId'] as String?,
        assignedWorkerName: json['assignedWorkerName'] as String?,
        assignedWorkerAvatar: json['assignedWorkerAvatar'] as String?,
        frequency: SubscriptionFrequency.values.firstWhere(
          (e) => e.name == json['frequency'],
          orElse: () => SubscriptionFrequency.monthly,
        ),
        status: SubscriptionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SubscriptionStatus.active,
        ),
        serviceCategory: json['serviceCategory'] as String,
        serviceDescription: json['serviceDescription'] as String,
        preferredTime: json['preferredTime'] as String,
        pricePerVisit: (json['pricePerVisit'] as num).toDouble(),
        tasksUsed: json['tasksUsed'] as int? ?? 0,
        tasksTotal: json['tasksTotal'] as int? ?? 4,
        startDate: DateTime.parse(json['startDate'] as String),
        nextVisit: DateTime.parse(json['nextVisit'] as String),
        lastVisit: json['lastVisit'] != null
            ? DateTime.parse(json['lastVisit'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String get frequencyLabel {
    switch (frequency) {
      case SubscriptionFrequency.once:
        return 'Разовый';
      case SubscriptionFrequency.weekly:
        return 'Каждую неделю';
      case SubscriptionFrequency.biweekly:
        return 'Каждые 2 недели';
      case SubscriptionFrequency.monthly:
        return 'Раз в месяц';
    }
  }

  String get statusLabel {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Активен';
      case SubscriptionStatus.paused:
        return 'Приостановлен';
      case SubscriptionStatus.cancelled:
        return 'Отменён';
      case SubscriptionStatus.expired:
        return 'Истёк';
    }
  }
}

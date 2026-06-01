/// Тип сообщения в чате
enum MessageType {
  text,    // Обычное текстовое сообщение
  image,   // Фотография
  file,    // Файл (документ)
  voice,   // Голосовое сообщение
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  
  // Медиа-вложения
  final MessageType type;
  final String? imageUrl;        // URL фото (для type == image)
  final List<String> imageUrls;  // Несколько фото
  final String? fileUrl;         // URL файла
  final String? fileName;        // Имя файла для отображения
  final String? fileMimeType;    // MIME тип файла

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
    this.isRead = false,
    this.type = MessageType.text,
    this.imageUrl,
    this.imageUrls = const [],
    this.fileUrl,
    this.fileName,
    this.fileMimeType,
  });

  /// Есть ли вложения
  bool get hasAttachment =>
      imageUrl != null || imageUrls.isNotEmpty || fileUrl != null;

  /// Это голосовое сообщение?
  bool get isVoice => type == MessageType.voice;

  /// Текст для превью в списке чатов
  String get previewText {
    switch (type) {
      case MessageType.image:
        return content.isNotEmpty ? content : 'Фото';
      case MessageType.file:
        return content.isNotEmpty ? content : 'Файл: ${fileName ?? "документ"}';
      case MessageType.voice:
        return 'Голосовое сообщение';
      case MessageType.text:
        return content;
    }
  }
}

class ChatThread {
  final String id;
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final String? taskId;
  final String? taskTitle;
  final List<ChatMessage> messages;
  final DateTime lastActivity;
  int get unreadCount => messages.where((m) => !m.isRead && m.senderId == participantId).length;

  const ChatThread({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    this.taskId,
    this.taskTitle,
    required this.messages,
    required this.lastActivity,
  });

  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;
}

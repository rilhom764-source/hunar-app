import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../models/task_model.dart';
import '../providers/app_state_provider.dart';
import '../services/media_service.dart';
import '../widgets/confetti_celebration.dart';
import '../utils/geo_utils.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  TaskCategory _selectedCategory = TaskCategory.repair;
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  String _selectedCity = 'Dushanbe';
  
  // Фото заказа
  final List<XFile> _selectedImages = [];
  final Map<String, Uint8List> _imageBytes = {}; // для Web-превью
  bool _isUploadingImages = false;
  
  // 🎤 Голосовое сообщение
  bool _isRecording = false;
  bool _hasRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;
    final padding = isSmall ? 12.0 : 20.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('task_create_title'), style: TextStyle(fontSize: isSmall ? 16 : 18)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.headerGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              _buildLabel(l10n.tr('task_title_label')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  hintText: l10n.tr('task_title_hint'),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? l10n.tr('error_field_required')
                    : null,
              ),

              const SizedBox(height: 20),

              // Description
              _buildLabel(l10n.tr('task_description_label')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n.tr('task_description_hint'),
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? l10n.tr('error_field_required')
                    : null,
              ),

              const SizedBox(height: 20),

              // 📸 Фото заказа
              _buildLabel('📸 Фото проблемы (необязательно)'),
              const SizedBox(height: 10),
              _buildImagePicker(),

              const SizedBox(height: 20),

              // Category
              _buildLabel(l10n.tr('task_category_label')),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.surface,
                ),
                child: DropdownButtonFormField<TaskCategory>(
                  initialValue: _selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: TaskCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(
                        '${_catEmoji(cat)} ${l10n.tr('category_${cat.name}')}',
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ),

              const SizedBox(height: 20),

              // Budget
              _buildLabel(l10n.tr('task_budget_label')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _budgetCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: l10n.tr('task_budget_hint'),
                  prefixIcon: const Icon(Icons.payments_outlined),
                  suffixText: 'TJS',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l10n.tr('error_field_required');
                  }
                  final num = double.tryParse(v);
                  if (num == null || num < 10) {
                    return l10n.tr('error_min_budget');
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Location
              _buildLabel(l10n.tr('task_location_label')),
              const SizedBox(height: 6),
              // City selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.surface,
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCity,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  items: TajikistanLocations.cities.keys.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCity = v!),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _locationCtrl,
                decoration: InputDecoration(
                  hintText: l10n.tr('task_location_hint'),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? l10n.tr('error_field_required')
                    : null,
              ),

              const SizedBox(height: 20),

              // Deadline
              _buildLabel(l10n.tr('task_deadline_label')),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDeadline,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.surface,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: AppColors.slateGray),
                      const SizedBox(width: 12),
                      Text(
                        '${_deadline.day}.${_deadline.month.toString().padLeft(2, '0')}.${_deadline.year}',
                        style: const TextStyle(fontSize: 16, color: AppColors.deepSlate),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🎤 Голосовое сообщение
              _buildLabel('🎤 Голосовое сообщение (необязательно)'),
              const SizedBox(height: 10),
              _buildVoiceRecorder(),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isUploadingImages ? null : _submitTask,
                  icon: _isUploadingImages
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isUploadingImages
                        ? 'Загрузка фото...'
                        : l10n.tr('task_create_button'),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.deepSlate,
      ),
    );
  }

  // Виджет выбора фото (Web + Mobile)
  Widget _buildImagePicker() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Галерея'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImageFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Камера'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImagePreview(index),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePreview(int index) {
    final xFile = _selectedImages[index];
    if (kIsWeb) {
      final bytes = _imageBytes[xFile.path];
      if (bytes != null) {
        return Image.memory(bytes, width: 100, height: 100, fit: BoxFit.cover);
      }
      return Container(
        width: 100, height: 100,
        color: AppColors.divider,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else {
      return Image.file(File(xFile.path), width: 100, height: 100, fit: BoxFit.cover);
    }
  }

  // 🎤 Виджет записи голоса
  Widget _buildVoiceRecorder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          if (!_hasRecording)
            ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? 'Остановить запись' : 'Начать запись'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : AppColors.warning,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          
          if (_isRecording) ...[
            const SizedBox(height: 12),
            Text(
              _formatDuration(_recordingDuration),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],

          if (_hasRecording) ...[
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Голосовое сообщение записано',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  onPressed: _deleteRecording,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Удалить запись',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Выбор фото из галереи (кросс-платформа)
  Future<void> _pickImageFromGallery() async {
    if (_selectedImages.length >= 5) {
      _showSnackBar('Максимум 5 фотографий');
      return;
    }

    final image = await MediaService.pickImageFromGalleryXFile();
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        _imageBytes[image.path] = bytes;
      }
      setState(() => _selectedImages.add(image));
    }
  }

  // Фото с камеры (кросс-платформа)
  Future<void> _pickImageFromCamera() async {
    if (_selectedImages.length >= 5) {
      _showSnackBar('Максимум 5 фотографий');
      return;
    }

    final image = await MediaService.pickImageFromCameraXFile();
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        _imageBytes[image.path] = bytes;
      }
      setState(() => _selectedImages.add(image));
    }
  }

  // Удаление фото
  void _removeImage(int index) {
    final xFile = _selectedImages[index];
    _imageBytes.remove(xFile.path);
    setState(() => _selectedImages.removeAt(index));
  }

  // 🎤 Начать запись голоса
  Future<void> _startRecording() async {
    final started = await MediaService.startRecording();
    if (started) {
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Счётчик времени записи
      _startTimer();
    } else {
      _showSnackBar('Не удалось начать запись. Проверьте разрешения.');
    }
  }

  // 🎤 Остановить запись голоса
  Future<void> _stopRecording() async {
    final path = await MediaService.stopRecording();
    if (path != null) {
      setState(() {
        _isRecording = false;
        _hasRecording = true;
        _recordingPath = path;
      });
    }
  }

  // 🎤 Удалить запись
  void _deleteRecording() {
    setState(() {
      _hasRecording = false;
      _recordingPath = null;
      _recordingDuration = Duration.zero;
    });
  }

  // 🎤 Таймер записи
  void _startTimer() {
    Future.doWhile(() async {
      if (!_isRecording) return false;
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isRecording) {
        setState(() => _recordingDuration += const Duration(seconds: 1));
      }
      return _isRecording;
    });
  }

  // 🎤 Форматирование времени
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    final state = context.read<AppStateProvider>();
    final l10n = context.read<LocalizationProvider>();
    final cityCoords = TajikistanLocations.getCity(_selectedCity);

    // Показать индикатор загрузки
    setState(() => _isUploadingImages = true);

    try {
      // Загрузка фото (XFile -> Firebase)
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        _showSnackBar('Загрузка фото (${_selectedImages.length} шт.)...');
        
        if (kDebugMode) {
          debugPrint('CreateTask: Uploading ${_selectedImages.length} images...');
        }
        
        imageUrls = await MediaService.uploadMultipleXFiles(
          _selectedImages,
          folder: 'task_images',
          onProgress: (current, total) {
            if (mounted) {
              setState(() {}); // Trigger rebuild for progress
            }
          },
        );
        
        if (kDebugMode) {
          debugPrint('CreateTask: Uploaded ${imageUrls.length}/${_selectedImages.length} images');
          for (final url in imageUrls) {
            final isDataUrl = url.startsWith('data:');
            debugPrint('  URL type: ${isDataUrl ? "data:" : "https:"}, length: ${url.length}');
          }
        }
        
        if (imageUrls.isEmpty && _selectedImages.isNotEmpty) {
          _showSnackBar('Не удалось загрузить фото. Заказ будет создан без фото.');
        } else if (imageUrls.length < _selectedImages.length) {
          _showSnackBar('Загружено ${imageUrls.length} из ${_selectedImages.length} фото');
        }
      }

      // 🎤 Загрузка голосового сообщения
      String? voiceUrl;
      if (_hasRecording && _recordingPath != null) {
        _showSnackBar('Загрузка голосового сообщения...');
        voiceUrl = await MediaService.uploadAudio(_recordingPath!);
        
        if (kDebugMode) {
          debugPrint('CreateTask: Voice URL: ${voiceUrl != null ? "OK (${voiceUrl.length} chars)" : "FAILED"}');
        }
      }

      // Проверка размера данных перед сохранением в Firestore (лимит ~1MB на документ)
      int totalDataSize = 0;
      for (final url in imageUrls) {
        totalDataSize += url.length;
      }
      if (voiceUrl != null) totalDataSize += voiceUrl.length;
      
      if (totalDataSize > 900000) { // ~900KB предел для безопасности
        if (kDebugMode) {
          debugPrint('CreateTask: WARNING - Total data URL size: ${(totalDataSize / 1024).toStringAsFixed(0)} KB, may exceed Firestore limit');
        }
        // Оставляем только фото что помещаются
        final List<String> filteredUrls = [];
        int runningSize = voiceUrl?.length ?? 0;
        for (final url in imageUrls) {
          if (runningSize + url.length < 900000) {
            filteredUrls.add(url);
            runningSize += url.length;
          } else {
            if (kDebugMode) {
              debugPrint('CreateTask: Dropping image (would exceed Firestore limit)');
            }
          }
        }
        if (filteredUrls.length < imageUrls.length) {
          _showSnackBar('Некоторые фото слишком большие и были пропущены');
        }
        imageUrls = filteredUrls;
      }

      // Создание заказа
      await state.createTask(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _selectedCategory,
        budget: double.parse(_budgetCtrl.text.trim()),
        location: '${_locationCtrl.text.trim()}, $_selectedCity',
        latitude: cityCoords['lat']!,
        longitude: cityCoords['lon']!,
        deadline: _deadline,
        imageUrls: imageUrls, // 📸 Фото
        voiceMessageUrl: voiceUrl, // 🎤 Голос
      );

      if (mounted) {
        // 🎉 Первый заказ — показываем конфетти
        final isFirstTask = state.myCreatedTasks.length <= 1;
        if (isFirstTask) {
          ConfettiCelebration.show(context, type: CelebrationType.firstOrder);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tr('task_created_success')),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        // Сброс формы
        state.setNavIndex(0);
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Ошибка создания заказа: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploadingImages = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String _catEmoji(TaskCategory cat) {
    switch (cat) {
      case TaskCategory.plumbing:
        return '🔧';
      case TaskCategory.electrical:
        return '⚡';
      case TaskCategory.repair:
        return '🛠️';
      case TaskCategory.painting:
        return '🎨';
      case TaskCategory.construction:
        return '🏗️';
      case TaskCategory.tiling:
        return '🧱';
      case TaskCategory.welding:
        return '🔥';
      case TaskCategory.roofing:
        return '🏠';
      case TaskCategory.windows:
        return '🪟';
      case TaskCategory.cleaning:
        return '🧹';
      case TaskCategory.garden:
        return '🌿';
      case TaskCategory.laundry:
        return '👕';
      case TaskCategory.cooking:
        return '🍳';
      case TaskCategory.pestControl:
        return '🐛';
      case TaskCategory.moving:
        return '📦';
      case TaskCategory.delivery:
        return '🚚';
      case TaskCategory.courier:
        return '🏃';
      case TaskCategory.cargoTransport:
        return '🚛';
      case TaskCategory.groceryDelivery:
        return '🛒';
      case TaskCategory.toolRental:
        return '🔨';
      case TaskCategory.applianceRepair:
        return '🔌';
      case TaskCategory.furnitureAssembly:
        return '🪑';
      case TaskCategory.acRepair:
        return '❄️';
      case TaskCategory.computerRepair:
        return '💻';
      case TaskCategory.phoneRepair:
        return '📱';
      case TaskCategory.networkSetup:
        return '🌐';
      case TaskCategory.autoRepair:
        return '🚗';
      case TaskCategory.carWash:
        return '🧼';
      case TaskCategory.tireService:
        return '🛞';
      case TaskCategory.beauty:
        return '💇';
      case TaskCategory.massage:
        return '💆';
      case TaskCategory.fitness:
        return '🏋️';
      case TaskCategory.tutoring:
        return '📚';
      case TaskCategory.musicLessons:
        return '🎵';
      case TaskCategory.languageLessons:
        return '🗣️';
      case TaskCategory.drivingLessons:
        return '🚘';
      case TaskCategory.remoteWork:
        return '🏠';
      case TaskCategory.webDevelopment:
        return '👨‍💻';
      case TaskCategory.design:
        return '🎯';
      case TaskCategory.copywriting:
        return '✍️';
      case TaskCategory.photoVideo:
        return '📸';
      case TaskCategory.smmMarketing:
        return '📢';
      case TaskCategory.translation:
        return '🌍';
      case TaskCategory.legalHelp:
        return '⚖️';
      case TaskCategory.accounting:
        return '📊';
      case TaskCategory.events:
        return '🎉';
      case TaskCategory.entertainment:
        return '🎭';
      case TaskCategory.other:
        return '📋';
    }
  }
}

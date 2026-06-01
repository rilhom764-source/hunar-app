import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/user_model.dart';
import '../providers/app_state_provider.dart';
import 'worker_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng _initialPosition = const LatLng(38.5598, 68.7738); // Душанбе

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createMarkers();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _createMarkers() {
    final state = context.read<AppStateProvider>();
    final workers = state.workers;

    final markers = <Marker>{};
    
    for (final worker in workers) {
      markers.add(
        Marker(
          markerId: MarkerId(worker.id),
          position: LatLng(worker.latitude, worker.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            worker.rating >= 4.5
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: worker.fullName,
            snippet: '⭐ ${worker.rating.toStringAsFixed(1)} • ${worker.tasksCompleted} заказов',
            onTap: () => _showWorkerDetails(worker),
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
        if (workers.isNotEmpty) {
          _initialPosition = LatLng(workers.first.latitude, workers.first.longitude);
        }
      });
    }
  }

  void _showWorkerDetails(UserModel worker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerDetailScreen(worker: worker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺️ Карта мастеров'),
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
        actions: [
          IconButton(
            onPressed: _goToMyLocation,
            icon: const Icon(Icons.my_location),
            tooltip: 'Моё местоположение',
          ),
          IconButton(
            onPressed: _createMarkers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Карта
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 12.0,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: true,
            compassEnabled: true,
          ),

          // Легенда
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Легенда:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(
                    Colors.green,
                    'Рейтинг ≥ 4.5',
                  ),
                  const SizedBox(height: 4),
                  _buildLegendItem(
                    Colors.red,
                    'Рейтинг < 4.5',
                  ),
                ],
              ),
            ),
          ),

          // Счётчик мастеров
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_markers.length} мастеров',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  void _goToMyLocation() async {
    if (_mapController != null) {
      // По умолчанию центр Душанбе
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(
            target: LatLng(38.5598, 68.7738),
            zoom: 13.0,
          ),
        ),
      );
    }
  }
}

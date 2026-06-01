import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_theme.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    
    try {
      // Get current user info
      final user = _auth.currentUser;
      final userId = user?.uid ?? '';
      
      // Get user document
      DocumentSnapshot? userDoc;
      if (userId.isNotEmpty) {
        userDoc = await _db.collection('users').doc(userId).get();
      }
      
      // Count tasks
      final tasksSnapshot = await _db.collection('tasks').get();
      final openTasks = tasksSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'open';
      }).length;
      
      // Count workers
      final workersSnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .get();
      
      // Count notifications for current user
      int myNotifications = 0;
      if (userId.isNotEmpty) {
        final notifsSnapshot = await _db
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();
        myNotifications = notifsSnapshot.docs.length;
      }
      
      setState(() {
        _stats = {
          'currentUserId': userId,
          'userRole': userDoc?.data() != null 
              ? (userDoc!.data() as Map<String, dynamic>)['role'] ?? 'unknown'
              : 'not logged in',
          'totalTasks': tasksSnapshot.docs.length,
          'openTasks': openTasks,
          'totalWorkers': workersSnapshot.docs.length,
          'myNotifications': myNotifications,
          'phoneNumber': user?.phoneNumber ?? 'not set',
        };
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _stats = {'error': e.toString()};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Firestore Statistics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepSlate,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  if (_stats.containsKey('error'))
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Error:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _stats['error'] ?? 'Unknown error',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    _buildStatCard('Current User', [
                      'User ID: ${_stats['currentUserId']}',
                      'Role: ${_stats['userRole']}',
                      'Phone: ${_stats['phoneNumber']}',
                    ]),
                    const SizedBox(height: 12),
                    
                    _buildStatCard('Tasks', [
                      'Total Tasks: ${_stats['totalTasks']}',
                      'Open Tasks: ${_stats['openTasks']}',
                    ]),
                    const SizedBox(height: 12),
                    
                    _buildStatCard('Workers', [
                      'Total Workers: ${_stats['totalWorkers']}',
                    ]),
                    const SizedBox(height: 12),
                    
                    _buildStatCard('Notifications', [
                      'My Notifications: ${_stats['myNotifications']}',
                    ]),
                    const SizedBox(height: 20),
                    
                    Card(
                      color: AppColors.info.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Troubleshooting:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('✓ Если Total Workers = 0:'),
                            const Text(
                              '  → Зарегистрируйтесь как мастер',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            const Text('✓ Если Open Tasks не появляются:'),
                            const Text(
                              '  → Перезапустите приложение',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            const Text('✓ Если уведомления не приходят:'),
                            const Text(
                              '  → Проверьте разрешения Android',
                              style: TextStyle(fontSize: 12),
                            ),
                            const Text(
                              '  → Убедитесь, что role = worker',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, List<String> items) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(item),
            )),
          ],
        ),
      ),
    );
  }
}

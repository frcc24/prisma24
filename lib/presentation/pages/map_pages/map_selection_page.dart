import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/progress_storage.dart';
import 'full_mode_map_page.dart';

class MapSelectionPage extends StatefulWidget {
  const MapSelectionPage({super.key});

  @override
  State<MapSelectionPage> createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends State<MapSelectionPage> {

  Future<List<Map<String, dynamic>>> _maps() async {
    final snap = await FirebaseFirestore.instance
        .collection('maps')
        .orderBy('createdAt')
        .get();
    final storage = await ProgressStorage.getInstance();
    final maps = <Map<String, dynamic>>[];

    for (int i = 0; i < snap.docs.length; i++) {
      final d = snap.docs[i];
      final data = d.data();
      final id = d.id;

      final phases = await FirebaseFirestore.instance
          .collection('maps')
          .doc(id)
          .collection('phases')
          .get();
      final phaseCount = phases.size;
      final completedCount = storage.getCompleted(id).length;
      final percent = phaseCount == 0
          ? 0
          : ((completedCount / phaseCount) * 100).round();

      bool unlocked = i == 0 || storage.isMapUnlocked(id);
      if (!unlocked && i > 0) {
        final prevId = snap.docs[i - 1].id;
        final completed = storage.getCompleted(prevId).length;
        unlocked = completed >= 8;
      }

      maps.add({
        'id': id,
        'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        'message': data['message'] ?? '',
        'bg': data['bg'] ?? '',
        'unlocked': unlocked,
        'percent': percent,
      });
    }
    return maps;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('choose_map'.tr),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/ui/bg_gradient.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _maps(),
          builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final maps = snap.data!;
          if (maps.isEmpty) {
            return Center(child: Text('no_maps'.tr));
          }
          final topPadding =
              MediaQuery.of(context).padding.top + kToolbarHeight + 24;
          return ListView(
            padding: EdgeInsets.fromLTRB(16, topPadding, 16, 16),
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: maps.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, i) {
                  final map = maps[i];
                  final id = map['id'] as String;
                  final unlocked = map['unlocked'] as bool? ?? false;
                  final date = map['createdAt'] as DateTime?;
                  final message = map['message'] as String?;
              final percent = map['percent'] as int? ?? 0;
              final theme = map['bg'] as String? ?? '';
              final bgPath = theme.isNotEmpty
                  ? (theme.contains('/')
                      ? theme
                      : 'assets/images/ui/bgs/$theme')
                  : 'assets/images/ui/bg_gradient.png';
              return Card(
                margin: EdgeInsets.zero,
                color: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        bgPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      title: Text('map'.trArgs(['${i + 1}'])),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(date != null
                              ? 'Criado em ${date.day}/${date.month}/${date.year}'
                              : 'Sem data'),
                          if (message != null && message.isNotEmpty)
                            Text(message),
                          Text('map_progress'.trParams({'pct': percent.toString()})),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        if (!unlocked) {
                          Get.snackbar('Ops', 'complete_prev_map'.tr,
                              snackPosition: SnackPosition.BOTTOM);
                        } else {
                          await Get.to(
                            () => FullModeMapPage(mapId: id),
                            routeName: '/full_map',
                            arguments: id,
                          );
                          if (mounted) setState(() {});
                        }
                      },
                    ),
                    if (!unlocked)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black54.withOpacity(0.6),
                          alignment: Alignment.center,
                          child:
                              const Icon(Icons.lock, color: Colors.white, size: 48),
                        ),
                      ),
                  ],
                ),
                );
              },
              ),
            ],);
          },
        ),
      ),
    );
  }
}

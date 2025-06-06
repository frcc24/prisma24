import 'package:get/get.dart';

import '../controllers/map_pages/full_mode_map_controller.dart';

class FullModeMapBinding extends Bindings {
  final String mapId;
  FullModeMapBinding(this.mapId);

  @override
  void dependencies() {
    Get.put(FullModeMapController(mapId), tag: mapId);
  }
}

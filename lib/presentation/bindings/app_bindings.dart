import 'package:get/get.dart';

import '../pages/tango_game/tango_board_controller.dart';
import '../pages/nonogram_game/nonogram_board_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(TangoBoardController(), permanent: true);
    Get.put(NonogramBoardController(), permanent: true);
  }
}

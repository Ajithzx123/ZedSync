import 'package:get/get.dart';

import 'data/repositories/portfolio_repository.dart';
import 'data/services/api_client.dart';
import 'ui/core/settings_controller.dart';
import 'ui/features/more/history_controller.dart';
import 'ui/features/portfolio/portfolio_controller.dart';

/// Dependency wiring: services -> repositories -> controllers.
class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(ApiClient(), permanent: true);
    Get.put(PortfolioRepository(api: Get.find()), permanent: true);
    Get.put(SettingsController(), permanent: true);
    Get.put(PortfolioController(repository: Get.find()), permanent: true);
    Get.lazyPut(() => HistoryController(repository: Get.find()), fenix: true);
  }
}

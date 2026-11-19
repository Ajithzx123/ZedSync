import 'package:get/get.dart';

import '../../../data/repositories/portfolio_repository.dart';
import '../../../domain/models/deal.dart';

class HistoryController extends GetxController {
  HistoryController({required PortfolioRepository repository}) : _repo = repository;

  final PortfolioRepository _repo;

  final deals = <Deal>[].obs;
  final days = 7.obs;
  final isLoading = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      deals.assignAll(await _repo.fetchDeals(days: days.value));
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void setDays(int d) {
    days.value = d;
    load();
  }
}

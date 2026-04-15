import 'package:flutter/foundation.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';

class FacilityProvider extends ChangeNotifier {
  List<Facility> _facilities = [];
  bool _isLoading = false;

  List<Facility> get facilities => _facilities;
  bool get isLoading => _isLoading;

  List<Facility> get favoriteFacilities =>
      _facilities.where((f) => f.isFavorite).toList();

  void setFacilities(List<Facility> facilities) {
    _facilities = facilities;
    _isLoading = false;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void toggleFavorite(String facilityId) {
    final facilityIndex = _facilities.indexWhere((f) => f.id == facilityId);
    if (facilityIndex != -1) {
      final oldFacility = _facilities[facilityIndex];
      final newFacility =
          oldFacility.copyWith(isFavorite: !oldFacility.isFavorite);
      _facilities[facilityIndex] = newFacility;
      notifyListeners();
    }
  }

  Facility? getFacilityById(String id) {
    try {
      return _facilities.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }
}

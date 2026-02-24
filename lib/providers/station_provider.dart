import 'package:flutter/foundation.dart';
import '../services/hydrogen_api.dart';

class StationProvider extends ChangeNotifier {
  ChargerStatus _chargerA = ChargerStatus.operating;
  ChargerStatus _chargerB = ChargerStatus.operating;
  CarWashStatus _carWashStatus = CarWashStatus.operating;
  TTStatus _ttAStatus = TTStatus.empty;
  TTStatus _ttBStatus = TTStatus.empty;
  String? _announcement;

  ChargerStatus get chargerA => _chargerA;
  ChargerStatus get chargerB => _chargerB;
  CarWashStatus get carWashStatus => _carWashStatus;
  TTStatus get ttAStatus => _ttAStatus;
  TTStatus get ttBStatus => _ttBStatus;
  String? get announcement => _announcement;

  void setChargerA(ChargerStatus status) {
    _chargerA = status;
    notifyListeners();
  }

  void setChargerB(ChargerStatus status) {
    _chargerB = status;
    notifyListeners();
  }

  void setCarWashStatus(CarWashStatus status) {
    _carWashStatus = status;
    notifyListeners();
  }

  void setAnnouncement(String? announcement) {
    _announcement = announcement;
    notifyListeners();
  }

  void setTTAStatus(TTStatus status) {
    _ttAStatus = status;
    notifyListeners();
  }

  void setTTBStatus(TTStatus status) {
    _ttBStatus = status;
    notifyListeners();
  }

  void updateFromApi(StationData data) {
    _chargerA = data.chargerA;
    _chargerB = data.chargerB;
    _carWashStatus = data.carWashStatus;
    _ttAStatus = data.ttAStatus;
    _ttBStatus = data.ttBStatus;
    _announcement = data.announcement;
    notifyListeners();
  }
}

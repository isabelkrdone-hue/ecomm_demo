import 'dart:collection';

import 'package:flutter/foundation.dart';

class AddressModel extends ChangeNotifier {
  AddressModel._privateConstructor();

  static final AddressModel instance = AddressModel._privateConstructor();

  final List<Map<String, String>> _addresses = [
    {
      'label': 'Rumah',
      'name': 'Isabel',
      'phone': '+62 812-3456-7890',
      'address': 'Jl. Mawar No. 12, Kel. Sukamaju, Kec. Cilandak',
      'city': 'Jakarta Selatan, DKI Jakarta 12430',
    },
    {
      'label': 'Kantor',
      'name': 'Isabel (Kantor)',
      'phone': '+62 812-3456-7890',
      'address': 'Gedung Graha Niaga Lt. 5, Jl. Sudirman No. 52',
      'city': 'Jakarta Pusat, DKI Jakarta 10220',
    },
  ];

  int _selectedIndex = 0;

  // ── Getters ────────────────────────────────────────────────────────────────

  UnmodifiableListView<Map<String, String>> get addresses =>
      UnmodifiableListView(_addresses);

  int get selectedIndex => _selectedIndex;

  bool get isEmpty => _addresses.isEmpty;

  Map<String, String>? get selectedAddress =>
      _addresses.isEmpty ? null : _addresses[_selectedIndex];

  // ── Mutators ───────────────────────────────────────────────────────────────

  void setSelected(int index) {
    if (index < 0 || index >= _addresses.length) return;
    _selectedIndex = index;
    notifyListeners();
  }

  void addAddress(Map<String, String> address) {
    _addresses.add(Map<String, String>.from(address));
    notifyListeners();
  }

  void updateAddress(int index, Map<String, String> address) {
    if (index < 0 || index >= _addresses.length) return;
    _addresses[index] = Map<String, String>.from(address);
    notifyListeners();
  }

  void removeAddress(int index) {
    if (index < 0 || index >= _addresses.length) return;
    _addresses.removeAt(index);
    if (_selectedIndex >= _addresses.length && _selectedIndex > 0) {
      _selectedIndex = _addresses.length - 1;
    }
    notifyListeners();
  }
}

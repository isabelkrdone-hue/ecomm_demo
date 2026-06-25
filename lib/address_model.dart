import 'dart:collection';

import 'package:flutter/foundation.dart';

class AddressModel extends ChangeNotifier {
  AddressModel._privateConstructor();

  static final AddressModel instance = AddressModel._privateConstructor();

  final List<Map<String, String>> _addresses = [];

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

  void replaceAddresses(List<Map<String, String>> addresses) {
    _addresses
      ..clear()
      ..addAll(addresses.map(Map<String, String>.from));
    if (_addresses.isEmpty) {
      _selectedIndex = 0;
    } else if (_selectedIndex >= _addresses.length) {
      _selectedIndex = _addresses.length - 1;
    }
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

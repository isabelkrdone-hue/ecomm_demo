// Global list to store all businesses
final List<Map<String, dynamic>> allBusinesses = [];

class BusinessModel {
  static final BusinessModel _instance = BusinessModel._internal();
  static BusinessModel get instance => _instance;
  
  BusinessModel._internal();

  List<Map<String, dynamic>> getAllBusinesses() {
    return List<Map<String, dynamic>>.from(allBusinesses);
  }

  void addBusiness(Map<String, dynamic> business) {
    allBusinesses.add(business);
  }

  void updateBusiness(int index, Map<String, dynamic> business) {
    if (index >= 0 && index < allBusinesses.length) {
      allBusinesses[index] = business;
    }
  }

  void deleteBusiness(int index) {
    if (index >= 0 && index < allBusinesses.length) {
      allBusinesses.removeAt(index);
    }
  }

  Map<String, dynamic>? getBusinessAt(int index) {
    if (index >= 0 && index < allBusinesses.length) {
      return allBusinesses[index];
    }
    return null;
  }

  int get count => allBusinesses.length;
}

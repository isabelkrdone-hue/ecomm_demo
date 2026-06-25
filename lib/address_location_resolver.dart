import 'repository/http.dart';

class AddressLocationResolver {
  AddressLocationResolver._();

  static final AddressLocationResolver instance = AddressLocationResolver._();

  final Map<String, String> _provinceCache = {};
  final Map<String, Map<String, String>> _regencyCacheByProvince = {};
  final Map<String, Map<String, String>> _districtCacheByRegency = {};
  final Map<String, Map<String, String>> _villageCacheByDistrict = {};

  bool _looksLikeLocationId(String? value) {
    if (value == null) return false;
    final normalized = value.trim();
    if (normalized.isEmpty) return false;
    return RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
        ).hasMatch(normalized) ||
        RegExp(r'^\d+$').hasMatch(normalized);
  }

  List<dynamic> _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map) {
      final nested =
          value['data'] ?? value['items'] ?? value['rows'] ?? value['results'];
      if (nested is List) return nested;
    }
    return [];
  }

  String? _firstString(Map item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  Map<String, String> _locationMapFrom(dynamic data) {
    final options = <String, String>{};
    for (final item in _extractList(data)) {
      if (item is Map) {
        final id = _firstString(item, const [
          'id',
          'kode',
          'code',
          'value',
          'province_id',
          'regency_id',
          'district_id',
          'village_id',
          'provinsi_id',
          'kota_id',
          'kecamatan_id',
          'desa_id',
        ]);
        final name = _firstString(item, const [
          'nama',
          'name',
          'provinsi',
          'kota',
          'kecamatan',
          'desa',
          'nama_provinsi',
          'province_name',
          'nama_kota',
          'nama_kabupaten',
          'regency_name',
          'city_name',
          'nama_kecamatan',
          'district_name',
          'nama_kelurahan',
          'village_name',
          'label',
        ]);
        if (id != null && name != null) {
          options[id] = name;
        }
      } else {
        final value = item.toString().trim();
        if (value.isNotEmpty) {
          options[value] = value;
        }
      }
    }
    return options;
  }

  Future<Map<String, String>> _provinces() async {
    if (_provinceCache.isNotEmpty) return _provinceCache;
    final res = await Http().getProvinces(perPage: 100);
    if (res['success'] == true) {
      _provinceCache.addAll(_locationMapFrom(res['data']));
    }
    return _provinceCache;
  }

  Future<Map<String, String>> _regencies(String provinceId) async {
    final cached = _regencyCacheByProvince[provinceId];
    if (cached != null && cached.isNotEmpty) return cached;
    final res = await Http().getRegencies(provinceId: provinceId, perPage: 100);
    final map = _locationMapFrom(res['data']);
    _regencyCacheByProvince[provinceId] = map;
    return map;
  }

  Future<Map<String, String>> _districts(String regencyId) async {
    final cached = _districtCacheByRegency[regencyId];
    if (cached != null && cached.isNotEmpty) return cached;
    final res = await Http().getDistricts(regencyId: regencyId, perPage: 100);
    final map = _locationMapFrom(res['data']);
    _districtCacheByRegency[regencyId] = map;
    return map;
  }

  Future<Map<String, String>> _villages(String districtId) async {
    final cached = _villageCacheByDistrict[districtId];
    if (cached != null && cached.isNotEmpty) return cached;
    final res = await Http().getVillages(districtId: districtId, perPage: 100);
    final map = _locationMapFrom(res['data']);
    _villageCacheByDistrict[districtId] = map;
    return map;
  }

  Future<String> resolveProvince(String? provinceId,
      {String fallback = ''}) async {
    if (provinceId == null || provinceId.trim().isEmpty) return fallback;
    final provinces = await _provinces();
    return provinces[provinceId] ?? fallback;
  }

  Future<String> resolveRegency(
    String? provinceId,
    String? regencyId, {
    String fallback = '',
  }) async {
    if (regencyId == null || regencyId.trim().isEmpty) return fallback;
    if (provinceId == null || provinceId.trim().isEmpty) return fallback;
    final regencies = await _regencies(provinceId);
    return regencies[regencyId] ?? fallback;
  }

  Future<String> resolveDistrict(
    String? regencyId,
    String? districtId, {
    String fallback = '',
  }) async {
    if (districtId == null || districtId.trim().isEmpty) return fallback;
    if (regencyId == null || regencyId.trim().isEmpty) return fallback;
    final districts = await _districts(regencyId);
    return districts[districtId] ?? fallback;
  }

  Future<String> resolveVillage(
    String? districtId,
    String? villageId, {
    String fallback = '',
  }) async {
    if (villageId == null || villageId.trim().isEmpty) return fallback;
    if (districtId == null || districtId.trim().isEmpty) return fallback;
    final villages = await _villages(districtId);
    return villages[villageId] ?? fallback;
  }

  Future<Map<String, String>> resolveAddress(
      Map<String, String> address) async {
    final provinceKey = _looksLikeLocationId(address['province_id'])
        ? address['province_id']
        : (_looksLikeLocationId(address['province'])
            ? address['province']
            : null);
    final regencyKey = _looksLikeLocationId(address['regency_id'])
        ? address['regency_id']
        : (_looksLikeLocationId(address['regency'])
            ? address['regency']
            : null);
    final districtKey = _looksLikeLocationId(address['district_id'])
        ? address['district_id']
        : (_looksLikeLocationId(address['district'])
            ? address['district']
            : null);
    final villageKey = _looksLikeLocationId(address['village_id'])
        ? address['village_id']
        : (_looksLikeLocationId(address['village'])
            ? address['village']
            : null);

    final resolvedProvince = await resolveProvince(
      provinceKey,
      fallback: address['province'] ?? '',
    );
    final resolvedRegency = await resolveRegency(
      provinceKey,
      regencyKey,
      fallback: address['regency'] ?? '',
    );
    final resolvedDistrict = await resolveDistrict(
      regencyKey,
      districtKey,
      fallback: address['district'] ?? '',
    );
    final resolvedVillage = await resolveVillage(
      districtKey,
      villageKey,
      fallback: address['village'] ?? '',
    );

    final cityParts = <String>[
      if (resolvedVillage.isNotEmpty) resolvedVillage,
      if (resolvedDistrict.isNotEmpty) resolvedDistrict,
      if (resolvedRegency.isNotEmpty) resolvedRegency,
      if (resolvedProvince.isNotEmpty) resolvedProvince,
    ];

    return {
      ...address,
      if (resolvedProvince.isNotEmpty) 'province': resolvedProvince,
      if (resolvedRegency.isNotEmpty) 'regency': resolvedRegency,
      if (resolvedDistrict.isNotEmpty) 'district': resolvedDistrict,
      if (resolvedVillage.isNotEmpty) 'village': resolvedVillage,
      if (cityParts.isNotEmpty) 'city': cityParts.join(', '),
    };
  }

  Future<List<Map<String, String>>> resolveAddresses(
    List<Map<String, String>> addresses,
  ) async {
    final resolved = <Map<String, String>>[];
    for (final address in addresses) {
      resolved.add(await resolveAddress(address));
    }
    return resolved;
  }
}

// Indonesia Location Data with cascading structure
// Province > City/Regency > District (Kecamatan) > Sub-district (Kelurahan)

class IndonesiaLocationData {
  // Main data structure
  static final Map<String, Map<String, Map<String, List<String>>>> locationData = {
    'DKI Jakarta': {
      'Jakarta Pusat': {
        'Menteng': ['Menteng', 'Gondangdia', 'Cikini', 'Kebon Sirih'],
        'Tanah Abang': ['Gelora', 'Bendungan Hilir', 'Karet Tengsin', 'Petamburan'],
        'Gambir': ['Gambir', 'Kebon Kelapa', 'Petojo Utara', 'Duri Pulo'],
      },
      'Jakarta Selatan': {
        'Kebayoran Baru': ['Senayan', 'Melawai', 'Gunung', 'Kramat Pela'],
        'Tebet': ['Tebet Barat', 'Tebet Timur', 'Kebon Baru', 'Bukit Duri'],
        'Cilandak': ['Cilandak Barat', 'Lebak Bulus', 'Pondok Labu', 'Cipete Selatan'],
      },
      'Jakarta Timur': {
        'Cakung': ['Cakung Barat', 'Cakung Timur', 'Rawa Terate', 'Penggilingan'],
        'Matraman': ['Kebon Manggis', 'Palmeriam', 'Utan Kayu Utara', 'Utan Kayu Selatan'],
      },
      'Jakarta Barat': {
        'Kebon Jeruk': ['Kebon Jeruk', 'Sukabumi Utara', 'Kelapa Dua', 'Duri Kepa'],
        'Grogol Petamburan': ['Grogol', 'Tomang', 'Jelambar', 'Tanjung Duren Utara'],
      },
      'Jakarta Utara': {
        'Kelapa Gading': ['Kelapa Gading Barat', 'Kelapa Gading Timur', 'Pegangsaan Dua'],
        'Tanjung Priok': ['Tanjung Priok', 'Sunter Agung', 'Papanggo', 'Kebon Bawang'],
      },
    },
    'Jawa Barat': {
      'Bandung': {
        'Bandung Wetan': ['Citarum', 'Tamansari', 'Cihapit', 'Braga'],
        'Coblong': ['Lebak Gede', 'Lebak Siliwangi', 'Sadang Serang', 'Cipaganti'],
        'Sukajadi': ['Sukajadi', 'Sukagalih', 'Cipedes', 'Pasteur'],
      },
      'Bekasi': {
        'Bekasi Utara': ['Harapan Baru', 'Kaliabang Tengah', 'Perwira', 'Teluk Pucung'],
        'Bekasi Selatan': ['Jatiwaringin', 'Jatisari', 'Pekayon Jaya', 'Margajaya'],
      },
      'Bogor': {
        'Bogor Tengah': ['Paledang', 'Babakan', 'Babakan Pasar', 'Gudang'],
        'Bogor Utara': ['Tegalega', 'Tanah Baru', 'Tanah Sareal', 'Kedung Jaya'],
      },
      'Depok': {
        'Beji': ['Beji', 'Beji Timur', 'Pondok Cina', 'Tanah Baru'],
        'Pancoran Mas': ['Pancoran Mas', 'Depok', 'Depok Jaya', 'Rangkapan Jaya'],
      },
    },
    'Jawa Tengah': {
      'Semarang': {
        'Semarang Tengah': ['Kauman', 'Kranggan', 'Pekunden', 'Karangkidul'],
        'Semarang Utara': ['Bandarharjo', 'Tanjung Mas', 'Kuningan', 'Panggung Lor'],
      },
      'Surakarta': {
        'Laweyan': ['Laweyan', 'Bumi', 'Panularan', 'Purwosari'],
        'Banjarsari': ['Nusukan', 'Kadipiro', 'Banyuanyar', 'Keprabon'],
      },
    },
    'Jawa Timur': {
      'Surabaya': {
        'Surabaya Pusat': ['Genteng', 'Tegalsari', 'Bubutan', 'Simokerto'],
        'Surabaya Utara': ['Kenjeran', 'Bulak', 'Semampir', 'Pabean Cantian'],
        'Surabaya Selatan': ['Wonokromo', 'Wonocolo', 'Tenggilis Mejoyo', 'Jambangan'],
      },
      'Malang': {
        'Klojen': ['Klojen', 'Oro-oro Dowo', 'Samaan', 'Kasin'],
        'Lowokwaru': ['Lowokwaru', 'Tunggulwulung', 'Tunjungsekar', 'Dinoyo'],
      },
    },
    'Bali': {
      'Denpasar': {
        'Denpasar Barat': ['Dauh Puri', 'Padangsambian', 'Tegal Harum', 'Pemecutan'],
        'Denpasar Selatan': ['Sanur', 'Renon', 'Panjer', 'Sesetan'],
      },
      'Badung': {
        'Kuta': ['Kuta', 'Legian', 'Seminyak', 'Tuban'],
        'Mengwi': ['Mengwi', 'Baha', 'Buduk', 'Cemagi'],
      },
    },
    'Sumatera Utara': {
      'Medan': {
        'Medan Kota': ['Medan Kota', 'Pandau Hulu I', 'Pusat Pasar', 'Sukaraja'],
        'Medan Baru': ['Babura', 'Merdeka', 'Kampung Baru', 'Petisah Tengah'],
      },
    },
    'Sumatera Selatan': {
      'Palembang': {
        'Ilir Barat I': ['Lorok Pakjo', 'Bukit Lama', 'Siring Agung', '24 Ilir'],
        'Seberang Ulu I': ['Seberang Ulu I', 'Plaju', 'Pahlawan', 'Talang Semut'],
      },
    },
    'Sulawesi Selatan': {
      'Makassar': {
        'Makassar': ['Baru', 'Losari', 'Lajangiru', 'Malimongan'],
        'Tamalate': ['Jongaya', 'Maccini Sombala', 'Parang Tambung', 'Balang Baru'],
      },
    },
    'Kalimantan Timur': {
      'Balikpapan': {
        'Balikpapan Kota': ['Damai', 'Gunung Bahagia', 'Klandasan Ilir', 'Klandasan Ulu'],
        'Balikpapan Utara': ['Batu Ampar', 'Gunung Samarinda', 'Karang Jati', 'Karang Rejo'],
      },
    },
  };

  // Get all provinces
  static List<String> getProvinces() {
    return locationData.keys.toList()..sort();
  }

  // Get cities by province
  static List<String> getCities(String province) {
    if (!locationData.containsKey(province)) return [];
    return locationData[province]!.keys.toList()..sort();
  }

  // Get districts (kecamatan) by province and city
  static List<String> getDistricts(String province, String city) {
    if (!locationData.containsKey(province)) return [];
    if (!locationData[province]!.containsKey(city)) return [];
    return locationData[province]![city]!.keys.toList()..sort();
  }

  // Get sub-districts (kelurahan) by province, city, and district
  static List<String> getSubDistricts(String province, String city, String district) {
    if (!locationData.containsKey(province)) return [];
    if (!locationData[province]!.containsKey(city)) return [];
    if (!locationData[province]![city]!.containsKey(district)) return [];
    return locationData[province]![city]![district]!..sort();
  }
}

class CropAdvisor {
  static List<String> suggestionsFor(DateTime date) {
    final month = date.month;
    if (month >= 6 && month <= 10) {
      return const [
        'Kharif paddy: maintain 2–5 cm standing water during tillering.',
        'Cotton: scout for pink bollworm; avoid late nitrogen top dress.',
        'Pulses (tur/arhar): ensure drainage after heavy rain spells.',
      ];
    }
    if (month >= 11 || month <= 2) {
      return const [
        'Rabi wheat: irrigate at crown root initiation if soil feels dry 5 cm deep.',
        'Chickpea: avoid waterlogging; widen furrows if clay soil.',
        'Vegetables: mulch beds to protect from temperature dips.',
      ];
    }
    return const [
      'Groundnut: complete final hoeing before pegging begins.',
      'Sorghum: watch for shoot fly in early stages; timely irrigation helps.',
      'Compost farm waste now to prepare for the next sowing window.',
    ];
  }

  static List<String> tips() {
    return const [
      'Check soil moisture with a simple finger test before each irrigation.',
      'Rotate legumes after cereals to rebuild nitrogen naturally.',
      'Record rainfall in a diary — it helps plan dry spells and tanker needs.',
      'Clean field channels after storms to avoid waterlogging.',
    ];
  }
}

class DeliveryLocation {
  final double latitude;
  final double longitude;
  final String? label;

  const DeliveryLocation({
    required this.latitude,
    required this.longitude,
    this.label,
  });

  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  String get coordinateText =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  String get displayText {
    final normalized = label?.trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;
    return coordinateText;
  }
}

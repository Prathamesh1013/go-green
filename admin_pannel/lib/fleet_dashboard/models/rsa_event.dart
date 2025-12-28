class RSAEvent {
  final String type;
  final String severity; // 'low', 'medium', 'high'
  final String time;
  final String location;

  RSAEvent({
    required this.type,
    required this.severity,
    required this.time,
    required this.location,
  });

  factory RSAEvent.fromJson(Map<String, dynamic> json) {
    return RSAEvent(
      type: json['type'] as String,
      severity: json['severity'] as String,
      time: json['time'] as String,
      location: json['location'] as String,
    );
  }
}

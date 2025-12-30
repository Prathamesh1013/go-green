enum AlertType { info, warning, critical }

class Alert {
  final AlertType type;
  final String message;

  Alert({
    required this.type,
    required this.message,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      type: AlertType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlertType.info,
      ),
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
    };
  }
}

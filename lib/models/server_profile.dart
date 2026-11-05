import 'dart:convert';

enum AuthType {
  password,
  privateKey,
}

class ServerProfile {
  final String id;
  String name;
  String host;
  int port;
  String username;
  AuthType authType;
  String password;
  String privateKey;
  String passphrase;
  int colorValue;
  DateTime? lastConnectedAt;

  ServerProfile({
    required this.id,
    required this.name,
    required this.host,
    this.port = 22,
    required this.username,
    this.authType = AuthType.password,
    this.password = '',
    this.privateKey = '',
    this.passphrase = '',
    this.colorValue = 0xFF10B981,
    this.lastConnectedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'authType': authType.name,
      'password': password,
      'privateKey': privateKey,
      'passphrase': passphrase,
      'colorValue': colorValue,
      'lastConnectedAt': lastConnectedAt?.toIso8601String(),
    };
  }

  factory ServerProfile.fromMap(Map<String, dynamic> map) {
    return ServerProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      host: map['host'] ?? '',
      port: map['port'] is int ? map['port'] : int.tryParse(map['port']?.toString() ?? '22') ?? 22,
      username: map['username'] ?? '',
      authType: map['authType'] == 'privateKey' ? AuthType.privateKey : AuthType.password,
      password: map['password'] ?? '',
      privateKey: map['privateKey'] ?? '',
      passphrase: map['passphrase'] ?? '',
      colorValue: map['colorValue'] ?? 0xFF10B981,
      lastConnectedAt: map['lastConnectedAt'] != null
          ? DateTime.tryParse(map['lastConnectedAt'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ServerProfile.fromJson(String source) =>
      ServerProfile.fromMap(json.decode(source));

  ServerProfile copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    AuthType? authType,
    String? password,
    String? privateKey,
    String? passphrase,
    int? colorValue,
    DateTime? lastConnectedAt,
  }) {
    return ServerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      authType: authType ?? this.authType,
      password: password ?? this.password,
      privateKey: privateKey ?? this.privateKey,
      passphrase: passphrase ?? this.passphrase,
      colorValue: colorValue ?? this.colorValue,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import '../models/server_profile.dart';
import 'secure_storage_service.dart';

class StorageService {
  static const String _keyServers = 'saved_servers_profiles_v1';
  static final SecureStorageService _secureStorage = SecureStorageService();

  static Future<List<ServerProfile>> loadServers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_keyServers);
      if (rawList == null || rawList.isEmpty) {
        return _defaultInitialServers();
      }

      final servers = rawList
          .map((item) => ServerProfile.fromJson(item))
          .toList();

      // Hydrate sensitive credentials from Hardware-Backed Keystore
      for (final srv in servers) {
        final secPwd = await _secureStorage.getServerPassword(srv.id);
        if (secPwd != null && secPwd.isNotEmpty) {
          srv.password = secPwd;
        }
        final secKey = await _secureStorage.getServerPrivateKey(srv.id);
        if (secKey != null && secKey.isNotEmpty) {
          srv.privateKey = secKey;
        }
        final secPass = await _secureStorage.getServerPassphrase(srv.id);
        if (secPass != null && secPass.isNotEmpty) {
          srv.passphrase = secPass;
        }
      }

      return servers;
    } catch (_) {
      return _defaultInitialServers();
    }
  }

  static Future<void> saveServers(List<ServerProfile> servers) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save sensitive credentials to SecureStorage
    for (final srv in servers) {
      await _secureStorage.saveServerCredentials(
        serverId: srv.id,
        password: srv.password,
        privateKey: srv.privateKey,
        passphrase: srv.passphrase,
      );
    }

    // Persist profile metadata (clearing plaintext passwords from unencrypted SharedPreferences)
    final sanitizedList = servers.map((s) {
      final sanitized = s.copyWith(password: '', privateKey: '', passphrase: '');
      return sanitized.toJson();
    }).toList();

    await prefs.setStringList(_keyServers, sanitizedList);
  }

  static Future<void> upsertServer(ServerProfile profile) async {
    final list = await loadServers();
    final index = list.indexWhere((s) => s.id == profile.id);
    if (index >= 0) {
      list[index] = profile;
    } else {
      list.insert(0, profile);
    }
    await saveServers(list);
  }

  static Future<void> deleteServer(String id) async {
    await _secureStorage.deleteServerCredentials(id);
    final list = await loadServers();
    list.removeWhere((s) => s.id == id);
    await saveServers(list);
  }

  static List<ServerProfile> _defaultInitialServers() {
    return [
      ServerProfile(
        id: 'default_vps_1',
        name: 'My Cloud Server',
        host: '192.168.1.100',
        port: 22,
        username: 'ubuntu',
        authType: AuthType.password,
        colorValue: 0xFF10B981,
      ),
    ];
  }
}

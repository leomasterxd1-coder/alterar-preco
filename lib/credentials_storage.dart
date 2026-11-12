import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredenciaisStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _usuario = 'usuario';
  static const _senha = 'senha';

  static Future<({String usuario, String senha})?> carregar() async {
    final usuario = await _storage.read(key: _usuario);
    final senha = await _storage.read(key: _senha);
    if (usuario == null || senha == null) return null;
    if (usuario.isEmpty || senha.isEmpty) return null;
    return (usuario: usuario, senha: senha);
  }

  static Future<void> salvar(String usuario, String senha) async {
    await _storage.write(key: _usuario, value: usuario);
    await _storage.write(key: _senha, value: senha);
  }

  static Future<void> limpar() async {
    await _storage.delete(key: _usuario);
    await _storage.delete(key: _senha);
  }
}

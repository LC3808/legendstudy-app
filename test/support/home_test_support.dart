import 'package:legendstudy_app/features/home/customization/home_configuration.dart';

class MemoryHomeCache implements HomeCache {
  final values = <String, String>{};
  bool fail = false;
  @override
  Future<String?> read(String owner) async {
    if (fail) throw StateError('offline');
    return values[owner];
  }

  @override
  Future<void> write(String owner, String value) async {
    if (fail) throw StateError('disk');
    values[owner] = value;
  }
}

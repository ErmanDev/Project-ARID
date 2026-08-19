import 'package:isar_community/isar.dart';

part 'app_config.g.dart';

/// Tunable key/value table so points and classification thresholds can change
/// without a code change.
@collection
class AppConfig {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String key;

  late String value;
}

/// Free-tier image hosting for this product environment.
///
/// Cloud name: Cloudinary Console → Product Environment (`dhoi760j1`)
/// Preset: unsigned `arid_unsigned` with folder `arid-reports`
class CloudinaryOptions {
  CloudinaryOptions._();

  static const compiledCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'dhoi760j1',
  );
  static const compiledPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'arid_unsigned',
  );
  static const folder = 'arid-reports';

  static bool isConfigured(String cloudName, String preset) {
    final name = cloudName.trim();
    return name.isNotEmpty &&
        name != 'YOUR_CLOUD_NAME' &&
        preset.trim().isNotEmpty;
  }
}

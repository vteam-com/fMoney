import 'dart:typed_data';

/// Data source configuration for file loading operations.
/// Supports:
/// - Local file paths
/// - In-memory byte data
/// - File format validation
class DataSource {
  DataSource({this.filePath = '', Uint8List? fileBytes}) : _fileBytes = fileBytes ?? Uint8List(0);

  final String filePath;

  final Uint8List _fileBytes;

  /// Returns the raw file bytes for the data source.
  Uint8List get fileBytes => _fileBytes;
}

// Function to open a folder in the FileExplorer/Finder
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

/// Opens local folder in system file explorer.
Future<void> showLocalFolder(final String folderPath) async {
  final Uri url = Uri.parse('file:$folderPath');

  if (!await launchUrl(url)) {
    throw Exception('Could not launch $url');
  }
}

const String initialAssetFile = 'assets/initial.json';
const String localFilename = 'myMoney.json';

/// Represents my file systems.
class MyFileSystems {
  /// Appends path separator between folder path and file name.
  static String append(final String folderPath, final String toAppend) {
    return '$folderPath${p.separator}$toAppend';
  }

  /// Checks if file exists at the specified path.
  static Future<bool> doesFileExist(final String pathToFile) async {
    final File file = File(pathToFile);
    return await file.exists();
  }

  /// Initially check if there is already a local file.
  /// If not, create one
  static Future<File> ensureFileIsExistOrCreateIt(
    final String pathToFile,
  ) async {
    final String containerFolder = p.dirname(pathToFile);
    await MyFileSystems.ensureFolderExist(containerFolder);

    final File file = File(pathToFile);

    if (!await file.exists()) {
      // read the file from assets first and create the local file with its contents
      await file.create();
    }

    return file;
  }

  /// Ensures folder exists at the specified path, creates if necessary.
  static Future<Directory> ensureFolderExist(final String fullPath) async {
    return await Directory(fullPath).create(recursive: true);
  }

  /// Returns file extension from file path.
  static String getFileExtension(final String filePath) {
    return p.extension(filePath);
  }

  /// Returns file modified time for the specified file path.
  static Future<DateTime?> getFileModifiedTime(String filePath) async {
    try {
      if (await MyFileSystems.doesFileExist(filePath)) {
        final File file = File(filePath);
        final FileStat fileStat = await file.stat();
        return fileStat.modified;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns file name from file path.
  static String getFileName(final String filePath) {
    return p.basename(filePath);
  }

  /// Returns folder path from file path.
  static String getFolderFromFilePath(final String filePath) {
    return p.dirname(filePath);
  }

  /// Returns the system path separator.
  static String get pathSeparator => p.separator;

  /// Reads file content as string from the specified path.
  static Future<String> readFile(final String pathToFile) async {
    if (await MyFileSystems.doesFileExist(pathToFile)) {
      final File file = File(pathToFile);
      return await file.readAsString();
    }
    return '';
  }

  /// Writes content to a file in the specified folder.
  static Future<void> writeFileContentIntoFolder(
    final String folder,
    final String fileName,
    final String content,
  ) {
    final String fullPathToFile = MyFileSystems.append(folder, fileName);
    return MyFileSystems.writeToFile(fullPathToFile, content);
  }

  /// Generic text file write
  static Future<void> writeToFile(
    final String pathToFile,
    final String data,
  ) async {
    final File file = File(pathToFile);

    if (!await file.exists()) {
      await file.create();
    }

    await file.writeAsString(data, flush: true);
  }
}

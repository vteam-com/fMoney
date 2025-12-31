// Function to open a folder in the FileExplorer/Finder
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

Future<void> showLocalFolder(final String folderPath) async {
  final Uri url = Uri.parse('file:$folderPath');

  if (!await launchUrl(url)) {
    throw Exception('Could not launch $url');
  }
}

const String initialAssetFile = 'assets/initial.json';
const String localFilename = 'myMoney.json';

class MyFileSystems {
  static String append(final String folderPath, final String toAppend) {
    return '$folderPath${p.separator}$toAppend';
  }

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

  static Future<Directory> ensureFolderExist(final String fullPath) async {
    return await Directory(fullPath).create(recursive: true);
  }

  static String getFileExtension(final String filePath) {
    return p.extension(filePath);
  }

  static Future<DateTime?> getFileModifiedTime(String filePath) async {
    try {
      if (await MyFileSystems.doesFileExist(filePath)) {
        final File file = File(filePath);
        final FileStat fileStat = await file.stat();
        return fileStat.modified;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static String getFileName(final String filePath) {
    return p.basename(filePath);
  }

  static String getFolderFromFilePath(final String filePath) {
    return p.dirname(filePath);
  }

  static String get pathSeparator => p.separator;

  static Future<String> readFile(final String pathToFile) async {
    if (await MyFileSystems.doesFileExist(pathToFile)) {
      final File file = File(pathToFile);
      return await file.readAsString();
    }
    return '';
  }

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

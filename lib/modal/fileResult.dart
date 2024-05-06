import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FileResult {
  final File file;
  final FileType type;
  final String extension;

  FileResult(this.file, this.type, this.extension);
}

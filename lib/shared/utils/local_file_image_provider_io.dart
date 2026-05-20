import 'dart:io';

import 'package:flutter/painting.dart';

ImageProvider<Object>? createLocalFileImageProvider(String pathOrUri) {
  final trimmed = pathOrUri.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.scheme == 'file') {
    return FileImage(File.fromUri(uri));
  }

  return FileImage(File(trimmed));
}

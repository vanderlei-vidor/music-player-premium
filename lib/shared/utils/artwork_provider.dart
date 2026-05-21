import 'package:flutter/painting.dart';

import 'local_file_image_provider_stub.dart'
    if (dart.library.io) 'local_file_image_provider_io.dart' as local_file;

ImageProvider<Object>? resolveArtworkImageProvider(String? artworkUrl) {
  if (artworkUrl == null) return null;

  final trimmed = artworkUrl.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  final scheme = uri?.scheme.toLowerCase();

  if (_looksLikeWindowsPath(trimmed)) {
    return local_file.createLocalFileImageProvider(trimmed);
  }

  if (scheme == 'http' || scheme == 'https') {
    return NetworkImage(trimmed);
  }

  if (scheme == 'content') {
    return null;
  }

  if (scheme == 'file') {
    return local_file.createLocalFileImageProvider(trimmed);
  }

  if (scheme != null && scheme.isNotEmpty) {
    return null;
  }

  return local_file.createLocalFileImageProvider(trimmed);
}

bool _looksLikeWindowsPath(String value) {
  if (value.length < 3) return false;
  final drive = value.codeUnitAt(0);
  final hasDriveLetter =
      (drive >= 65 && drive <= 90) || (drive >= 97 && drive <= 122);
  return hasDriveLetter &&
      value.codeUnitAt(1) == 58 &&
      (value[2] == r'\' || value[2] == '/');
}

import 'dart:typed_data';

const maxEvidencePhotoBytes = 5 * 1024 * 1024;

class EvidencePhotoType {
  final String mimeType;
  final String extension;
  const EvidencePhotoType(this.mimeType, this.extension);
}

EvidencePhotoType? detectEvidencePhoto(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return const EvidencePhotoType('image/jpeg', 'jpg');
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a) {
    return const EvidencePhotoType('image/png', 'png');
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return const EvidencePhotoType('image/webp', 'webp');
  }
  return null;
}

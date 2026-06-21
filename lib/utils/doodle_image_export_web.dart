import 'dart:html' as html;
import 'dart:typed_data';

Future<String?> saveDoodlePngBytes({
  required Uint8List bytes,
  required String fileName,
}) async {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
  return fileName;
}

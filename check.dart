import 'dart:io';
import 'dart:typed_data';

void main() async {
  final dir = Directory('assets/images/male1_sprite');
  if (!await dir.exists()) {
    print('Directory not found');
    return;
  }
  
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.png')).toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  
  for (var file in files) {
    final bytes = await file.readAsBytes();
    if (bytes.length > 24) {
      final byteData = ByteData.sublistView(bytes);
      // bytes 16-19 are width
      final width = byteData.getUint32(16, Endian.big);
      // bytes 20-23 are height
      final height = byteData.getUint32(20, Endian.big);
      
      final fileName = file.path.split(Platform.pathSeparator).last;
      print('- $fileName: ${width}x${height} pixels');
    }
  }
}

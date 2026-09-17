import 'dart:io';

void main() async {
  final file = File('assets/images/background/pickleball_court.png');
  if (await file.exists()) {
    print('File size: ${await file.length()}');
    // We don't have an image package directly accessible without pubspec dependencies,
    // but we can assume the user means "the edge of the screen".
  } else {
    print('File not found');
  }
}


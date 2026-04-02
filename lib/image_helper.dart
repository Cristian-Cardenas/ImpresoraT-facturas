import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageHelper {
  static Future<img.Image?> procesarLogo(Uint8List imagenBytes) async {
    try {
      final image = img.decodeImage(imagenBytes);
      if (image == null) return null;

      const maxWidth = 384;
      const maxHeight = 200;

      img.Image resized = image;

      if (image.width > maxWidth || image.height > maxHeight) {
        if (image.width / image.height > maxWidth / maxHeight) {
          resized = img.copyResize(image, width: maxWidth);
        } else {
          resized = img.copyResize(image, height: maxHeight);
        }
      }

      return img.grayscale(resized);
    } catch (e) {
      return null;
    }
  }
}

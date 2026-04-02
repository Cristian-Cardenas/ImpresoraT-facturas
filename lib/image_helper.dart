import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageHelper {
  static Future<Uint8List?> procesarLogo(Uint8List imagenBytes) async {
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

      final grayscale = img.grayscale(resized);
      final binary = img.Image(
        width: grayscale.width,
        height: grayscale.height,
      );

      for (int y = 0; y < grayscale.height; y++) {
        for (int x = 0; x < grayscale.width; x++) {
          final pixel = grayscale.getPixel(x, y);
          final luminance = img.getLuminance(pixel);
          if (luminance > 127) {
            binary.setPixel(x, y, img.ColorUint8.rgb(255, 255, 255));
          } else {
            binary.setPixel(x, y, img.ColorUint8.rgb(0, 0, 0));
          }
        }
      }

      final result = img.encodePng(binary);
      return Uint8List.fromList(result);
    } catch (e) {
      return null;
    }
  }
}

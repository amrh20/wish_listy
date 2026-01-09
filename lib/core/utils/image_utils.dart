import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/painting.dart' show decodeImageFromList;

/// Image compression utility
class ImageUtils {
  /// Compress image to target size (~500KB) and max dimensions (800x800)
  /// Returns path to compressed image file
  static Future<String> compressImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file does not exist');
      }

      // Get temporary directory for compressed image
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Get image dimensions to determine if we need to resize
      final imageBytes = await file.readAsBytes();
      final decodedImage = await decodeImageFromList(imageBytes);
      final originalWidth = decodedImage.width;
      final originalHeight = decodedImage.height;

      // Only resize if image is larger than 800x800
      // minWidth/minHeight will scale down if larger, but we don't want to upscale
      int? targetWidth;
      int? targetHeight;
      if (originalWidth > 800 || originalHeight > 800) {
        // Calculate dimensions to fit within 800x800 while maintaining aspect ratio
        final aspectRatio = originalWidth / originalHeight;
        if (originalWidth > originalHeight) {
          targetWidth = 800;
          targetHeight = (800 / aspectRatio).round();
        } else {
          targetHeight = 800;
          targetWidth = (800 * aspectRatio).round();
        }
      }

      // First pass: Compress with target dimensions (if needed)
      var result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        minWidth: targetWidth ?? originalWidth,
        minHeight: targetHeight ?? originalHeight,
        quality: 85, // Start with 85% quality
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        throw Exception('Failed to compress image');
      }

      var compressedFile = File(result.path);
      var compressedSize = await compressedFile.length();
      
      // Target size: ~500KB (500 * 1024 bytes)
      const targetSize = 500 * 1024;
      
      // If still too large, reduce quality iteratively
      if (compressedSize > targetSize) {
        int quality = 75;
        
        while (compressedSize > targetSize && quality >= 30) {
          result = await FlutterImageCompress.compressAndGetFile(
            imagePath,
            targetPath,
            minWidth: targetWidth ?? originalWidth,
            minHeight: targetHeight ?? originalHeight,
            quality: quality,
            format: CompressFormat.jpeg,
          );
          
          if (result == null) {
            throw Exception('Failed to compress image');
          }
          
          compressedFile = File(result.path);
          compressedSize = await compressedFile.length();
          
          // Reduce quality by 10 for next iteration if still too large
          if (compressedSize > targetSize) {
            quality -= 10;
          }
        }
      }

      if (result == null) {
        throw Exception('Failed to compress image: result is null');
      }

      return result.path;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }
}


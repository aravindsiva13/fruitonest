// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';

// class CloudinaryStorageService {
//   // Replace with your Cloudinary credentials
//   static const String cloudName = 'datvrenbt'; // Get from Cloudinary dashboard
//   static const String uploadPreset = 'fruitonest_products'; // Create in Settings > Upload
  
//   final ImagePicker _picker = ImagePicker();

//   // Pick single image
//   Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: source,
//         maxWidth: 1920,
//         maxHeight: 1920,
//         imageQuality: 85,
//       );
//       return image;
//     } catch (e) {
//       print('Error picking image: $e');
//       return null;
//     }
//   }

//   // Pick multiple images
//   Future<List<XFile>> pickMultipleImages({int maxImages = 5}) async {
//     try {
//       final List<XFile> images = await _picker.pickMultiImage(
//         maxWidth: 1920,
//         maxHeight: 1920,
//         imageQuality: 85,
//       );
      
//       if (images.length > maxImages) {
//         return images.sublist(0, maxImages);
//       }
//       return images;
//     } catch (e) {
//       print('Error picking multiple images: $e');
//       return [];
//     }
//   }

//   // Compress image
//   Future<List<int>?> compressImage(XFile imageFile) async {
//     try {
//       if (kIsWeb) {
//         return await imageFile.readAsBytes();
//       } else {
//         final result = await FlutterImageCompress.compressWithFile(
//           imageFile.path,
//           quality: 85,
//           minWidth: 1920,
//           minHeight: 1920,
//         );
//         return result;
//       }
//     } catch (e) {
//       print('Error compressing image: $e');
//       return null;
//     }
//   }

//   // Upload single image to Cloudinary
//   Future<String?> uploadImage({
//     required XFile imageFile,
//     String folder = 'products',
//     Function(double)? onProgress,
//   }) async {
//     try {
//       // Compress image
//       final compressedBytes = await compressImage(imageFile);
//       if (compressedBytes == null) {
//         throw Exception('Failed to compress image');
//       }

//       // Convert to base64
//       final base64Image = base64Encode(compressedBytes);
//       final base64String = 'data:image/jpeg;base64,$base64Image';

//       // Generate unique filename without slashes
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final uniqueId = '${timestamp}_${imageFile.name.replaceAll('/', '_')}';

//       // Prepare upload URL
//       final url = Uri.parse(
//         'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
//       );

//       // Upload to Cloudinary
//       // Note: folder parameter sets the folder, don't include it in public_id
//       final response = await http.post(
//         url,
//         body: {
//           'file': base64String,
//           'upload_preset': uploadPreset,
//           'folder': folder, // This creates the folder structure
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final imageUrl = data['secure_url'] as String;
//         return imageUrl;
//       } else {
//         print('Upload error response: ${response.body}');
//         throw Exception('Upload failed: ${response.body}');
//       }
//     } catch (e) {
//       print('Error uploading image: $e');
//       return null;
//     }
//   }

//   // Upload multiple images
//   Future<List<String>> uploadMultipleImages({
//     required List<XFile> imageFiles,
//     String folder = 'products',
//     Function(int current, int total)? onProgress,
//   }) async {
//     final List<String> downloadUrls = [];

//     for (int i = 0; i < imageFiles.length; i++) {
//       if (onProgress != null) {
//         onProgress(i + 1, imageFiles.length);
//       }

//       final url = await uploadImage(
//         imageFile: imageFiles[i],
//         folder: folder,
//       );

//       if (url != null) {
//         downloadUrls.add(url);
//       }
//     }

//     return downloadUrls;
//   }

//   // Delete image from Cloudinary (requires backend or signed delete)
//   Future<bool> deleteImage(String imageUrl) async {
//     try {
//       // Extract public_id from URL
//       final uri = Uri.parse(imageUrl);
//       final pathSegments = uri.pathSegments;
      
//       // Find the public_id (everything after version number)
//       int versionIndex = pathSegments.indexWhere((segment) => segment.startsWith('v'));
//       if (versionIndex == -1) return false;
      
//       final publicIdParts = pathSegments.sublist(versionIndex + 1);
//       final publicId = publicIdParts.join('/').split('.').first;

//       // Note: Delete requires authentication
//       // You'll need to implement backend endpoint for secure deletion
//       // For now, just return true (images stay on Cloudinary)
//       print('Image would be deleted: $publicId');
//       return true;
//     } catch (e) {
//       print('Error deleting image: $e');
//       return false;
//     }
//   }

//   // Delete multiple images
//   Future<void> deleteMultipleImages(List<String> imageUrls) async {
//     for (final url in imageUrls) {
//       await deleteImage(url);
//     }
//   }

//   // Upload profile picture
//   Future<String?> uploadProfilePicture({
//     required XFile imageFile,
//     required String userId,
//     String? oldImageUrl,
//   }) async {
//     try {
//       // Delete old image if exists (optional)
//       if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
//         await deleteImage(oldImageUrl);
//       }

//       // Upload new image
//       final url = await uploadImage(
//         imageFile: imageFile,
//         folder: 'profiles',
//       );

//       return url;
//     } catch (e) {
//       print('Error uploading profile picture: $e');
//       return null;
//     }
//   }
// }

//2



import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class CloudinaryStorageService {
  // Replace with your Cloudinary credentials
  static const String cloudName = 'datvrenbt'; // Get from Cloudinary dashboard
  static const String uploadPreset = 'fruitonest_products'; // Create in Settings > Upload
  
  final ImagePicker _picker = ImagePicker();

  // Pick single image
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Pick multiple images
  Future<List<XFile>> pickMultipleImages({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (images.length > maxImages) {
        return images.sublist(0, maxImages);
      }
      return images;
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  // Compress image
  Future<List<int>?> compressImage(XFile imageFile) async {
    try {
      if (kIsWeb) {
        return await imageFile.readAsBytes();
      } else {
        final result = await FlutterImageCompress.compressWithFile(
          imageFile.path,
          quality: 85,
          minWidth: 1920,
          minHeight: 1920,
        );
        return result;
      }
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  // Upload single image to Cloudinary
  Future<String?> uploadImage({
    required XFile imageFile,
    String folder = 'products',
    Function(double)? onProgress,
  }) async {
    try {
      // Compress image
      final compressedBytes = await compressImage(imageFile);
      if (compressedBytes == null) {
        throw Exception('Failed to compress image');
      }

      // Convert to base64
      final base64Image = base64Encode(compressedBytes);
      final base64String = 'data:image/jpeg;base64,$base64Image';

      // Prepare upload URL
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      // Upload to Cloudinary WITHOUT folder parameter
      // The folder will be set in the upload preset settings
      final response = await http.post(
        url,
        body: {
          'file': base64String,
          'upload_preset': uploadPreset,
          // Removed 'folder' parameter - set it in Cloudinary preset instead
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final imageUrl = data['secure_url'] as String;
        print('✅ Image uploaded successfully: $imageUrl');
        return imageUrl;
      } else {
        print('❌ Upload error response: ${response.body}');
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  // Upload multiple images
  Future<List<String>> uploadMultipleImages({
    required List<XFile> imageFiles,
    String folder = 'products',
    Function(int current, int total)? onProgress,
  }) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      if (onProgress != null) {
        onProgress(i + 1, imageFiles.length);
      }

      final url = await uploadImage(
        imageFile: imageFiles[i],
        folder: folder,
      );

      if (url != null) {
        downloadUrls.add(url);
      }
    }

    return downloadUrls;
  }

  // Delete image from Cloudinary (requires backend or signed delete)
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract public_id from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the public_id (everything after version number)
      int versionIndex = pathSegments.indexWhere((segment) => segment.startsWith('v'));
      if (versionIndex == -1) return false;
      
      final publicIdParts = pathSegments.sublist(versionIndex + 1);
      final publicId = publicIdParts.join('/').split('.').first;

      // Note: Delete requires authentication
      // You'll need to implement backend endpoint for secure deletion
      // For now, just return true (images stay on Cloudinary)
      print('Image would be deleted: $publicId');
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Delete multiple images
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await deleteImage(url);
    }
  }

  // Upload profile picture
  Future<String?> uploadProfilePicture({
    required XFile imageFile,
    required String userId,
    String? oldImageUrl,
  }) async {
    try {
      // Delete old image if exists (optional)
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await deleteImage(oldImageUrl);
      }

      // Upload new image
      final url = await uploadImage(
        imageFile: imageFile,
        folder: 'profiles',
      );

      return url;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }
}
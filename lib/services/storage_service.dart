// import 'dart:io';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:path/path.dart' as path;

// class StorageService {
//   final FirebaseStorage _storage = FirebaseStorage.instance;
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

//   // Pick multiple images (up to 5)
//   Future<List<XFile>> pickMultipleImages({int maxImages = 5}) async {
//     try {
//       final List<XFile> images = await _picker.pickMultipleImages(
//         maxWidth: 1920,
//         maxHeight: 1920,
//         imageQuality: 85,
//       );
      
//       // Limit to maxImages
//       if (images.length > maxImages) {
//         return images.sublist(0, maxImages);
//       }
//       return images;
//     } catch (e) {
//       print('Error picking multiple images: $e');
//       return [];
//     }
//   }

//   // Compress image before upload
//   Future<List<int>?> compressImage(XFile imageFile) async {
//     try {
//       if (kIsWeb) {
//         // For web, read bytes directly
//         return await imageFile.readAsBytes();
//       } else {
//         // For mobile, compress the image
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

//   // Upload single image to Firebase Storage
//   Future<String?> uploadImage({
//     required XFile imageFile,
//     required String folder, // e.g., 'products', 'profiles', 'banners'
//     String? fileName,
//     Function(double)? onProgress,
//   }) async {
//     try {
//       // Generate unique filename if not provided
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final extension = path.extension(imageFile.name);
//       final uploadFileName = fileName ?? 'image_${timestamp}$extension';
      
//       // Create reference
//       final ref = _storage.ref().child('$folder/$uploadFileName');
      
//       // Compress image
//       final compressedBytes = await compressImage(imageFile);
//       if (compressedBytes == null) {
//         throw Exception('Failed to compress image');
//       }

//       // Upload
//       final uploadTask = ref.putData(
//         compressedBytes,
//         SettableMetadata(contentType: 'image/${extension.replaceAll('.', '')}'),
//       );

//       // Track progress
//       if (onProgress != null) {
//         uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
//           final progress = snapshot.bytesTransferred / snapshot.totalBytes;
//           onProgress(progress);
//         });
//       }

//       // Wait for completion
//       await uploadTask;

//       // Get download URL
//       final downloadUrl = await ref.getDownloadURL();
//       return downloadUrl;
//     } catch (e) {
//       print('Error uploading image: $e');
//       return null;
//     }
//   }

//   // Upload multiple images
//   Future<List<String>> uploadMultipleImages({
//     required List<XFile> imageFiles,
//     required String folder,
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

//   // Delete image from Firebase Storage
//   Future<bool> deleteImage(String imageUrl) async {
//     try {
//       // Extract path from URL
//       final ref = _storage.refFromURL(imageUrl);
//       await ref.delete();
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

//   // Update product images (add new, remove old)
//   Future<List<String>> updateProductImages({
//     required List<String> existingUrls,
//     required List<XFile> newImages,
//     required String productId,
//   }) async {
//     // Upload new images
//     final newUrls = await uploadMultipleImages(
//       imageFiles: newImages,
//       folder: 'products/$productId',
//     );

//     // Combine with existing
//     return [...existingUrls, ...newUrls];
//   }

//   // Upload profile picture
//   Future<String?> uploadProfilePicture({
//     required XFile imageFile,
//     required String userId,
//     String? oldImageUrl,
//   }) async {
//     try {
//       // Delete old image if exists
//       if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
//         await deleteImage(oldImageUrl);
//       }

//       // Upload new image
//       final url = await uploadImage(
//         imageFile: imageFile,
//         folder: 'profiles',
//         fileName: 'profile_$userId${path.extension(imageFile.name)}',
//       );

//       return url;
//     } catch (e) {
//       print('Error uploading profile picture: $e');
//       return null;
//     }
//   }

//   // Upload banner image (for admin)
//   Future<String?> uploadBannerImage({
//     required XFile imageFile,
//     String? fileName,
//   }) async {
//     return await uploadImage(
//       imageFile: imageFile,
//       folder: 'banners',
//       fileName: fileName,
//     );
//   }

//   // Get storage usage (optional - for analytics)
//   Future<int> getStorageUsage(String folder) async {
//     try {
//       final ref = _storage.ref().child(folder);
//       final result = await ref.listAll();
      
//       int totalSize = 0;
//       for (final item in result.items) {
//         final metadata = await item.getMetadata();
//         totalSize += metadata.size ?? 0;
//       }
      
//       return totalSize;
//     } catch (e) {
//       print('Error getting storage usage: $e');
//       return 0;
//     }
//   }

//   // Clean up orphaned images (images not referenced in database)
//   Future<void> cleanupOrphanedImages({
//     required String folder,
//     required List<String> validUrls,
//   }) async {
//     try {
//       final ref = _storage.ref().child(folder);
//       final result = await ref.listAll();

//       for (final item in result.items) {
//         final url = await item.getDownloadURL();
//         if (!validUrls.contains(url)) {
//           await item.delete();
//           print('Deleted orphaned image: ${item.name}');
//         }
//       }
//     } catch (e) {
//       print('Error cleaning up orphaned images: $e');
//     }
//   }
// }
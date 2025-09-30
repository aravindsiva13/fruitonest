import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/cloudinary_storage_service.dart'; // Updated import
import '../models/product_model.dart';

class ManageProducts extends StatefulWidget {
  const ManageProducts({super.key});

  @override
  State<ManageProducts> createState() => _ManageProductsState();
}

class _ManageProductsState extends State<ManageProducts> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: Provider.of<DatabaseService>(context).getProducts(
          vendorId: authService.currentUser!.uid,
          activeOnly: false,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No products yet',
                    style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  const Text('Add your first product to get started'),
                ],
              ),
            );
          }

          final products = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(context, product);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: product.images.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.images.first,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.apple, color: Colors.green),
              ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('₹${product.price.toStringAsFixed(0)} per ${product.unit}'),
            Text(
              'Stock: ${product.stock} ${product.unit}',
              style: TextStyle(
                color: product.stock > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditProductDialog(context, product);
            } else if (value == 'delete') {
              _deleteProduct(context, product.id, product.images);
            } else if (value == 'toggle') {
              _toggleProductStatus(context, product);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(product.isActive ? 'Deactivate' : 'Activate'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProductFormDialog(
        isEdit: false,
        onSave: (productData, imageFiles) async {
          await _createProduct(context, productData, imageFiles);
        },
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProductFormDialog(
        isEdit: true,
        product: product,
        onSave: (productData, imageFiles) async {
          await _updateProduct(context, product, productData, imageFiles);
        },
      ),
    );
  }

  Future<void> _createProduct(
    BuildContext context,
    Map<String, dynamic> productData,
    List<XFile> imageFiles,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading images and creating product...'),
                ],
              ),
            ),
          ),
        ),
      );

      final authService = Provider.of<AuthService>(context, listen: false);
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final storageService = CloudinaryStorageService(); // Make sure this is CloudinaryStorageService

      // Upload images first
      List<String> imageUrls = [];
      if (imageFiles.isNotEmpty) {
        // Use simple folder name without slashes
        imageUrls = await storageService.uploadMultipleImages(
          imageFiles: imageFiles,
          folder: 'products', // Changed from 'products/$tempProductId'
          onProgress: (current, total) {
            print('Uploading image $current of $total');
          },
        );
      }

      // Create product with images
      final product = ProductModel(
        id: '',
        vendorId: authService.currentUser!.uid,
        name: productData['name'],
        description: productData['description'],
        price: productData['price'],
        category: productData['category'],
        images: imageUrls,
        stock: productData['stock'],
        unit: productData['unit'],
        isOrganic: productData['isOrganic'],
        isSeasonal: productData['isSeasonal'],
        createdAt: DateTime.now(),
        nutritionalInfo: productData['nutritionalInfo'],
      );

      await dbService.addProduct(product);

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close form
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateProduct(
    BuildContext context,
    ProductModel product,
    Map<String, dynamic> productData,
    List<XFile> newImageFiles,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Updating product...'),
                ],
              ),
            ),
          ),
        ),
      );

      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final storageService = CloudinaryStorageService(); // Make sure this is CloudinaryStorageService

      // Upload new images if any
      List<String> allImageUrls = List.from(productData['existingImages'] ?? []);
      
      if (newImageFiles.isNotEmpty) {
        final newUrls = await storageService.uploadMultipleImages(
          imageFiles: newImageFiles,
          folder: 'products', // Simple folder name
        );
        allImageUrls.addAll(newUrls);
      }

      // Update product
      await dbService.updateProduct(product.id, {
        'name': productData['name'],
        'description': productData['description'],
        'price': productData['price'],
        'stock': productData['stock'],
        'category': productData['category'],
        'unit': productData['unit'],
        'isOrganic': productData['isOrganic'],
        'isSeasonal': productData['isSeasonal'],
        'nutritionalInfo': productData['nutritionalInfo'],
        'images': allImageUrls,
      });

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close form
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _deleteProduct(BuildContext context, String productId, List<String> images) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product? This will also delete all product images.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final dbService = Provider.of<DatabaseService>(context, listen: false);
                final storageService = CloudinaryStorageService(); // Updated
                
                // Delete images from storage
                if (images.isNotEmpty) {
                  await storageService.deleteMultipleImages(images);
                }
                
                // Delete product from database
                await dbService.deleteProduct(productId);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleProductStatus(BuildContext context, ProductModel product) async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    await dbService.updateProduct(product.id, {'isActive': !product.isActive});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            product.isActive ? 'Product deactivated' : 'Product activated',
          ),
        ),
      );
    }
  }
}

// Separate widget for product form with image upload
class _ProductFormDialog extends StatefulWidget {
  final bool isEdit;
  final ProductModel? product;
  final Future<void> Function(Map<String, dynamic>, List<XFile>) onSave;

  const _ProductFormDialog({
    required this.isEdit,
    this.product,
    required this.onSave,
  });

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final nutritionalController = TextEditingController();
  
  String selectedCategory = 'Fruits';
  String selectedUnit = 'kg';
  bool isOrganic = false;
  bool isSeasonal = false;
  
  List<String> existingImageUrls = [];
  List<XFile> newImageFiles = [];
  bool isUploading = false;

  final categories = ['Fruits', 'Seasonal', 'Exotic', 'Organic', 'Berries', 'Citrus'];
  final units = ['kg', 'piece', 'dozen', 'gram'];

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.product != null) {
      nameController.text = widget.product!.name;
      descriptionController.text = widget.product!.description;
      priceController.text = widget.product!.price.toString();
      stockController.text = widget.product!.stock.toString();
      nutritionalController.text = widget.product!.nutritionalInfo ?? '';
      selectedCategory = widget.product!.category;
      selectedUnit = widget.product!.unit;
      isOrganic = widget.product!.isOrganic;
      isSeasonal = widget.product!.isSeasonal;
      existingImageUrls = List.from(widget.product!.images);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
    nutritionalController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final storageService = CloudinaryStorageService(); // Updated
    final images = await storageService.pickMultipleImages(
      maxImages: 5 - existingImageUrls.length - newImageFiles.length,
    );
    
    if (images.isNotEmpty) {
      setState(() {
        newImageFiles.addAll(images);
      });
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      newImageFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = existingImageUrls.length + newImageFiles.length;
    
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Product' : 'Add New Product'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Upload Section
                const Text(
                  'Product Images',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                // Image Grid
                if (existingImageUrls.isNotEmpty || newImageFiles.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: totalImages,
                      itemBuilder: (context, index) {
                        if (index < existingImageUrls.length) {
                          return _buildImageCard(
                            imageUrl: existingImageUrls[index],
                            onRemove: () => _removeExistingImage(index),
                          );
                        } else {
                          final newIndex = index - existingImageUrls.length;
                          return _buildImageCard(
                            imageFile: newImageFiles[newIndex],
                            onRemove: () => _removeNewImage(newIndex),
                          );
                        }
                      },
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                // Add Images Button
                if (totalImages < 5)
                  OutlinedButton.icon(
                    onPressed: isUploading ? null : _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text('Add Images (${totalImages}/5)'),
                  ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Product Details
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name *'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price (₹) *'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Stock Quantity *'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedCategory = value!);
                  },
                ),
                const SizedBox(height: 12),
                
                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: units.map((unit) {
                    return DropdownMenuItem(value: unit, child: Text(unit));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedUnit = value!);
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: nutritionalController,
                  decoration: const InputDecoration(labelText: 'Nutritional Info (Optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                
                CheckboxListTile(
                  title: const Text('Organic'),
                  value: isOrganic,
                  onChanged: (value) {
                    setState(() => isOrganic = value!);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                
                CheckboxListTile(
                  title: const Text('Seasonal'),
                  value: isSeasonal,
                  onChanged: (value) {
                    setState(() => isSeasonal = value!);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isUploading ? null : _handleSave,
          child: isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isEdit ? 'Update' : 'Add Product'),
        ),
      ],
    );
  }

  Widget _buildImageCard({String? imageUrl, XFile? imageFile, required VoidCallback onRemove}) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : FutureBuilder<Uint8List>(
                    future: imageFile!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(
                          snapshot.data!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        );
                      }
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isUploading = true);

    final productData = {
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'price': double.parse(priceController.text),
      'stock': int.parse(stockController.text),
      'category': selectedCategory,
      'unit': selectedUnit,
      'isOrganic': isOrganic,
      'isSeasonal': isSeasonal,
      'nutritionalInfo': nutritionalController.text.trim().isEmpty
          ? null
          : nutritionalController.text.trim(),
      'existingImages': existingImageUrls,
    };

    await widget.onSave(productData, newImageFiles);
  }
}
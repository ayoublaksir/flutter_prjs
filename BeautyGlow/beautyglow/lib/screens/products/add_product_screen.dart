import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/responsive/responsive_util.dart';

import '../../data/storage_service.dart';
import '../../models/product.dart';
import '../../utils/validation_util.dart';
import '../../services/ads_service.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({Key? key, this.product}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _reviewController = TextEditingController();

  String _selectedCategory = 'skincare';
  double _rating = 0;
  String? _imagePath;

  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _categories = [
    'skincare',
    'makeup',
    'haircare',
    'fragrance',
    'bodycare',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _brandController.text = widget.product!.brand;
      if (widget.product!.price != null) {
        _priceController.text = widget.product!.price!.toStringAsFixed(2);
      }
      _reviewController.text = widget.product!.review ?? '';
      _selectedCategory = widget.product!.category;
      _rating = widget.product!.rating;
      _imagePath = widget.product!.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXLarge),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.camera_alt, color: AppColors.primaryPink),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? photo = await _imagePicker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (photo != null) {
                    setState(() {
                      _imagePath = photo.path;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: AppColors.primaryPink),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? photo = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (photo != null) {
                    setState(() {
                      _imagePath = photo.path;
                    });
                  }
                },
              ),
              if (_imagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.errorRed),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imagePath = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final adsService = Provider.of<AdsService>(context, listen: false);

      try {
        final price = _priceController.text.isEmpty
            ? null
            : double.tryParse(_priceController.text);

        final product = Product(
          id: widget.product?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          brand: _brandController.text,
          category: _selectedCategory,
          price: price,
          rating: _rating,
          review:
              _reviewController.text.isEmpty ? null : _reviewController.text,
          dateAdded: widget.product?.dateAdded ?? DateTime.now(),
          isFavorite: false,
          imagePath: _imagePath,
        );

        if (widget.product == null) {
          // Creating new product
          _storageService.addProduct(product);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✅ Product "${_nameController.text}" added successfully!'),
                backgroundColor: AppColors.successGreen,
                duration: const Duration(seconds: 2),
              ),
            );

            Navigator.pop(context, true);

            // 🎯 STRATEGIC AD PLACEMENT: Show interstitial after product creation
            // This is a high-value moment - user just created a product
            await adsService.showInterstitialForProductCreation();
          }
        } else {
          // Updating existing product
          _storageService.updateProduct(product);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✅ Product "${_nameController.text}" updated successfully!'),
                backgroundColor: AppColors.successGreen,
                duration: const Duration(seconds: 2),
              ),
            );

            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error saving product: $e'),
              backgroundColor: AppColors.errorRed,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            ResponsiveUtil.instance
                .proportionateWidth(AppDimensions.paddingMedium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: ResponsiveUtil.instance.proportionateWidth(150),
                    height: ResponsiveUtil.instance.proportionateWidth(150),
                    decoration: BoxDecoration(
                      color: AppColors.softRose,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLarge),
                      border: Border.all(
                        color: AppColors.primaryPink.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: _imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusLarge),
                            child: Image.file(
                              File(_imagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 48,
                                color: AppColors.primaryPink.withOpacity(0.5),
                              ),
                              SizedBox(
                                  height: ResponsiveUtil.instance
                                      .proportionateHeight(8)),
                              Text(
                                'Add Photo',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ).animate().fadeIn().scale(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                    ),
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),

              // Product Details
              _buildSectionTitle('Product Details'),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(12)),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'e.g., Vitamin C Serum',
                  prefixIcon:
                      Icon(Icons.shopping_bag, color: AppColors.primaryPink),
                ),
                validator: ValidationUtil.validateProductName,
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),

              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  hintText: 'e.g., The Ordinary',
                  prefixIcon:
                      Icon(Icons.business, color: AppColors.primaryPink),
                ),
                validator: ValidationUtil.validateBrandName,
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),

              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (Optional)',
                  hintText: '0.00',
                  prefixIcon:
                      Icon(Icons.attach_money, color: AppColors.primaryPink),
                ),
                validator: ValidationUtil.validatePrice,
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),

              // Category
              _buildSectionTitle('Category'),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(12)),
              Wrap(
                spacing: ResponsiveUtil.instance.proportionateWidth(8),
                runSpacing: ResponsiveUtil.instance.proportionateHeight(8),
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text(_getCategoryLabel(category)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: AppColors.primaryPink,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),

              // Rating
              _buildSectionTitle('Your Rating'),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(12)),
              Center(
                child: RatingBar.builder(
                  initialRating: _rating,
                  minRating: 0,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: AppColors.warningAmber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating;
                    });
                  },
                ),
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),

              // Review
              _buildSectionTitle('Review (Optional)'),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(12)),
              TextFormField(
                controller: _reviewController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Share your thoughts about this product...',
                  alignLabelWithHint: true,
                ),
                validator: ValidationUtil.validateReview,
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(80)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveProduct,
        backgroundColor: AppColors.primaryPink,
        label: Text(
          widget.product == null ? 'Add Product' : 'Update Product',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.save, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.labelLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'skincare':
        return 'Skincare';
      case 'makeup':
        return 'Makeup';
      case 'haircare':
        return 'Hair Care';
      case 'fragrance':
        return 'Fragrance';
      case 'bodycare':
        return 'Body Care';
      default:
        return category;
    }
  }
}

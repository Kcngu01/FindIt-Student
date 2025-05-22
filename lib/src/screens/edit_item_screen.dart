import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/item_provider.dart';
import '../services/item_service.dart';
import '../models/characteristic.dart';
import '../models/item.dart';
import '../config/api_config.dart';
import '../services/image_service.dart';
import '../widgets/image_compression_info.dart';

class EditItemScreen extends StatefulWidget {
  final int itemId;

  const EditItemScreen({
    super.key,
    required this.itemId,
  });

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  //image file picked
  File? _imageFile;
  File? _compressedImageFile;
  bool _isCompressing = false;
  final ImagePicker _picker = ImagePicker();
  final ItemService _itemService = ItemService();

  // Data for dropdowns
  late Future<List<Characteristic>> _categories;
  late Future<List<Characteristic>> _colours;
  late Future<List<Characteristic>> _locations;
  
  int? _selectedCategoryId;
  int? _selectedColourId;
  int? _selectedLocationId;
  
  bool _isLoading = false;
  String? _error;
  //current item waiting to be edited
  Item? _currentItem;

  @override
  void initState() {
    super.initState();
    _categories = _itemService.getCategories();
    _colours = _itemService.getColours();
    _locations = _itemService.getLocations();
    
    // Load current item details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentItem();
    });
  }

  Future<void> _loadCurrentItem() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      
      // Check if we already have the item in the provider
      if (itemProvider.currentItem?.id == widget.itemId) {
        _populateFormWithItem(itemProvider.currentItem!);
      } else {
        // If not, load it
        await itemProvider.loadItemDetails(widget.itemId);
        if (itemProvider.currentItem != null) {
          _populateFormWithItem(itemProvider.currentItem!);
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFormWithItem(Item item) {
    setState(() {
      _currentItem = item;
      _nameController.text = item.name;
      _descriptionController.text = item.description ?? '';
      _selectedCategoryId = item.categoryId;
      _selectedColourId = item.colorId;
      _selectedLocationId = item.locationId;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    // if (pickedFile != null) {
    //   await _processSelectedImage(File(pickedFile.path));
    // }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    await _processSelectedImage(File(photo.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    await _processSelectedImage(File(image.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  //compress the image
  Future<void> _processSelectedImage(File imageFile) async {
    setState(() {
      _imageFile = imageFile;
      _isCompressing = true;
      _compressedImageFile = null;
    });
    
    // Check if the image needs compression (over 5MB)
    final fileSize = await imageFile.length();
    if (fileSize > ImageService.maxFileSize) {
      try {
        // Perform the compression
        final compressedFile = await ImageService.compressImage(imageFile);
        
        if (mounted) {
          setState(() {
            _compressedImageFile = compressedFile;
            _isCompressing = false;
          });
        }
      } catch (e) {
        print('Error compressing image: $e');
        if (mounted) {
          setState(() {
            _compressedImageFile = null;
            _isCompressing = false;
          });
        }
      }
    } else {
      setState(() {
        _isCompressing = false;
      });
    }
  }

  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    
    if (_selectedColourId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a color')),
      );
      return;
    }
    
    if (_selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      print(widget.itemId);
      print(_nameController.text);
      print(_descriptionController.text);
      print(_selectedCategoryId);
      print(_selectedColourId);
      print(_selectedLocationId);
      print(_imageFile);
      await itemProvider.updateItem(
        itemId: widget.itemId,
        name: _nameController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        categoryId: _selectedCategoryId,
        colorId: _selectedColourId,
        locationId: _selectedLocationId,
        imageFile: _imageFile,
        type: _currentItem?.type,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated successfully')),
        );
        
        // Navigate back to details screen
        await Future.delayed(const Duration(seconds:2),(){
          if (mounted){
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update item: $_error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Item'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading && _currentItem == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _currentItem == null
              ? Center(child: Text('Error: $_error'))
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image section
            Center(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.contain,
                            ),
                          )
                        : _currentItem?.image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  ApiConfig.getItemImageUrl(_currentItem!.image!, _currentItem!.type),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.image,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                              ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Change Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  
                  // Show compression indicator
                  if (_isCompressing)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Checking image size...',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    
                  // Show compression information
                  if (!_isCompressing && _imageFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: ImageCompressionInfo(
                        originalImage: _imageFile,
                        compressedImage: _compressedImageFile,
                        isCompressed: _compressedImageFile != null,
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
              // onChanged: (value) {
              //   // This will update the controller's text value in real-time as the user types
              //   _nameController.text = value;
              //   print(_nameController.text);
              // },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              // onChanged: (value) {
              //   // This will update the controller's text value in real-time as the user types
              //   _descriptionController.text = value;
              //   print(_descriptionController.text);
              // },
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Category dropdown
            FutureBuilder<List<Characteristic>>(
              future: _categories,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No categories available');
                } else {
                  return DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCategoryId,
                    items: snapshot.data!.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  );
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Color dropdown
            FutureBuilder<List<Characteristic>>(
              future: _colours,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No colors available');
                } else {
                  return DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Color',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedColourId,
                    items: snapshot.data!.map((color) {
                      return DropdownMenuItem<int>(
                        value: color.id,
                        child: Text(color.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedColourId = value;
                      });
                    },
                  );
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Location dropdown
            FutureBuilder<List<Characteristic>>(
              future: _locations,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No locations available');
                } else {
                  return DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedLocationId,
                    items: snapshot.data!.map((location) {
                      return DropdownMenuItem<int>(
                        value: location.id,
                        child: Text(location.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLocationId = value;
                      });
                    },
                  );
                }
              },
            ),
            
            const SizedBox(height: 24),
            
            // Submit button
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateItem,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
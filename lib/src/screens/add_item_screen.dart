import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/login_provider.dart';
import '../services/item_service.dart';
import '../models/characteristic.dart';
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedType = 'found'; // Default to 'found'
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final ItemService itemService = ItemService();

  // Data for dropdowns from API
  late Future<List<Characteristic>> _categories;
  late Future<List<Characteristic>> _colours;
  late Future<List<Characteristic>> _locations;
  
  int? _selectedCategoryId;
  int? _selectedColourId;
  int? _selectedLocationId;
  
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _categories = itemService.getCategories();
    _colours = itemService.getColours();
    _locations = itemService.getLocations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Show a modal bottom sheet with camera and gallery options
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
                    setState(() {
                      _imageFile = File(photo.path);
                    });
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
                    setState(() {
                      _imageFile = File(image.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _validateCharacteristics() async {
    if (_selectedCategoryId == null || _selectedColourId == null || _selectedLocationId == null) {
      return;
    }

    try {
      // Fetch fresh data to validate
      final List<Characteristic> categories = await itemService.getCategories();
      final List<Characteristic> colours = await itemService.getColours();
      final List<Characteristic> locations = await itemService.getLocations();

      // Store the names of selected items before validation
      // These will be used to compare with the database entries
      String? selectedCategoryName;
      String? selectedColourName;
      String? selectedLocationName;
      
      // Get names from current UI dropdowns
      await Future.wait([
        _categories.then((list) {
          final category = list.firstWhere(
            (c) => c.id == _selectedCategoryId,
            orElse: () => Characteristic(id: -1, name: ''),
          );
          selectedCategoryName = category.name;
        }),
        _colours.then((list) {
          final colour = list.firstWhere(
            (c) => c.id == _selectedColourId,
            orElse: () => Characteristic(id: -1, name: ''),
          );
          selectedColourName = colour.name;
        }),
        _locations.then((list) {
          final location = list.firstWhere(
            (l) => l.id == _selectedLocationId,
            orElse: () => Characteristic(id: -1, name: ''),
          );
          selectedLocationName = location.name;
        }),
      ]);

      // Check if IDs exist in the database
      final dbCategory = categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => Characteristic(id: -1, name: ''),
      );
      final dbColour = colours.firstWhere(
        (c) => c.id == _selectedColourId,
        orElse: () => Characteristic(id: -1, name: ''),
      );
      final dbLocation = locations.firstWhere(
        (l) => l.id == _selectedLocationId,
        orElse: () => Characteristic(id: -1, name: ''),
      );

      // Check if IDs exist and if names match
      final categoryValid = dbCategory.id != -1 && dbCategory.name == selectedCategoryName;
      final colourValid = dbColour.id != -1 && dbColour.name == selectedColourName;
      final locationValid = dbLocation.id != -1 && dbLocation.name == selectedLocationName;

      if (!categoryValid || !colourValid || !locationValid) {
        // If any selection is invalid, refresh the data and throw error
        setState(() {
          _categories = itemService.getCategories();
          _colours = itemService.getColours();
          _locations = itemService.getLocations();
          // Clear invalid selections
          if (!categoryValid) _selectedCategoryId = null;
          if (!colourValid) _selectedColourId = null;
          if (!locationValid) _selectedLocationId = null;
        });
        throw Exception('Some selected options are no longer valid or have been modified. Please reselect from the updated list.');
      }
    } catch (e) {
      throw Exception('Failed to validate selections: $e');
    }
  }

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedCategoryId == null || _selectedColourId == null || _selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all required fields')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Validate characteristics before submission
      await _validateCharacteristics();
      
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      final studentId = loginProvider.student?.id;
      
      if (studentId == null) {
        throw Exception('User not logged in');
      }
      
      await itemService.createItem(
        name: _nameController.text,
        description: _descriptionController.text,
        type: _selectedType,
        categoryId: _selectedCategoryId!,
        colourId: _selectedColourId!,
        locationId: _selectedLocationId!,
        studentId: studentId,
        imageFile: _imageFile,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully')),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $_error'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: !_isLoading 
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Item Type Selection
                      const Text(
                        'Item Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedType = 'found';
                                  });
                                },
                                child: Container(
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _selectedType == 'found'
                                        ? Colors.green[100]
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Text(
                                    'Found',
                                    style: TextStyle(
                                      color: _selectedType == 'found'
                                          ? Colors.green[800]
                                          : Colors.grey[600],
                                      fontWeight: _selectedType == 'found'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedType = 'lost';
                                  });
                                },
                                child: Container(
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _selectedType == 'lost'
                                        ? Colors.red[100]
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Text(
                                    'Lost',
                                    style: TextStyle(
                                      color: _selectedType == 'lost'
                                          ? Colors.red[800]
                                          : Colors.grey[600],
                                      fontWeight: _selectedType == 'lost'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Item Image
                      const Text(
                        'Item Image',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: Colors.grey[400]!,
                              width: 1,
                            ),
                          ),
                          child: _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 64,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to add image',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Item Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter item name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Item Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Category Dropdown
                      FutureBuilder<List<Characteristic>>(
                        future: _categories,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          return DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            value: _selectedCategoryId,
                            hint: const Text('Select Category'),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryId = value;
                              });
                            },
                            items: snapshot.data!.map((category) {
                              return DropdownMenuItem<int>(
                                value: category.id,
                                child: Text(category.name),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Colour Dropdown
                      FutureBuilder<List<Characteristic>>(
                        future: _colours,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          return DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Colour',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            value: _selectedColourId,
                            hint: const Text('Select Colour'),
                            onChanged: (value) {
                              setState(() {
                                _selectedColourId = value;
                              });
                            },
                            items: snapshot.data!.map((colour) {
                              return DropdownMenuItem<int>(
                                value: colour.id,
                                child: Text(colour.name),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Location Dropdown
                      FutureBuilder<List<Characteristic>>(
                        future: _locations,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          return DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Location',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            value: _selectedLocationId,
                            hint: const Text('Select Location'),
                            onChanged: (value) {
                              setState(() {
                                _selectedLocationId = value;
                              });
                            },
                            items: snapshot.data!.map((location) {
                              return DropdownMenuItem<int>(
                                value: location.id,
                                child: Text(location.name),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Submit Button
                      ElevatedButton(
                        onPressed: _submitItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Submitting item...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 
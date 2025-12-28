import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'smart_camera_screen.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class InventoryPhotosScreen extends StatefulWidget {
  final String vehicleId;
  const InventoryPhotosScreen({super.key, required this.vehicleId});

  @override
  State<InventoryPhotosScreen> createState() => _InventoryPhotosScreenState();
}

class _InventoryPhotosScreenState extends State<InventoryPhotosScreen> {
  // We no longer need _picker here for main capture, but keep checkLostData logic if needed for recovery
  // However, SmartCamera handles its own capture. 
  // Let's simplify and use the custom camera.
  
  final List<Map<String, String>> categories = [
    {'id': 'ext_front', 'label': 'Exterior: Front View', 'icon': 'car'},
    {'id': 'ext_rear', 'label': 'Exterior: Rear View', 'icon': 'car'},
    {'id': 'ext_left', 'label': 'Exterior: Left Side', 'icon': 'car'},
    {'id': 'ext_right', 'label': 'Exterior: Right Side', 'icon': 'car'},
    {'id': 'dents', 'label': 'Dents & Scratches', 'icon': 'scan'},
    {'id': 'interior', 'label': 'Interior / Cabin', 'icon': 'armchair'},
    {'id': 'dikki', 'label': 'Dikki / Trunk', 'icon': 'shopping-bag'},
    {'id': 'tools', 'label': 'Tool Kit', 'icon': 'wrench'},
    {'id': 'valuables', 'label': 'Valuables Check', 'icon': 'briefcase'},
  ];

  @override
  void initState() {
    super.initState();
    _checkLostData();
  }

  Future<void> _checkLostData() async {
    // Standard image_picker lost data recovery is less relevant with custom camera
    // but we can leave it or remove it. Let's remove to stay clean.
  }

  Future<void> _capture(int index) async {
    if (index >= categories.length) return;
    final category = categories[index];
    
    try {
      final String? path = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => SmartCameraScreen(
            categoryId: category['id']!,
            categoryLabel: category['label']!,
          ),
        ),
      );
      
      if (path != null) {
        if (!mounted) return;
        
        // Show loading snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Syncing photo to dashboard...'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Save photo
        await context.read<AppProvider>().setInventoryPhoto(
          widget.vehicleId, 
          category['id']!, 
          path
        );

        // Auto move to next photo if available
        if (mounted && index + 1 < categories.length) {
          // Add a small delay for better transition feel
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _capture(index + 1);
          });
        } else if (mounted && index + 1 == categories.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All photos captured successfully!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removePhoto(Map<String, String> category) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: Text('Are you sure you want to remove the photo for ${category['label']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      await context.read<AppProvider>().removeInventoryPhoto(widget.vehicleId, category['id']!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo removed for ${category['label']}')),
      );
    }
  }

  bool get _isAllDone {
    final photos = context.watch<AppProvider>().getInventoryPhotos(widget.vehicleId);
    return categories.every((cat) => photos.containsKey(cat['id']));
  }

  @override
  Widget build(BuildContext context) {
    final photos = context.watch<AppProvider>().getInventoryPhotos(widget.vehicleId);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Inventory Photos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(LucideIcons.info, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All 9 photos are compulsory for this report.',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      ),
                      if (photos.length < categories.length)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton.icon(
                            onPressed: () => _capture(photos.length), // Start from first missing
                            icon: const Icon(LucideIcons.play, size: 16),
                            label: const Text('Start Capture Flow'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${photos.length}/${categories.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final photoPath = photos[cat['id']];
                return _buildPhotoCard(index, cat, photoPath);
              },
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(int index, Map<String, String> cat, String? path) {
    final bool hasPhoto = path != null;
    
    return InkWell(
      onTap: () => _capture(index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasPhoto ? AppTheme.successGreen : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhoto)
                Image.file(File(path), fit: BoxFit.cover)
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getIcon(cat['icon']!), color: AppTheme.primaryBlue, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        cat['label']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                      ),
                    ),
                  ],
                ),
              if (hasPhoto)
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () => _removePhoto(cat),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: const Icon(LucideIcons.trash2, color: AppTheme.dangerRed, size: 14),
                    ),
                  ),
                ),
              if (hasPhoto)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppTheme.successGreen, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.check, color: Colors.white, size: 12),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: (hasPhoto ? AppTheme.successGreen : AppTheme.primaryBlue).withOpacity(0.1),
                  child: Text(
                    hasPhoto ? 'Retake' : 'Capture',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.bold, 
                      color: hasPhoto ? AppTheme.successGreen : AppTheme.primaryBlue
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    final bool done = _isAllDone;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: done ? () => context.pop() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              done ? 'Verify & Apply' : 'Capture all photos to proceed',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'car': return LucideIcons.car;
      case 'scan': return LucideIcons.scan;
      case 'armchair': return LucideIcons.armchair;
      case 'shopping-bag': return LucideIcons.shoppingBag;
      case 'wrench': return LucideIcons.wrench;
      case 'briefcase': return LucideIcons.briefcase;
      default: return LucideIcons.camera;
    }
  }
}

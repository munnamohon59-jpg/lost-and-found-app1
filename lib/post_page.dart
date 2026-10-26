import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'colors.dart';
import 'models.dart';
import 'app_store.dart';
import 'helpers.dart';

/* =========================================================
   5. POST PAGE
   - ID verification: University ID / NID photo MANDATORY
   - Item post: item photo MANDATORY
========================================================= */

class PostPage extends StatefulWidget {
  final AppStore store;
  final VoidCallback onGoHome;

  const PostPage({super.key, required this.store, required this.onGoHome});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final itemNameController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();

  Uint8List? pickedImageBytes;
  String? category;
  String itemStatus = 'Lost';
  DateTime selectedDate = DateTime.now();
  bool isBusy = false;

  // তারিখ সিলেক্ট করার ক্যালেন্ডার ফাংশন
  Future<void> chooseDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate != null) {
      setState(() => selectedDate = pickedDate);
    }
  }

  /* ---------- ITEM PHOTO PICKER (MANDATORY) ---------- */

  Future<void> pickImage({required bool fromCamera}) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => pickedImageBytes = bytes);
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Could not pick image: $e', success: false);
      }
    }
  }

  void showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'SELECT ITEM PHOTO',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: darkSlate,
                      ),
                    ),
                  ),
                  if (!kIsWeb)
                    ListTile(
                      leading: const Icon(
                        Icons.photo_camera_rounded,
                        color: primaryIndigo,
                      ),
                      title: const Text(
                        'Take Photo (Camera)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        pickImage(fromCamera: true);
                      },
                    ),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library_rounded,
                      color: accentViolet,
                    ),
                    title: const Text(
                      'Choose from Gallery',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      pickImage(fromCamera: false);
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void removeImage() => setState(() => pickedImageBytes = null);

  /* ---------- ID DOCUMENT PICKER (UNIVERSITY ID / NID) ---------- */

  Future<void> pickIdDocument({required bool fromCamera}) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1000,
        imageQuality: 60,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      widget.store.attachDocument(bytes, file.name);
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'ID pick kora jay nai: $e', success: false);
      }
    }
  }

  void showIdSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'SELECT ID CARD PHOTO',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: darkSlate,
                      ),
                    ),
                  ),
                  if (!kIsWeb)
                    ListTile(
                      leading: const Icon(
                        Icons.photo_camera_rounded,
                        color: primaryIndigo,
                      ),
                      title: const Text(
                        'Take Photo (Camera)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        pickIdDocument(fromCamera: true);
                      },
                    ),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library_rounded,
                      color: accentViolet,
                    ),
                    title: const Text(
                      'Choose from Gallery',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      pickIdDocument(fromCamera: false);
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  /* ---------- PUBLISH ---------- */

  Future<void> publishPost() async {
    if (!formKey.currentState!.validate()) return;

    // MANDATORY IMAGE CHECK — photo chara post hobe na
    if (pickedImageBytes == null) {
      showAppMessage(
        context,
        'Item photo is MANDATORY! Please attach a photo first.',
        success: false,
      );
      return;
    }

    setState(() => isBusy = true);
    final error = await widget.store.createPost(
      itemName: itemNameController.text.trim(),
      category: category!,
      itemStatus: itemStatus,
      date: selectedDate,
      location: locationController.text.trim(),
      imageUrl: '',
      imageBytes: pickedImageBytes,
      description: descriptionController.text.trim(),
    );
    if (!mounted) return;
    setState(() => isBusy = false);

    if (error != null) {
      showAppMessage(context, error, success: false);
      return;
    }

    itemNameController.clear();
    locationController.clear();
    descriptionController.clear();
    setState(() {
      category = null;
      pickedImageBytes = null;
    });

    showAppMessage(
      context,
      'Report Submitted! Admin will review shortly.',
      success: true,
    );
    widget.onGoHome();
  }

  @override
  Widget build(BuildContext context) {
    final isVerified =
        widget.store.currentUser.identityStatus == IdentityStatus.verified;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'CREATE REPORT',
          style: TextStyle(
            color: primaryIndigo,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const Text(
          'Post Item Details',
          style: TextStyle(
            color: darkSlate,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        isVerified ? _buildForm() : _buildIdentityCard(),
      ],
    );
  }

  /* ---------- ID VERIFICATION CARD ---------- */

  Widget _buildIdentityCard() {
    final user = widget.store.currentUser;
    final isPending = user.identityStatus == IdentityStatus.pending;
    final hasDoc = user.documentPhotoBytes != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPending ? amberWarning : primaryIndigo,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isPending
                ? Icons.hourglass_top_rounded
                : Icons.verified_user_rounded,
            size: 48,
            color: isPending ? amberWarning : primaryIndigo,
          ),
          const SizedBox(height: 14),
          Text(
            isPending
                ? 'Verification Under Review'
                : 'Verify Your Identity First',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: darkSlate,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPending
                ? 'Admin is reviewing your ID card photo. Please check back soon.'
                : 'For community safety, upload a clear photo of your University ID / NID card once before posting.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          if (!isPending) ...[
            // ID PHOTO PICKER (MANDATORY)
            GestureDetector(
              onTap: showIdSourceSheet,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: bgSlate,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasDoc ? emeraldGreen : neonPink.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child:
                    hasDoc
                        ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.memory(
                                user.documentPhotoBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onPressed:
                                      () => widget.store.removeIdDocument(),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: emeraldGreen,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'ID ATTACHED ✓',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                        : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.badge_outlined,
                              size: 40,
                              color: primaryIndigo,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'ATTACH UNIVERSITY ID / NID *',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: darkSlate,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mandatory — Tap to add ID card photo',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    hasDoc
                        ? () {
                          widget.store.submitIdentityRequest();
                          showAppMessage(
                            context,
                            'Sent to Admin for review!',
                            success: true,
                          );
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'SUBMIT FOR REVIEW',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /* ---------- ITEM POST FORM ---------- */

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _statusSelector(
                    'Lost',
                    Icons.search_rounded,
                    neonPink,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statusSelector(
                    'Found',
                    Icons.check_circle_outline,
                    emeraldGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---------- MANDATORY ITEM PHOTO ----------
            GestureDetector(
              onTap: showImageSourceSheet,
              child: Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: bgSlate,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        pickedImageBytes == null
                            ? neonPink.withOpacity(0.5)
                            : emeraldGreen,
                    width: 1.5,
                  ),
                ),
                child:
                    pickedImageBytes == null
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.add_a_photo_rounded,
                              size: 40,
                              color: primaryIndigo,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'ATTACH ITEM PHOTO *',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: darkSlate,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mandatory — Tap to add photo',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        )
                        : Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.memory(
                                pickedImageBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onPressed: removeImage,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: emeraldGreen,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'PHOTO ATTACHED ✓',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: itemNameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items:
                  [
                        'Electronics',
                        'Wallets/Bags',
                        'Documents',
                        'Accessories',
                        'Other',
                      ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (v) => setState(() => category = v),
              validator: (v) => v == null ? 'Select category' : null,
            ),
            const SizedBox(height: 14),

            // DATE PICKER FIELD
            InkWell(
              onTap: chooseDate,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date (When lost or found?)',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                child: Text(
                  formatDate(selectedDate),
                  style: const TextStyle(
                    color: darkSlate,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description / Details',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isBusy ? null : publishPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child:
                    isBusy
                        ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                        : const Text(
                          'PUBLISH ITEM POST',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusSelector(String status, IconData icon, Color color) {
    final isSelected = itemStatus == status;
    return GestureDetector(
      onTap: () => setState(() => itemStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 18),
            const SizedBox(width: 6),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

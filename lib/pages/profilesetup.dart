// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:josephs_vs_01/management/database.dart' show DatabaseManager;
import 'package:path_provider/path_provider.dart';

import 'package:josephs_vs_01/components/mybutton.dart';
import 'package:josephs_vs_01/components/mytextformfield.dart';
import 'package:josephs_vs_01/pages/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetUpProfile extends StatefulWidget {
  const SetUpProfile({super.key});

  @override
  State<SetUpProfile> createState() => _SetUpProfileState();
}

class _SetUpProfileState extends State<SetUpProfile> {
  // controllers
  final TextEditingController fnameController = TextEditingController();
  final TextEditingController lnameController = TextEditingController();

  // db
  final DatabaseManager _db = DatabaseManager();

  // image picker
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  bool _saving = false;
  bool _picking = false;

  // ----------------------------
  // PICK + CROP IMAGE
  // ----------------------------
  Future<void> _pickAndCrop(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (picked == null) return;

      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xff050c20),
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: true),
        ],
      );

      if (cropped == null) return;

      setState(() {
        _profileImage = File(cropped.path);
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  // ----------------------------
  // SAVE IMAGE TO APP DIRECTORY
  // ----------------------------
  Future<String> _persistImageToAppDir(File imageFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = "pp_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final saved = File("${dir.path}/$fileName");

    // safer on iOS release: write bytes
    final bytes = await imageFile.readAsBytes();
    await saved.writeAsBytes(bytes, flush: true);

    return saved.path;
  }

  // -------------------------------------------
  // SAVE PROFILE TO DATABASE + PUSH DASHBOARD
  // -------------------------------------------
  Future<void> _saveProfile() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final fname = fnameController.text.trim();
      final lname = lnameController.text.trim();

      if (fname.isEmpty || lname.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter first and last name."),
            backgroundColor: Color(0xff050c20),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // optional: require picture
      // if (_profileImage == null) { ... }

      // save image locally
      String photoPath = '';
      if (_profileImage != null) {
        photoPath = await _persistImageToAppDir(_profileImage!);
      }

      // save user in sqlite
      await _db.updateLocalUser(
        fname: fname,
        lname: lname,
        photoPath: photoPath,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not save profile.\n$e"),
          backgroundColor: const Color(0xff050c20),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ----------------------------
  // SOURCE PICKER SHEET
  // ----------------------------
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            _sourceTile(
              icon: CupertinoIcons.photo,
              text: 'Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickAndCrop(ImageSource.gallery);
              },
            ),
            _sourceTile(
              icon: CupertinoIcons.camera,
              text: 'Camera',
              onTap: () {
                Navigator.pop(context);
                _pickAndCrop(ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _sourceTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xff050c20)),
      title: Text(text),
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    fnameController.dispose();
    lnameController.dispose();
    super.dispose();
  }

  // ----------------------------
  // UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile Set Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // PROFILE IMAGE
            GestureDetector(
              onTap: _showImageSourcePicker,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : null,
                child: _profileImage == null
                    ? const Icon(
                        CupertinoIcons.camera,
                        size: 30,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 30),

            Mytextformfield(
              controller: fnameController,
              hintText: "First Name",
              leadingIcon: const Icon(
                CupertinoIcons.person_fill,
                color: Color(0xff050c20),
              ),
            ),

            const SizedBox(height: 20),

            Mytextformfield(
              controller: lnameController,
              hintText: "Last Name",
              leadingIcon: const Icon(
                CupertinoIcons.person_fill,
                color: Color(0xff050c20),
              ),
            ),

            const SizedBox(height: 30),

            MyButton(
              text: _saving ? "Saving..." : "Save Profile",
              onPressed: _saving ? () {} : _saveProfile,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:josephs_vs_01/management/database.dart';
import 'package:josephs_vs_01/components/mybutton.dart';
import 'package:josephs_vs_01/components/mytextformfield.dart';
import 'package:josephs_vs_01/pages/dashboard.dart';

class SetUpProfile extends StatefulWidget {
  const SetUpProfile({super.key});

  @override
  State<SetUpProfile> createState() => _SetUpProfileState();
}

class _SetUpProfileState extends State<SetUpProfile> {
  final fnameController = TextEditingController();
  final lnameController = TextEditingController();

  final DatabaseManager _db = DatabaseManager();
  final ImagePicker _picker = ImagePicker();

  File? _profileImage;
  bool _saving = false;

  static const Color _primaryColor = Color(0xff050c20);
  static const Color _bgColor = Colors.white;
  static const Color _textColor = Color(0xff050c20);
  static const Color _borderColor = Color(0x33050c20);

  Future<void> _onChangePhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  CupertinoIcons.camera,
                  color: _primaryColor,
                ),
                title: const Text(
                  "Camera",
                  style: TextStyle(color: _textColor),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await _pickAndCrop(ImageSource.camera);
                  if (file != null) {
                    setState(() {
                      _profileImage = file;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.photo, color: _primaryColor),
                title: const Text(
                  "Gallery",
                  style: TextStyle(color: _textColor),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await _pickAndCrop(ImageSource.gallery);
                  if (file != null) {
                    setState(() {
                      _profileImage = file;
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

  Future<File?> _pickAndCrop(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);

    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          lockAspectRatio: true,
          toolbarTitle: 'Crop Photo',
          toolbarColor: _primaryColor,
          toolbarWidgetColor: Colors.white,
          statusBarColor: _primaryColor,
          backgroundColor: Colors.white,
        ),
        IOSUiSettings(aspectRatioLockEnabled: true, title: 'Crop Photo'),
      ],
    );

    if (cropped == null) return null;

    return File(cropped.path);
  }

  Future<String> _persistImage(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = "${dir.path}/pp_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final saved = File(path);

    await saved.writeAsBytes(await file.readAsBytes(), flush: true);
    return saved.path;
  }

  Future<void> _saveProfile() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    final fname = fnameController.text.trim();
    final lname = lnameController.text.trim();

    if (fname.isEmpty || lname.isEmpty) {
      setState(() {
        _saving = false;
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: _bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Missing information",
            style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Please enter your first name and last name.",
            style: TextStyle(color: _textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OK",
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    String photoPath = '';

    if (_profileImage != null) {
      photoPath = await _persistImage(_profileImage!);
    }

    await _db.updateLocalUser(fname: fname, lname: lname, photoPath: photoPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    await prefs.setBool('hasCompletedProfile', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Dashboard()),
    );
  }

  @override
  void dispose() {
    fnameController.dispose();
    lnameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _bgColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: _bgColor,
          foregroundColor: _textColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: _bgColor,
          surfaceTintColor: Colors.transparent,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: _bgColor,
          surfaceTintColor: Colors.transparent,
        ),
        colorScheme: const ColorScheme.light(
          primary: _primaryColor,
          surface: _bgColor,
          onSurface: _textColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            "Profile Setup",
            style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              GestureDetector(
                onTap: _onChangePhoto,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xfff4f4f4),
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : null,
                  child: _profileImage == null
                      ? const Icon(
                          CupertinoIcons.camera,
                          size: 30,
                          color: _primaryColor,
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                "Add a profile photo",
                style: TextStyle(
                  color: _textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 30),

              Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.white,
                    hintStyle: const TextStyle(color: Colors.black54),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primaryColor),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Mytextformfield(
                      controller: fnameController,
                      hintText: "First Name",
                    ),

                    const SizedBox(height: 20),

                    Mytextformfield(
                      controller: lnameController,
                      hintText: "Last Name",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              MyButton(
                text: _saving ? "Saving..." : "Save Profile",
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

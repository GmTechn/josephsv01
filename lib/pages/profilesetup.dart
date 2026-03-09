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

  // ----------------------------
  // PHOTO PICKER
  // ----------------------------

  Future<void> _onChangePhoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(CupertinoIcons.camera),
                title: const Text("Camera"),
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
                leading: const Icon(CupertinoIcons.photo),
                title: const Text("Gallery"),
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
        AndroidUiSettings(lockAspectRatio: true),
        IOSUiSettings(aspectRatioLockEnabled: true),
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

  // ----------------------------
  // SAVE PROFILE
  // ----------------------------

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

  // ----------------------------
  // UI
  // ----------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile Setup")),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            /// PHOTO
            GestureDetector(
              onTap: _onChangePhoto,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : null,
                child: _profileImage == null
                    ? const Icon(CupertinoIcons.camera, size: 30)
                    : null,
              ),
            ),

            const SizedBox(height: 30),

            /// FIRST NAME
            Mytextformfield(
              controller: fnameController,
              hintText: "First Name",
            ),

            const SizedBox(height: 20),

            /// LAST NAME
            Mytextformfield(controller: lnameController, hintText: "Last Name"),

            const SizedBox(height: 30),

            /// SAVE BUTTON
            MyButton(
              text: _saving ? "Saving..." : "Save Profile",
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
    );
  }
}

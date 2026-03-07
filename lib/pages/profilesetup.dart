// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:josephs_vs_01/components/mybutton.dart';
import 'package:josephs_vs_01/components/mytextformfield.dart';
import 'package:josephs_vs_01/pages/dashboard.dart';
import 'package:josephs_vs_01/management/database.dart';

class SetUpProfile extends StatefulWidget {
  const SetUpProfile({super.key});

  @override
  State<SetUpProfile> createState() => _SetUpProfileState();
}

class _SetUpProfileState extends State<SetUpProfile> {
  final fnameController = TextEditingController();
  final lnameController = TextEditingController();

  final DatabaseManager _db = DatabaseManager();

  bool _saving = false;

  Future<void> _saveProfile() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    final fname = fnameController.text.trim();
    final lname = lnameController.text.trim();

    if (fname.isEmpty || lname.isEmpty) return;

    await _db.updateLocalUser(fname: fname, lname: lname, photoPath: '');

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile Setup")),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            Mytextformfield(
              controller: fnameController,
              hintText: "First Name",
            ),

            const SizedBox(height: 20),

            Mytextformfield(controller: lnameController, hintText: "Last Name"),

            const SizedBox(height: 30),

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

import 'package:flutter/material.dart';

class AdminModeratorsScreen extends StatefulWidget {
  const AdminModeratorsScreen({Key? key}) : super(key: key);

  @override
  State<AdminModeratorsScreen> createState() =>
      _AdminModeratorsScreenState();
}

class _AdminModeratorsScreenState
    extends State<AdminModeratorsScreen> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Admin Moderators Screen',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
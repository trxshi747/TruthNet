import 'package:flutter/material.dart';

class AdminRoleScreen extends StatefulWidget {
  const AdminRoleScreen({Key? key}) : super(key: key);

  @override
  State<AdminRoleScreen> createState() => _AdminRoleScreenState();
}

class _AdminRoleScreenState extends State<AdminRoleScreen> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Admin Role Screen',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFFFFCC33),
      ),
      body: const Center(
        child: Text(
          'No new notifications',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class OnProgressScreen extends StatelessWidget {
  const OnProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('On Progress')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Placeholder for image
            SizedBox(
              width: double.infinity,
              height: 200,
              child: const Center(
                child: Image(image: AssetImage('assets/images/onprogress.jpg')),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'This activity is currently in progress.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check back later for updates.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

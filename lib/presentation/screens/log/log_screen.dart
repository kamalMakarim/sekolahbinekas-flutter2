import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sekolahbinekas/data/user_database.dart';
import './log_logic.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  _LogScreenState createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final TextEditingController _textController = TextEditingController();
  List<File> _selectedImages = [];
  List<File> _selectedFiles = [];
  bool _isUploading = false;

  Future<void> _pickImages() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
    );
    if (result.isNotEmpty) {
      final paths = result.map((file) => file.path).whereType<String>().toList();
      setState(() {
        _selectedImages = paths.map((p) => File(p)).toList();
      });
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
    );

    // Check for files larger than 10MB
    if (result.isNotEmpty) {
      final paths = result.map((file) => file.path).whereType<String>().toList();
      final tooLarge = paths.any((file) => File(file).lengthSync() > 10 * 1024 * 1024);
      if (tooLarge) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size must be less than 10MB.')),
        );
        setState(() {
          _selectedFiles.clear();
        });
        return;
      }
      setState(() {
        _selectedFiles = paths.map((path) => File(path)).toList();
      });
    }
  }

  Future<void> sendLog() async {
    if (_textController.text.trim().isEmpty && _selectedImages.isEmpty && _selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter text or select images or files')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final log = await LogLogic().sendLog(
        text: _textController.text.trim(),
        images: _selectedImages,
        files: _selectedFiles,
        className: await UserDatabase().getCurrentUserClassName()
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Log sent successfully: ${log.id}')),
      );

      setState(() {
        _textController.clear();
        _selectedImages.clear();
        _selectedFiles.clear();
      });
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending log: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Log')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textController,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Write your text here...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            if (_selectedImages.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedImages
                    .map((img) => Image.file(img, width: 100, height: 100, fit: BoxFit.cover))
                    .toList(),
              ),
            SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: Icon(Icons.image, color: Colors.blue),
                  label: Text('Add Images', selectionColor: Colors.blue,),
                ),
                ElevatedButton.icon(
                  onPressed: _pickFiles,
                  icon: Icon(Icons.attach_file, color: Colors.blue),
                  label: Text('Add Files', selectionColor: Colors.blue,),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : sendLog,
                  icon: _isUploading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.upload, color: Colors.blue,),
                  label: Text(_isUploading ? 'Sending...' : 'Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

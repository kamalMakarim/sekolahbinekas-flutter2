import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sekolahbinekas/data/user_database.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageDatabase {
  final String url = 'https://zipline.bukom.sekolahbinekas.com';

  Future<List<String>> uploadImages(List<File> files) async {
    List<String> uploadedUrls = [];
    try {
      if (files.isEmpty) return uploadedUrls;
      // Compress and convert to JPEG before uploading
      List<File> compressedFiles = await Future.wait(
        files.map((file) async {
          final bytes = await file.readAsBytes();

          // Get a temporary file path
          final tempDir = await getTemporaryDirectory();
          final targetPath =
              "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";

          // Compress & convert to JPEG
          final compressedBytes = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: 800,
            minHeight: 800,
            quality: 80,
            format: CompressFormat.jpeg, // Force JPEG output
          );

          // Save the compressed bytes as a file
          final compressedFile = File(targetPath)
            ..writeAsBytesSync(compressedBytes);
          return compressedFile;
        }),
      );
      uploadedUrls = await uploadFiles(compressedFiles);
    } catch (e) {
      print('Error uploading file: $e');
    }
    return uploadedUrls;
  }

  Future<List<String>> uploadFiles(List<File> files) async {
    List<String> uploadedUrls = [];
    try {
      if (files.isEmpty) return uploadedUrls;
      final userToken = await UserDatabase().getCurrentUserZiplineToken();
      final uri = Uri.parse('$url/api/upload');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = '$userToken'
        ..files.addAll(
          await Future.wait(
            files.map((f) => http.MultipartFile.fromPath('file', f.path)),
          ),
        );

      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(respStr);

        if (jsonResponse['files'] != null) {
          for (var file in jsonResponse['files']) {
            if (file['url'] != null) {
              uploadedUrls.add(file['url']);
            }
          }
        }
      } else {
        print('Failed to upload file: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading file: $e');
    }
    return uploadedUrls;
  }

  Future<bool> register(String email, String password) async {
    final client = http.Client();
    try {
      final responseRegister = await client.post(
        Uri.parse("$url/api/auth/register"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': password}),
      );
      if (responseRegister.statusCode != 200) {
        print('Failed to register: ${responseRegister.statusCode} - ${responseRegister.body}');
        return false;
      }
        final response = await client.post(
        Uri.parse("$url/api/auth/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        // get upload token
        final cookie = response.headers['set-cookie'];
        final uploadToken = await client.get(
          Uri.parse("$url/api/user/token"),
          headers: {'Content-Type': 'application/json', 'Cookie': cookie ?? ''},
        );
        print('cookie: $cookie');
        print('Upload token response: ${uploadToken.statusCode} - ${uploadToken.body}');

        // save token to database
        final supabase = Supabase.instance.client;
        final authUser = supabase.auth.currentUser;
        if (authUser != null) {
          await supabase.from('user_zipline_tokens').upsert({
            'auth_id': authUser.id,
            'zipline_token': jsonDecode(uploadToken.body)['token'],
          });
          await UserDatabase().getCurrentUserData(forceRefresh: true);
        }
        return true;
      } else {
        print('Failed to register: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during registration: $e');
    }
    return false;
  }

  Future<bool> deleteImage(List<String> imageUrls) async {
    final client = http.Client();

    //get file name from url last part after last /
    List<String> fileNames = imageUrls
        .map((url) => url.split('/').last)
        .toList();

    // loop through file names and delete each
    try {
      final userToken = await UserDatabase().getCurrentUserZiplineToken();
      for (String fileName in fileNames) {
        final uri = Uri.parse("$url/api/user/files/$fileName" );
        final response = await client.delete(
          uri,
          headers: {'Authorization': '$userToken'},
        );
        if (response.statusCode == 200) {
          print('Deleted file $fileName successfully');
        } else {
          print('Failed to delete file $fileName: ${response.statusCode}');
        }
      }
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  Future<bool> deleteFile(List<String> fileUrls) async {
    final client = http.Client();

    //get file name from url last part after last /
    List<String> fileNames = fileUrls
        .map((url) => url.split('/').last)
        .toList();

    // loop through file names and delete each
    try {
      final userToken = await UserDatabase().getCurrentUserZiplineToken();
      for (String fileName in fileNames) {
        final uri = Uri.parse('$url/api/user/files/$fileName');
        final response = await client.delete(
          uri,
          headers: {'Authorization': '$userToken'},
        );
        if (response.statusCode == 200) {
          print('Deleted file $fileName successfully');
        } else {
          print('Failed to delete file $fileName: ${response.statusCode}');
        }
      }
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
}

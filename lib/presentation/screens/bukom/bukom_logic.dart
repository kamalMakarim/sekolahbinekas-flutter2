import 'package:sekolahbinekas/data/message_database.dart';
import 'package:sekolahbinekas/data/student_database.dart';
import 'package:sekolahbinekas/data/unread_count_database.dart';
import 'package:sekolahbinekas/data/user_database.dart';
import 'package:sekolahbinekas/models/read_check.dart';
import 'package:sekolahbinekas/models/student.dart';
import 'package:sekolahbinekas/models/message.dart';
import 'dart:io';
import 'package:sekolahbinekas/data/image_database.dart';
import 'package:sekolahbinekas/models/unread_count.dart';
import 'package:sekolahbinekas/data/read_check_database.dart';

class BukomLogic {
  Future<({List<Student> students, Student currentStudent, List<UnreadCount> unreadCounts})> loadData() async {
    final students = await StudentDatabase().getAllStudents();
    final unreadCount = await UnreadCountDatabase().getAllofUser();
    if (students.isEmpty) {
      throw Exception("No students found");
    }

    final currentStudent = students.first;

    return (students: students, currentStudent: currentStudent, unreadCounts: unreadCount);
  }

  Future<Message> sendMessage({
    required String text,
    required String studentId,
    required List<File> images,
    required List<File> files,
  }) async {
    // Upload images to Zipline first
    List<String> imageUrls = await ImageDatabase().uploadImages(images);
    // Upload files to Zipline
    List<String> fileUrls = await ImageDatabase().uploadFiles(files);

    // Save message with text + image URLs
    Message message = await MessageDatabase().addMessage(
      text,
      studentId,
      imageUrls,
      fileUrls,
    );

    message.displayName = await UserDatabase().getCurrentUserDisplayName();
    message.profilePicture = await UserDatabase()
        .getCurrentUserProfilePicture();
    return message;
  }

  DateTime? lastLoadedTimestamp;
  List<Message> cachedMessages = [];

  Future<List<Message>> loadMessages(String studentId, DateTime before) async {
    // If the timestamp is the same as the last one, skip DB call
    if (lastLoadedTimestamp != null && lastLoadedTimestamp == before) {
      print("Skipping fetch, already loaded for $before");
      return cachedMessages;
    }

    // Otherwise, fetch from DB
    final messages = await MessageDatabase().getMessagesByStudentId(
      studentId,
      before: before,
    );

    await UnreadCountDatabase().setCountToZeroByStudent(studentId);

    // Update cache
    lastLoadedTimestamp = before;
    cachedMessages = messages;

    return messages;
  }

  Future<void> deleteMessage(
    String messageId,
    String messageType,
    String? logId,
    List<String>? imageUrls,
    List<String>? fileUrls,
  ) async {
    try {
      await MessageDatabase().deleteMessage(messageId, messageType, logId);
      await ImageDatabase().deleteImage(imageUrls ?? []);
      await ImageDatabase().deleteFile(fileUrls ?? []);
    } catch (e, stack) {
      print('Error deleting message $messageId: $e\n$stack');
      rethrow;
    }
  }

  Future<List<ReadCheck>> getReadChecksForMessage(String messageId) async {
    final result =await ReadCheckDatabase().getReadCheck(messageId);
    print('Fetched ${result.map((e) => e.display_name).toList().length} read checks for message $messageId');

    return result;
  }
}

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sekolahbinekas/models/tingkat_classes.dart';
import 'package:sekolahbinekas/models/unread_count.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sekolahbinekas/models/student.dart';
import 'package:sekolahbinekas/models/message.dart';
import 'bukom_bs_logic.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:textf/textf.dart';
class BukomBsScreen extends StatefulWidget {
  const BukomBsScreen({super.key, this.kelas});
  final TingkatClasses? kelas;
  @override
  _BukomBsScreenState createState() => _BukomBsScreenState(kelas);
}

class _BukomBsScreenState extends State<BukomBsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  List<Student>? students;
  List<UnreadCount>? unreadCounts;
  final TingkatClasses? kelas;
  _BukomBsScreenState(this.kelas);
  Student? currentStudent;
  List<Message>? messages;
  List<File> _selectedImages = [];
  List<File> _selectedFiles = [];
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    _initPage();

    _scrollController.addListener(() {
      // Lazy load trigger: when reaching near top
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        _loadOlderMessages();
      }
    });

    FirebaseMessaging.onMessage.listen((payload) {
      final notification = payload.notification;
      if (notification != null) {
        final title = notification.title ?? '';
        if (currentStudent != null && title.contains(currentStudent!.name)) {
          loadMessages();
        }
      }
    });
  }

  Future<void> loadMessages() async {
    if (currentStudent != null) {
      final newMessages = await BukomBsLogic().loadMessages(
        currentStudent!.id,
        DateTime.now(),
      );
      setState(() {
        // Merge newly loaded messages into existing list (avoid duplicates) and sort newest first.
        final existing = messages ?? [];
        final merged = List<Message>.from(existing);

        final existingIds = existing.map((m) => m.id).toSet();
        for (final m in newMessages) {
          if (!existingIds.contains(m.id)) {
            merged.add(m);
            existingIds.add(m.id);
          }
        }
        merged.sort(
          (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );
        messages = merged;
      });
    }
  }

  Future<void> _onStudentChanged(Student? student) async {
    if (student != null) {
      // Load messages for the selected student
      List<Message> newMessage = await BukomBsLogic().loadMessages(
        student.id,
        DateTime.now(),
      );
      setState(() {
        currentStudent = student;
        messages = newMessage;
        unreadCounts?.removeWhere((uc) => uc.studentId == student.id);
        _controller.clear();
        _selectedImages.clear();
        _selectedFiles.clear();
      });
    }
  }

  Future<void> _initPage() async {
    try {
      final data = await BukomBsLogic().loadData(kelas);
      setState(() {
        students = data.students;
        currentStudent = data.currentStudent;
        unreadCounts = data.unreadCounts;
      });
      await loadMessages();

      // Delay so UI builds first
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print("Error loading data: $e");
    }
  }

  Future<void> _loadOlderMessages() async {
    if (currentStudent != null && messages != null && messages!.isNotEmpty) {
      final older = await BukomBsLogic().loadMessages(
        currentStudent!.id,
        messages!.last.createdAt ?? DateTime.now(),
      );
      setState(() {
        //remove duplicates
        final existingIds = messages!.map((m) => m.id).toSet();
        messages!.addAll(older.where((m) => !existingIds.contains(m.id)));
        messages!.sort(
          (a, b) => b.createdAt!.compareTo(a.createdAt!),
        ); // sort by newest first
      });
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.minScrollExtent, // for reversed ListView
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
    );
    if (result.isNotEmpty) {
      final paths = result.map((file) => file.path).whereType<String>().toList();
      setState(() {
        _selectedImages = paths.map((path) => File(path)).toList();
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

  Future<void> showReadReceipts(String messageId) async {
    try {
      final readChecks = await BukomBsLogic().getReadChecksForMessage(
        messageId,
      );

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Read By'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: readChecks.length,
                itemBuilder: (context, index) {
                  final rc = readChecks[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        rc.profile_picture ??
                            'https://zipline.bukom.sekolahbinekas.com/u/5ldroU.jpg',
                      ),
                    ),
                    title: Text(rc.display_name),
                    subtitle: Text(
                      '${rc.createdAt.toLocal().day}/${rc.createdAt.toLocal().month} '
                      '${rc.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${rc.createdAt.toLocal().minute.toString().padLeft(2, '0')}',
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error fetching read receipts: $e');
    }
  }

  Future<void> downloadFile(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not download file')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error downloading file')));
    }
  }

  Future<void> showImagePopup(BuildContext context, String url) async {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: InteractiveViewer(child: Image.network(url)),
              ),
              Positioned(
                bottom: 20,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const SizedBox.shrink(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    shape: const CircleBorder(),
                    elevation: 0,
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: () async {
                    try {
                      // Download image
                      final response = await http.get(Uri.parse(url));
                      final bytes = Uint8List.fromList(response.bodyBytes);

                      // Extract filename
                      final filename = url.split('/').last.split('?').first;

                      // Save to gallery
                      await FilePicker.saveFile(
                        bytes: bytes,
                        fileName: filename,
                      );

                      Navigator.pop(context); // Close popup
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Image saved to Gallery")),
                      );
                    } catch (e) {
                      debugPrint('Error saving: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Error saving image, make sure to grant storage permission.",
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty &&
        _selectedImages.isEmpty &&
        _selectedFiles.isEmpty)
      return;
    FocusScope.of(context).unfocus();

    try {
      setState(() {
        isSending = true;
      });
      // Send text + images to BukomBsLogic
      final newMessage = await BukomBsLogic().sendMessage(
        text: _controller.text.trim(),
        studentId: currentStudent?.id ?? '',
        images: _selectedImages,
        files: _selectedFiles,
      );

      setState(() {
        messages?.insert(0, newMessage); // because reverse:true
        _controller.clear();
        _selectedImages.clear();
        _selectedFiles.clear();
        isSending = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (error) {
      print('Error sending message: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: DropdownButton<Student>(
          isExpanded: true,
          value: currentStudent,
          underline: SizedBox(),
          dropdownColor: Colors.blue,
          borderRadius: BorderRadius.circular(10),
          items: (students ?? []).map((student) {
            return DropdownMenuItem(
              value: student,
              child: Row(
                children: [
                  Text(student.name, style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 8),
                  if (unreadCounts != null)
                    ...unreadCounts!
                        .where(
                          (uc) => uc.studentId == student.id && uc.count > 0,
                        )
                        .map(
                          (uc) => Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              uc.count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) async {
            await _onStudentChanged(value);
          },
        ),
      ),
      body: Container(
        color: Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.only(top: 0, left: 5, right: 5),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages?.length ?? 0,
                  itemBuilder: (context, index) {
                    final msg = messages?[index];
                    final isMe =
                        msg?.senderId ==
                        Supabase.instance.client.auth.currentUser?.id;

                    // Use default avatar if profilePicture is null or empty
                    final profilePicUrl =
                        (msg?.profilePicture != null &&
                            msg!.profilePicture!.isNotEmpty)
                        ? msg.profilePicture!
                        : 'https://zipline.bukom.sekolahbinekas.com/u/5ldroU.jpg'; // default

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe) // Show avatar on the left for received messages
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(profilePicUrl),
                              ),
                            ),
                          GestureDetector(
                            onLongPress: () {
                              final m = msg;
                              if (m == null) return;
                              showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isMe)
                                          ListTile(
                                            leading: Icon(Icons.delete),
                                            title: Text('Delete'),
                                            onTap: () async {
                                              Navigator.pop(context);
                                              final confirm =
                                                  await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        title: Text(
                                                          'Delete message',
                                                        ),
                                                        content: Text(
                                                          'Are you sure you want to delete this message?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  false,
                                                                ),
                                                            child: Text(
                                                              'Cancel',
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  true,
                                                                ),
                                                            child: Text(
                                                              'Delete',
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                              if (confirm != true) return;

                                              try {
                                                // Attempt backend delete if available; ignore errors but remove locally on success
                                                try {
                                                  await BukomBsLogic()
                                                      .deleteMessage(
                                                        m.id,
                                                        m.messageType,
                                                        m.logId,
                                                        m.images,
                                                        m.files,
                                                      );
                                                } catch (_) {
                                                  print(
                                                    "Server failed to delete",
                                                  );
                                                }
                                                setState(() {
                                                  messages?.removeWhere(
                                                    (x) => x.id == m.id,
                                                  );
                                                });
                                                if (!mounted) return;
                                              } catch (e) {
                                                print(
                                                  'Error deleting message: $e',
                                                );
                                              }
                                            },
                                          ),

                                        ListTile(
                                          leading: Icon(Icons.copy),
                                          title: Text('Copy Text'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            if (msg?.message != null) {
                                              Clipboard.setData(
                                                ClipboardData(
                                                  text: msg!.message,
                                                ),
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Message copied to clipboard',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(Icons.visibility),
                                          title: Text('Read By'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            showReadReceipts(msg!.id);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 3,
                              ),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.green[100] : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withAlpha(77),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (msg?.displayName != null)
                                    Text(
                                      msg!.displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  SizedBox(height: 4),
                                  if (msg?.images != null &&
                                      msg!.images!.isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: msg.images!.map((url) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ), // space between images
                                          child: GestureDetector(
                                            onTap: () =>
                                                showImagePopup(context, url),
                                            child: Image.network(
                                              url,
                                              width: 250,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  if (msg?.files != null &&
                                      msg!.files!.isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: msg.files!.map((fileUrl) {
                                        print(fileUrl);
                                        final fileName = Uri.decodeComponent(
                                          fileUrl
                                              .split('/')
                                              .last
                                              .split('?')
                                              .first,
                                        );
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: GestureDetector(
                                            onTap: () async {
                                              await downloadFile(fileUrl);
                                            },
                                            child: Container(
                                              width: 250,
                                              padding: EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.insert_drive_file,
                                                    color: Colors.blueGrey,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      fileName,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.black87,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.download,
                                                    color: Colors.blueGrey,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),

                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                          0.7,
                                    ),
                                    child: TextfOptions(
                                      onLinkTap: (url, displayText) =>
                                          launchUrl(Uri.parse(url)),
                                      child: Textf(msg?.message ?? ''),
                                    ),
                                  ),
                                  if (msg?.createdAt != null)
                                    Text(
                                      "${msg!.createdAt!.toLocal().day}/${msg.createdAt!.toLocal().month} ${msg.createdAt!.toLocal().hour.toString().padLeft(2, '0')}:${msg.createdAt!.toLocal().minute.toString().padLeft(2, '0')}",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black54,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe) // Show avatar on the right for sent messages
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(profilePicUrl),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Divider(height: 1),
              if (_selectedImages.isNotEmpty || _selectedFiles.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._selectedImages.map(
                        (img) => Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.file(img, width: 70, height: 70),
                            ),
                          ],
                        ),
                      ),
                      ..._selectedFiles.map(
                        (file) => Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.insert_drive_file,
                                        size: 32,
                                        color: Colors.blueGrey,
                                      ),
                                      Text(
                                        file.path.split('/').last,
                                        style: TextStyle(fontSize: 10),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.attach_file, color: Colors.white),
                        onPressed: _pickFiles,
                        splashRadius: 24,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.image, color: Colors.white),
                        onPressed: _pickImages,
                        splashRadius: 24,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: isSending
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.send, color: Colors.white),
                        onPressed: isSending ? null : _sendMessage,
                        splashRadius: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

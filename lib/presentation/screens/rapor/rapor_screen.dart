import 'package:flutter/material.dart';
import 'package:sekolahbinekas/models/rapor.dart';
import 'package:sekolahbinekas/models/student.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sekolahbinekas/presentation/screens/rapor/rapor_logic.dart';

class RaporScreen extends StatefulWidget {
  const RaporScreen({super.key});

  @override
  State<RaporScreen> createState() => _RaporScreenState();
}

class _RaporScreenState extends State<RaporScreen> {
  List<Student>? students;
  Student? currentStudent;
  List<Rapor>? raporList;

  @override
  void initState() {
    super.initState();
    _initPage().then((_) => _loadRapor());
  }

  Future<void> _initPage() async {
    final data = await RaporLogic().loadData();
    setState(() {
      students = data.students;
      currentStudent = data.currentStudent;
    });
  }

  Future<void> _loadRapor() async {
    if (currentStudent != null) {
      final rapor = await RaporLogic().loadRaporForStudent(currentStudent!);
      setState(() {
        raporList = rapor;
      });
    }
  }

  Future<void> _openPdf(String pdfUrl) async {
    final uri = Uri.tryParse(pdfUrl);
    if (uri == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link PDF tidak valid')));
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal membuka file PDF')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNoData = raporList == null || raporList!.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        titleSpacing: 0,
        title: DropdownButton<Student>(
          isExpanded: true,
          value: currentStudent,
          underline: const SizedBox(),
          iconEnabledColor: Colors.white,
          dropdownColor: Colors.blue,
          borderRadius: BorderRadius.circular(10),
          items: (students ?? []).map((student) {
            return DropdownMenuItem(
              value: student,
              child: Text(
                student.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) async {
            if (value != null) {
              final newRaporList = await RaporLogic().loadRaporForStudent(
                value,
              );
              setState(() {
                currentStudent = value;
                raporList = newRaporList;
              });
            }
          },
        ),
      ),
      body: hasNoData
          ? const Center(child: Text('No rapor available'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: raporList!.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rapor = raporList![index];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openPdf(rapor.pdf),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7EEFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rapor ${rapor.tahunAjaran}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Semester: ${rapor.semester}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Icon(
                                Icons.open_in_new_rounded,
                                size: 18,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

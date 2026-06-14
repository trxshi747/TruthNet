import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:model2/core/theme/app_theme.dart';
import 'package:model2/widgets/dynamic_background.dart';
import 'package:model2/services/api_service.dart';
import 'package:model2/providers/auth_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<dynamic> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => isLoading = true);
    try {
      final fetched = await ApiService.getReports();
      if (mounted) {
        setState(() {
          reports = fetched;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleResolve(String reportId, String action, String adminId, [String? customReason]) async {
    final success = await ApiService.resolveReport(reportId, action, adminId, customReason);
    if (!mounted) return;
    
    if (success) {
      _fetchReports();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Report resolved successfully", style: GoogleFonts.spaceMono(color: AppTheme.darkPurple, fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.peach,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to resolve report", style: GoogleFonts.spaceMono(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.coral,
        ),
      );
    }
  }

  Future<void> _promptDeleteReason(String reportId, String adminId, String defaultReason) async {
    final TextEditingController controller = TextEditingController(text: defaultReason);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkPurple,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "DELETE & NOTIFY",
                style: GoogleFonts.righteous(color: AppTheme.peach, fontSize: 18),
              ),
              const SizedBox(height: 15),
              Text(
                "Specify the reason to notify the author:",
                style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                maxLines: 3,
                style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black26,
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppTheme.peach),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.peach,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _handleResolve(reportId, 'delete', adminId, controller.text.trim());
                },
                child: Text(
                  "CONFIRM DELETE",
                  style: GoogleFonts.spaceMono(
                    color: AppTheme.darkPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      }
    );
  }

  Future<void> _handleReAnalyze(String reportId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.peach))
    );

    // Update ApiService or handle the response here
    final response = await ApiService.analyzeReportTargetFullResponse(reportId);
    
    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (response['success'] == true && response['analysis'] != null) {
      final aiResult = response['analysis'];
      final tox = aiResult['toxicity'];
      final sent = aiResult['sentiment'];
      final isToxic = tox['is_toxic'] ?? false;
      final toxicScore = (tox['toxic_score'] ?? 0.0) * 100;
      final sentimentLabel = sent?['label'] ?? 'Unknown';
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkPurple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("AI ANALYSIS", style: GoogleFonts.righteous(color: AppTheme.peach)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow("Sentiment", sentimentLabel.toString().toUpperCase()),
              const SizedBox(height: 10),
              _buildInfoRow("Toxicity", isToxic ? 'TOXIC' : 'CLEAN', color: isToxic ? AppTheme.coral : Colors.green),
              const SizedBox(height: 5),
              Text("Toxicity Score: ${toxicScore.toStringAsFixed(1)}%", 
                  style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 12)),
              if (tox['flags'] != null) ...[
                 const SizedBox(height: 10),
                 Text("Flags:", style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 10)),
                 ...(tox['flags'] as Map<String, dynamic>).entries.where((e) => e.value > 0.1).map((e) => 
                    Text("• ${e.key}: ${(e.value * 100).toStringAsFixed(0)}%", 
                        style: GoogleFonts.spaceMono(color: e.value > 0.4 ? AppTheme.coral : Colors.white38, fontSize: 10))
                 ).toList(),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CLOSE", style: GoogleFonts.spaceMono(color: Colors.white)),
            )
          ],
        )
      );
    } else {
      final errorMsg = response['message'] ?? "AI Analysis failed";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg, style: GoogleFonts.spaceMono()), 
          backgroundColor: AppTheme.coral
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$label:", style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 12)),
        Text(value, style: GoogleFonts.spaceMono(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceMono(color: color, fontSize: 10),
        ),
      ),
    );
  }

  Widget _reportTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.coral.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.coral.withOpacity(0.5)),
      ),
      child: Text(
        type.toUpperCase(),
        style: GoogleFonts.spaceMono(
          color: AppTheme.coral,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentAdminId = auth.user?.id ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Reports Dashboard", style: GoogleFonts.righteous(color: AppTheme.peach)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.peach),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.peach),
            onPressed: _fetchReports,
          ),
        ],
      ),
      body: DynamicBackground(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.peach))
            : reports.isEmpty
                ? Center(child: Text("No pending reports.", style: GoogleFonts.spaceMono(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final r = reports[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppTheme.mediumPurple.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Reported by @${r['reporterName'] ?? 'unknown'}",
                                        style: GoogleFonts.righteous(
                                          color: AppTheme.peach,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (r['timestamp'] != null)
                                        Text(
                                          DateTime.fromMillisecondsSinceEpoch(r['timestamp']).toString().substring(0, 16),
                                          style: GoogleFonts.spaceMono(color: Colors.white30, fontSize: 10),
                                        ),
                                    ],
                                  ),
                                ),
                                _reportTypeBadge(r['targetType'] ?? 'Unknown'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Author: @${r['authorName'] ?? 'unknown'}",
                              style: GoogleFonts.spaceMono(color: AppTheme.coral, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                r['targetContent'] == null || r['targetContent'].isEmpty 
                                    ? "[NO_CONTENT_OR_MEDIA_ONLY]" 
                                    : "\"${r['targetContent']}\"",
                                style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.peach.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, color: AppTheme.peach, size: 14),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Reason:",
                                        style: GoogleFonts.spaceMono(
                                          color: AppTheme.peach,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 22),
                                    child: Text(
                                      r['reason'] ?? "No reason provided",
                                      style: GoogleFonts.spaceMono(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _actionButton(
                                  'ANALYZE',
                                  Colors.blue,
                                  () => _handleReAnalyze(r['id']),
                                ),
                                _actionButton(
                                  'DISMISS',
                                  Colors.grey,
                                  () => _handleResolve(r['id'], 'dismiss', currentAdminId),
                                ),
                                _actionButton(
                                  'DELETE CONTENT',
                                  Colors.redAccent,
                                  () => _promptDeleteReason(r['id'], currentAdminId, r['reason'] ?? 'Violation of rules'),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

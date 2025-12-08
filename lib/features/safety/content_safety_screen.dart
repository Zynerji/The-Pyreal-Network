import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/safety/content_safety.dart';
import '../../shared/widgets/polished_widgets.dart';
import '../hub/providers/integrated_providers.dart';

/// Content Safety Dashboard
/// Scan uploads for CSAM and inappropriate content with real-time results
class ContentSafetyScreen extends ConsumerStatefulWidget {
  const ContentSafetyScreen({super.key});

  @override
  ConsumerState<ContentSafetyScreen> createState() => _ContentSafetyScreenState();
}

class _ContentSafetyScreenState extends ConsumerState<ContentSafetyScreen> {
  List<ScanResult> _scanHistory = [];
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    final error = ref.watch(errorProvider);
    final successMessage = ref.watch(successMessageProvider);

    // Show snackbars for errors and success
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showErrorSnackbar(context, error);
        ref.read(errorProvider.notifier).state = null;
      });
    }

    if (successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showSuccessSnackbar(context, successMessage);
        ref.read(successMessageProvider.notifier).state = null;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Safety'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showSafetyInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildUploadSection(isLoading || _isScanning),
          Expanded(
            child: _buildScanHistory(),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection(bool isLoading) {
    return AnimatedCard(
      padding: const EdgeInsets.all(20),
      color: Colors.blueGrey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.shield, color: Colors.blue, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Content for Scanning',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'All uploads are automatically scanned for safety',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PremiumButton(
                  text: 'Scan Image',
                  icon: Icons.image,
                  isLoading: isLoading && _scanHistory.isEmpty,
                  gradientColors: const [Color(0xFF2196F3), Color(0xFF1976D2)],
                  onPressed: () => _scanFile('image'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PremiumButton(
                  text: 'Scan Video',
                  icon: Icons.video_library,
                  isLoading: isLoading && _scanHistory.isNotEmpty,
                  gradientColors: const [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                  onPressed: () => _scanFile('video'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PremiumButton(
            text: 'Scan Text/URL',
            icon: Icons.link,
            gradientColors: const [Color(0xFF00BCD4), Color(0xFF0097A7)],
            onPressed: _scanText,
          ),
        ],
      ),
    );
  }

  Widget _buildScanHistory() {
    if (_scanHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user,
              size: 80,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              'No scans yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload content to scan for safety',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _scanHistory.length,
        itemBuilder: (context, index) {
          final result = _scanHistory[_scanHistory.length - 1 - index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildScanResultCard(result),
          );
        },
      ),
    );
  }

  Widget _buildScanResultCard(ScanResult result) {
    final isSafe = result.isSafe;
    final color = isSafe ? Colors.green : Colors.red;

    return AnimatedCard(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.5), width: 2),
                ),
                child: Icon(
                  isSafe ? Icons.check_circle : Icons.warning,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSafe ? 'Content Safe' : 'Content Flagged',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      result.contentType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Risk: ${(result.riskScore * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getRiskColor(result.riskScore),
                    ),
                  ),
                  Text(
                    result.scanDate.toString().substring(11, 19),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!isSafe) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.gavel, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'FLAGGED ISSUES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...result.flaggedReasons.map((reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[300], size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red[200],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (result.isReportedToAuthorities) ...[
                    const Divider(height: 16),
                    Row(
                      children: [
                        Icon(Icons.report, color: Colors.orange[300], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reported to NCMEC and law enforcement',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[200],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (result.details.isNotEmpty) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Scan Details',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              children: result.details.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRiskColor(double risk) {
    if (risk < 0.3) return Colors.green;
    if (risk < 0.6) return Colors.orange;
    return Colors.red;
  }

  Future<void> _scanFile(String type) async {
    setState(() => _isScanning = true);
    ref.read(isLoadingProvider.notifier).state = true;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: type == 'image' ? FileType.image : FileType.video,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path!;
        final file = File(filePath);
        final bytes = await file.readAsBytes();

        // Scan the content
        final scanResult = await ref.read(scanContentAction)(
          bytes,
          type,
          'default_user',
        );

        if (scanResult != null) {
          setState(() {
            _scanHistory.add(scanResult);
          });

          if (scanResult.isSafe) {
            showSuccessSnackbar(context, 'Content is safe to use');
          } else {
            showErrorSnackbar(
              context,
              'Content flagged: ${scanResult.flaggedReasons.join(", ")}',
            );
          }
        }
      }
    } catch (e) {
      showErrorSnackbar(context, 'Failed to scan file: $e');
    } finally {
      setState(() => _isScanning = false);
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _scanText() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Text/URL'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter text or URL to scan...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          PremiumButton(
            text: 'Scan',
            icon: Icons.search,
            onPressed: () async {
              Navigator.pop(context);
              await _performTextScan(controller.text);
            },
          ),
        ],
      ),
    );

    controller.dispose();
  }

  Future<void> _performTextScan(String text) async {
    if (text.isEmpty) return;

    setState(() => _isScanning = true);
    ref.read(isLoadingProvider.notifier).state = true;

    try {
      final scanResult = await ref.read(scanContentAction)(
        text.codeUnits,
        'text',
        'default_user',
      );

      if (scanResult != null) {
        setState(() {
          _scanHistory.add(scanResult);
        });

        if (scanResult.isSafe) {
          showSuccessSnackbar(context, 'Text is safe');
        } else {
          showErrorSnackbar(
            context,
            'Text flagged: ${scanResult.flaggedReasons.join(", ")}',
          );
        }
      }
    } catch (e) {
      showErrorSnackbar(context, 'Failed to scan text: $e');
    } finally {
      setState(() => _isScanning = false);
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  void _showSafetyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield, color: Colors.blue),
            SizedBox(width: 8),
            Text('Content Safety System'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Our multi-layer safety system protects the network:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                Icons.fingerprint,
                'Hash Matching',
                'Compare against NCMEC database',
              ),
              _buildInfoItem(
                Icons.psychology,
                'AI Analysis',
                'Deep learning detection models',
              ),
              _buildInfoItem(
                Icons.pattern,
                'Pattern Analysis',
                'Behavioral pattern detection',
              ),
              _buildInfoItem(
                Icons.report,
                'Automatic Reporting',
                'Immediate reporting to authorities',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ZERO TOLERANCE: Any CSAM content is immediately reported to NCMEC and law enforcement.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          PremiumButton(
            text: 'Got it',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue[300]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

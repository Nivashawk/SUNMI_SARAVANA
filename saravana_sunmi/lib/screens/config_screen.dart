import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/printer_service.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _branchController = TextEditingController();
  final _floorController = TextEditingController();
  final _deviceIdController = TextEditingController();
  final _printerService = PrinterService();

  bool _isLoadingDevice = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _fetchDeviceId();
  }

  @override
  void dispose() {
    _branchController.dispose();
    _floorController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchDeviceId() async {
    try {
      final serial = await _printerService.getPrinterId();
      if (mounted) {
        setState(() {
          _deviceIdController.text = serial ?? '';
          _isLoadingDevice = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deviceIdController.text = 'Error-Fetching';
          _isLoadingDevice = false;
        });
      }
    }
  }

  Future<void> _syncWithCloud() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSyncing = true;
    });

    final deviceId = _deviceIdController.text.trim();
    final branchName = _branchController.text.trim();
    final floorNum = int.tryParse(_floorController.text.trim()) ?? 0;

    final result = await ApiService.saveConfig(
      deviceId: deviceId,
      branch: branchName,
      floor: floorNum,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_configured', true);
        await prefs.setString('branch_name', branchName);
        await prefs.setString('floor_number', floorNum.toString());
        await prefs.setString('device_serial', deviceId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(result['message'] ?? 'Config synced with cloud successfully!'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF388E3C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save config: $e'),
              backgroundColor: const Color(0xFFD32F2F),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSyncing = false;
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(result['message'] ?? 'Failed to sync with cloud'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(flex: 1),
                          
                          // Logo / Header Section
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/app_logo.png',
                                height: 60,
                                width: 60,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.settings_suggest_rounded,
                                    size: 60,
                                    color: Color(0xFF512DA8),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // const Center(
                          //   child: Text(
                          //     'Saravana Stores',
                          //     style: TextStyle(
                          //       fontSize: 24,
                          //       fontWeight: FontWeight.w900,
                          //       color: Color(0xFF1A1A2E),
                          //       letterSpacing: 0.5,
                          //     ),
                          //   ),
                          // ),
                          const Center(
                            child: Text(
                              'APP CONFIGURATION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF512DA8),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          
                          const Spacer(flex: 1),
                          const SizedBox(height: 16),

                          // Config Card
                          Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.withOpacity(0.12)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Device Metadata',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Device ID Input
                                  TextFormField(
                                    controller: _deviceIdController,
                                    keyboardType: TextInputType.text,
                                    decoration: InputDecoration(
                                      labelText: 'Device ID (SID)',
                                      hintText: 'Detecting/Enter Device ID',
                                      prefixIcon: const Icon(Icons.perm_device_information_rounded, size: 20),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      suffixIcon: _isLoadingDevice
                                          ? const Padding(
                                              padding: EdgeInsets.all(12.0),
                                              child: SizedBox(
                                                height: 16,
                                                width: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 1.5,
                                                  valueColor: AlwaysStoppedAnimation(Color(0xFF512DA8)),
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter Device ID';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  const Text(
                                    'Location Settings',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Branch Name Input
                                  TextFormField(
                                    controller: _branchController,
                                    keyboardType: TextInputType.text,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: InputDecoration(
                                      labelText: 'Branch Name',
                                      hintText: 'e.g. T-Nagar, Porur',
                                      prefixIcon: const Icon(Icons.store_rounded, size: 20),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter branch name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Floor Number Input
                                  TextFormField(
                                    controller: _floorController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Floor Number',
                                      hintText: 'e.g. 1, 2, 3',
                                      prefixIcon: const Icon(Icons.layers_rounded, size: 20),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter floor number';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const Spacer(flex: 2),
                          const SizedBox(height: 24),

                          // Sync button
                          ElevatedButton(
                            onPressed: _isSyncing ? null : _syncWithCloud,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF512DA8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: const Color(0xFF512DA8).withOpacity(0.25),
                            ),
                            child: _isSyncing
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'SYNCING WITH CLOUD...',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'SYNC WITH CLOUD',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

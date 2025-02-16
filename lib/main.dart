import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'src/gopro_telemetry_extractor.dart';
import 'src/gpmf_bindings.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoPro Telemetry Extractor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? selectedFilePath;
  Map<String, dynamic>? extractedData;
  bool isLoading = false;
  String? errorMessage;
  final List<String> sensorTypes = ['ACCL', 'GYRO', 'GPS5', 'GRAV'];
  String? selectedSampleFile;
  final List<String> sampleFiles = [
    'Fusion.mp4',
    'hero7.mp4',
    'hero8.mp4',
    'max-heromode.mp4'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize GPMFBindings
    GPMFBindings.initialize();
  }

  Future<void> processSelectedSample() async {
    if (selectedSampleFile == null) {
      setState(() {
        errorMessage = 'No sample file selected';
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        extractedData = null;
      });

      final String assetPath = 'assets/samples/$selectedSampleFile';
      // Copy asset to a temporary file since we need a file path
      final tempDir = await Directory.systemTemp.createTemp('gpmf_samples');
      final tempFile = File('${tempDir.path}/$selectedSampleFile');
      
      // Get the asset file
      final ByteData data = await rootBundle.load(assetPath);
      await tempFile.writeAsBytes(data.buffer.asUint8List());
      
      selectedFilePath = tempFile.path;
      final extractor = GoProTelemetryExtractor(selectedFilePath!);
      await extractor.openSource(selectedFilePath!);

      try {
        final data = extractor.extractDataToJson(sensorTypes: sensorTypes);
        setState(() {
          extractedData = data;
          isLoading = false;
        });
      } finally {
        extractor.close();
        // Clean up temporary files
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error processing sample file: $e';
      });
    }
  }

  Future<void> pickAndProcessFile() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        extractedData = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['MP4', 'mp4'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'No file selected';
        });
        return;
      }

      selectedFilePath = result.files.first.path;
      if (selectedFilePath == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Invalid file path';
        });
        return;
      }

      final extractor = GoProTelemetryExtractor(selectedFilePath!);
      await extractor.openSource(selectedFilePath!);

      try {
        final data = extractor.extractDataToJson(sensorTypes: sensorTypes);
        setState(() {
          extractedData = data;
          isLoading = false;
        });
      } finally {
        extractor.close();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoPro Telemetry Extractor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Sample Files',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select a sample file'),
                      value: selectedSampleFile,
                      items: sampleFiles.map((String file) {
                        return DropdownMenuItem<String>(
                          value: file,
                          child: Text(file),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (String? newValue) {
                              setState(() {
                                selectedSampleFile = newValue;
                              });
                            },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: isLoading ? null : processSelectedSample,
                      child: Text(
                        isLoading ? 'Processing...' : 'Process Sample File',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Upload Your Own File',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: isLoading ? null : pickAndProcessFile,
                      child: Text(
                        isLoading ? 'Processing...' : 'Select MP4 File',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (selectedFilePath != null) ...[
              const SizedBox(height: 16),
              Text('Selected file: $selectedFilePath'),
            ],
            if (extractedData != null) ...[
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Extracted Data:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final sensorType in sensorTypes)
                        if (extractedData!.containsKey(sensorType)) ...[
                          Text(
                            '$sensorType Data:',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Samples: ${(extractedData![sensorType]['data'] as List).length}',
                          ),
                          const SizedBox(height: 8),
                        ],
                      ElevatedButton(
                        onPressed: () async {
                          final file = File('${selectedFilePath!}_telemetry.json');
                          await file.writeAsString(
                            const JsonEncoder.withIndent('  ').convert(extractedData),
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Saved to ${file.path}'),
                              ),
                            );
                          }
                        },
                        child: const Text('Save to JSON'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
 
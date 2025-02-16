import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import '../lib/src/gopro_telemetry_extractor.dart';
import '../lib/src/gpmf_bindings.dart';
import 'dart:convert';


void main() {
  setUpAll(() {
    GPMFBindings.initialize();
  });

  test('Extract all sensor data from MP4 file', () {
    final filePath = path.join(Directory.current.path, 'assets', 'samples', 'Fusion.mp4');
    print('Testing file: ${filePath}');

    final extractor = GoProTelemetryExtractor(filePath);
    extractor.openSource(filePath);

    try {
      // Get image timestamps
      final timestamps = extractor.getImageTimestampsS();
      print('Found ${timestamps.length} image timestamps');

      // List of all sensor types to test
      final sensorTypes = [
        'ACCL', 'GYRO', 'GPS5', 'GRAV', 'MAGN',
        'CORI', 'IORI', 'GPSP', 'GPSF', 'GPSU'
      ];

      // Extract data for each sensor type
      for (final sensorType in sensorTypes) {
        print('\nTrying to extract $sensorType data:');
        try {
          final result = extractor.extractData(sensorType);
          print('$sensorType: Found ${result.data.length} samples');
          
          // Print first sample if available
          if (result.data.isNotEmpty) {
            print('$sensorType first sample: ${result.data.first}');
            print('$sensorType first timestamp: ${result.timestamps.first}');
          }
        } catch (e, stackTrace) {
          print('$sensorType: No data available (${e.toString()})');
          print('Stack trace: $stackTrace');
        }
      }

      // Extract all data to a map
      final allData = extractor.extractDataToJson(
        sensorTypes: ['ACCL', 'GYRO', 'GPS5', 'GRAV']
      );

      // Verify that we got data for at least some sensors
      expect(allData, isNotEmpty);
      expect(allData['img_timestamps_s'], isNotEmpty);
      final jsonFile = File('extracted_data.json');
      jsonFile.writeAsString(jsonEncode(allData));
      print('Extracted data saved to extracted_data.json');
    } finally {
      extractor.close();
    }
  });
} 
import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'gpmf_bindings.dart';
import 'dart:io';
import 'dart:async';

class SensorData {
  final List<List<double>> data;
  final List<double> timestamps;

  SensorData(this.data, this.timestamps);
}

class GoProTelemetryExtractor {
  final String mp4FilePath;
  int? _handle;
  late final int _strmFourCC;  // Cache STRM FourCC code

  GoProTelemetryExtractor(this.mp4FilePath) {
    // Pre-compute STRM FourCC code
    final strmPtr = 'STRM'.toNativeUtf8().cast<ffi.Int8>();
    try {
      _strmFourCC = GPMFBindings.strToFourCC(strmPtr);
    } finally {
      malloc.free(strmPtr);
    }
  }

  static const int MOV_GPMF_TRAK_TYPE = 0x6174656D;    // 'meta'
  static const int MOV_GPMF_TRAK_SUBTYPE = 0x646D7067;  // 'GPMF'

Future<void> openSource(String path) async {
    if (!File(path).existsSync()) {
      throw Exception('File does not exist: $path');
    }
    print('Opening file: $path');
    print('File exists: ${File(path).existsSync()}');
    print('File size: ${File(path).lengthSync()} bytes');

    final pathPointer = allocateNativeString(path);
    try {
      print('Calling openMP4Source with:');
      print('- MOV_GPMF_TRAK_TYPE: 0x${MOV_GPMF_TRAK_TYPE.toRadixString(16)}');
      print('- MOV_GPMF_TRAK_SUBTYPE: 0x${MOV_GPMF_TRAK_SUBTYPE.toRadixString(16)}');

      _handle = GPMFBindings.openMP4Source(pathPointer, MOV_GPMF_TRAK_TYPE, MOV_GPMF_TRAK_SUBTYPE, 0);
      
      print('openMP4Source returned handle: $_handle');

      if (_handle == 0) {
        throw Exception('Failed to open MP4 source');
      }
    } finally {
      malloc.free(pathPointer);
      print('Freed native path pointer');
    }
}

  void closeSource() {
    if (_handle == null) {
      throw Exception('No source to close!');
    }
    GPMFBindings.closeSource(_handle!);
    _handle = null;
  }

  List<double> getImageTimestampsS() {
    if (_handle == null) {
      throw Exception('Source is not opened!');
    }

    final numer = calloc<ffi.Uint32>();
    final denom = calloc<ffi.Uint32>();

    try {
      final numFrames = GPMFBindings.getVideoFrameRateAndCount(_handle!, numer, denom);
      final frameTime = denom.value / numer.value;

      return List.generate(numFrames, (i) => i * frameTime.toDouble());
    } finally {
      calloc.free(numer);
      calloc.free(denom);
    }
  }

  SensorData extractData(String sensorType) {
    if (_handle == null) {
      throw Exception('Source is not opened!');
    }

    final totalTimer = Stopwatch()..start();
    final setupTimer = Stopwatch()..start();

    final results = <List<double>>[];
    final timestamps = <double>[];

    // Pre-allocate these once
    final sensorTypePointer = sensorType.toNativeUtf8().cast<ffi.Int8>();
    final shutPointer = 'SHUT'.toNativeUtf8().cast<ffi.Int8>();
    final startTime = calloc<ffi.Double>();
    final endTime = calloc<ffi.Double>();
    final inTime = calloc<ffi.Double>();
    final outTime = calloc<ffi.Double>();

    setupTimer.stop();
    print('Setup time: ${setupTimer.elapsedMilliseconds}ms');

    try {
      final sampleRateTimer = Stopwatch()..start();
      final rate = GPMFBindings.getGPMFSampleRate(
        _handle!,
        GPMFBindings.strToFourCC(sensorTypePointer),
        GPMFBindings.strToFourCC(shutPointer),
        startTime,
        endTime,
      );
      sampleRateTimer.stop();
      print('GetGPMFSampleRate time: ${sampleRateTimer.elapsedMilliseconds}ms');

      final payloadTimer = Stopwatch()..start();
      var payloadInitTime = 0;
      var findNextTime = 0;
      var findStrmTime = 0;
      var findSensorTime = 0;
      var elementsTime = 0;
      var samplesTime = 0;
      var scaledDataTime = 0;
      var listCreationTime = 0;
      var timestampCreationTime = 0;
      var dataProcessingTime = 0;
      var bufferConversionTime = 0;

      final numPayloads = GPMFBindings.getNumberPayloads(_handle!);
      print('Number of payloads: $numPayloads');

      for (var i = 0; i < numPayloads; i++) {
        final payloadSize = GPMFBindings.getPayloadSize(_handle!, i);
        var resHandle = 0;
        resHandle = GPMFBindings.getPayloadResource(_handle!, resHandle, payloadSize);
        final payload = GPMFBindings.getPayload(_handle!, resHandle, i);
        
        GPMFBindings.getPayloadTime(_handle!, i, inTime, outTime);
        final deltaT = outTime.value - inTime.value;

        final initTimer = Stopwatch()..start();
        final stream = GPMFBindings.gpmfInit(payload, payloadSize);
        initTimer.stop();
        payloadInitTime += initTimer.elapsedMilliseconds;

        if (stream == ffi.nullptr) continue;

        final findTimer = Stopwatch()..start();
        var findStrmWatch = Stopwatch()..start();
        final strmResult = GPMFBindings.gpmfFindNext(stream, _strmFourCC, GPMFBindings.GPMF_RECURSE_LEVELS_AND_TOLERANT);
        findStrmWatch.stop();
        findStrmTime += findStrmWatch.elapsedMilliseconds;
        
        if (strmResult != GPMFBindings.GPMF_OK) break;

        final findSensorWatch = Stopwatch()..start();
        final sensorResult = GPMFBindings.gpmfFindNext(stream, GPMFBindings.strToFourCC(sensorTypePointer), GPMFBindings.GPMF_RECURSE_LEVELS_AND_TOLERANT);
        findSensorWatch.stop();
        findSensorTime += findSensorWatch.elapsedMilliseconds;
        
        if (sensorResult != GPMFBindings.GPMF_OK) continue;

        findTimer.stop();
        findNextTime += findTimer.elapsedMilliseconds;

        final processTimer = Stopwatch()..start();
        
        final elementsWatch = Stopwatch()..start();
        final elements = GPMFBindings.gpmfElementsInStruct(stream);
        elementsWatch.stop();
        elementsTime += elementsWatch.elapsedMilliseconds;

        final samplesWatch = Stopwatch()..start();
        final samples = GPMFBindings.gpmfRepeat(stream);
        samplesWatch.stop();
        samplesTime += samplesWatch.elapsedMilliseconds;

        if (samples > 0) {
          final bufferSize = samples * elements * 8;
          final buffer = calloc<ffi.Double>(bufferSize);

          try {
            final scaledDataWatch = Stopwatch()..start();
            final ret = GPMFBindings.gpmfScaledData(
              stream,
              buffer.cast(),
              bufferSize,
              0,
              samples,
              GPMFBindings.GPMF_TYPE_DOUBLE,
            );
            scaledDataWatch.stop();
            scaledDataTime += scaledDataWatch.elapsedMilliseconds;

            processTimer.stop();
            dataProcessingTime += processTimer.elapsedMilliseconds;

            if (ret == GPMFBindings.GPMF_OK) {
              final bufferTimer = Stopwatch()..start();
              // Convert buffer to List<double> in one go
              final data = buffer.asTypedList(samples * elements);
              
              // Add samples in chunks
              for (var j = 0; j < samples; j++) {
                final listWatch = Stopwatch()..start();
                results.add(data.sublist(j * elements, (j + 1) * elements).toList());
                listWatch.stop();
                listCreationTime += listWatch.elapsedMilliseconds;

                final timestampWatch = Stopwatch()..start();
                timestamps.add(inTime.value + j * deltaT / samples);
                timestampWatch.stop();
                timestampCreationTime += timestampWatch.elapsedMilliseconds;
              }
              bufferTimer.stop();
              bufferConversionTime += bufferTimer.elapsedMilliseconds;
            }
          } finally {
            calloc.free(buffer);
          }
        }
        GPMFBindings.gpmfResetState(stream);
      }
      payloadTimer.stop();

      final timestampTimer = Stopwatch()..start();
      // Add start time to all timestamps at once
      for (var i = 0; i < timestamps.length; i++) {
        timestamps[i] += startTime.value;
      }
      timestampTimer.stop();

      print('Payload processing breakdown:');
      print('  - Total payload time: ${payloadTimer.elapsedMilliseconds}ms');
      print('  - GPMF Init time: ${payloadInitTime}ms');
      print('  - Find Next breakdown:');
      print('    * Find STRM time: ${findStrmTime}ms');
      print('    * Find sensor time: ${findSensorTime}ms');
      print('  - Total Find Next time: ${findNextTime}ms');
      print('  - Data processing breakdown:');
      print('    * Get elements time: ${elementsTime}ms');
      print('    * Get samples time: ${samplesTime}ms');
      print('    * Scaled data time: ${scaledDataTime}ms');
      print('  - Total data processing time: ${dataProcessingTime}ms');
      print('  - Buffer conversion breakdown:');
      print('    * List creation time: ${listCreationTime}ms');
      print('    * Timestamp creation time: ${timestampCreationTime}ms');
      print('  - Total buffer conversion time: ${bufferConversionTime}ms');
      print('Timestamp adjustment time: ${timestampTimer.elapsedMilliseconds}ms');
      print('Number of samples: ${timestamps.length}');

    } finally {
      calloc.free(sensorTypePointer);
      calloc.free(shutPointer);
      calloc.free(startTime);
      calloc.free(endTime);
      calloc.free(inTime);
      calloc.free(outTime);
    }

    totalTimer.stop();
    print('Total extraction time: ${totalTimer.elapsedMilliseconds}ms');

    return SensorData(results, timestamps);
  }

  Map<String, dynamic> extractDataToJson({List<String> sensorTypes = const ['ACCL', 'GYRO']}) {
    final result = <String, dynamic>{
      'img_timestamps_s': getImageTimestampsS(),
    };

    for (final sensorType in sensorTypes) {
      try {
        final data = extractData(sensorType);
        result[sensorType] = {
          'data': data.data,
          'timestamps_s': data.timestamps,
        };
      } catch (e) {
        print('Failed to extract $sensorType data: $e');
      }
    }

    return result;
  }

  void close() {
    closeSource();
  }
} 

ffi.Pointer<ffi.Int8> allocateNativeString(String str) {
  return str.toNativeUtf8().cast<ffi.Int8>();
} 
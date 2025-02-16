import 'dart:ffi' as ffi;
import 'dart:io' show Platform, Directory, File;
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

// FFI type definitions
typedef OpenMP4SourceNative = ffi.Size Function(
    ffi.Pointer<ffi.Int8> filename,
    ffi.Uint32 trakType,
    ffi.Uint32 trakSubtype,
    ffi.Uint32 index);
typedef OpenMP4Source = int Function(
    ffi.Pointer<ffi.Int8> filename,
    int trakType,
    int trakSubtype,
    int index);

typedef CloseSourceNative = ffi.Void Function(ffi.Size handle);
typedef CloseSource = void Function(int handle);

typedef GetDurationNative = ffi.Double Function(ffi.Size handle);
typedef GetDuration = double Function(int handle);

typedef GetNumberPayloadsNative = ffi.Uint32 Function(ffi.Size handle);
typedef GetNumberPayloads = int Function(int handle);

typedef GetPayloadSizeNative = ffi.Uint32 Function(
    ffi.Size handle, ffi.Uint32 index);
typedef GetPayloadSize = int Function(int handle, int index);

typedef GetPayloadResourceNative = ffi.Size Function(
    ffi.Size mp4handle, ffi.Size resHandle, ffi.Uint32 payloadsize);
typedef GetPayloadResource = int Function(
    int mp4handle, int resHandle, int payloadsize);

typedef GetPayloadNative = ffi.Pointer<ffi.Uint32> Function(
    ffi.Size mp4handle, ffi.Size resHandle, ffi.Uint32 index);
typedef GetPayload = ffi.Pointer<ffi.Uint32> Function(
    int mp4handle, int resHandle, int index);

typedef GetPayloadTimeNative = ffi.Uint32 Function(
    ffi.Size handle,
    ffi.Uint32 index,
    ffi.Pointer<ffi.Double> inTime,
    ffi.Pointer<ffi.Double> outTime);
typedef GetPayloadTime = int Function(
    int handle,
    int index,
    ffi.Pointer<ffi.Double> inTime,
    ffi.Pointer<ffi.Double> outTime);

typedef GetVideoFrameRateAndCountNative = ffi.Uint32 Function(
    ffi.Size handle,
    ffi.Pointer<ffi.Uint32> numer,
    ffi.Pointer<ffi.Uint32> demon);
typedef GetVideoFrameRateAndCount = int Function(
    int handle,
    ffi.Pointer<ffi.Uint32> numer,
    ffi.Pointer<ffi.Uint32> demon);

typedef GPMFStreamWrapper = ffi.Opaque;

typedef GPMFInitNative = ffi.Pointer<GPMFStreamWrapper> Function(
    ffi.Pointer<ffi.Uint32> buffer, ffi.Uint32 datasize);
typedef GPMFInit = ffi.Pointer<GPMFStreamWrapper> Function(
    ffi.Pointer<ffi.Uint32> buffer, int datasize);

typedef GPMFFindNextNative = ffi.Int32 Function(
    ffi.Pointer<GPMFStreamWrapper> wrapper,
    ffi.Uint32 fourcc,
    ffi.Int32 recurse);
typedef GPMFFindNext = int Function(
    ffi.Pointer<GPMFStreamWrapper> wrapper,
    int fourcc,
    int recurse);

typedef GPMFResetStateNative = ffi.Int32 Function(
    ffi.Pointer<GPMFStreamWrapper> wrapper);
typedef GPMFResetState = int Function(
    ffi.Pointer<GPMFStreamWrapper> wrapper);

typedef GPMFKeyNative = ffi.Uint32 Function(
    ffi.Pointer<GPMFStreamWrapper> wrapper);
typedef GPMFKey = int Function(ffi.Pointer<GPMFStreamWrapper> wrapper);

typedef GPMFTypeNative = ffi.Uint32 Function(
    ffi.Pointer<GPMFStreamWrapper> wrapper);
typedef GPMFType = int Function(ffi.Pointer<GPMFStreamWrapper> wrapper);

typedef GPMFStructSizeNative = ffi.Uint32 Function(
    ffi.Pointer<GPMFStreamWrapper> wrapper);
typedef GPMFStructSize = int Function(ffi.Pointer<GPMFStreamWrapper> wrapper);

typedef GPMFElementsInStructNative = ffi.Uint32 Function(
    ffi.Pointer<GPMFStreamWrapper> wrapper);
typedef GPMFElementsInStruct = int Function(
    ffi.Pointer<GPMFStreamWrapper> wrapper);

typedef GPMFRepeatNative = ffi.Uint32 Function(
    ffi.Pointer<GPMFStreamWrapper> wrapper);
typedef GPMFRepeat = int Function(ffi.Pointer<GPMFStreamWrapper> wrapper);

typedef GPMFRawDataSizeNative = ffi.Uint32 Function(
    ffi.Pointer<GPMFStreamWrapper> wrapper);
typedef GPMFRawDataSize = int Function(ffi.Pointer<GPMFStreamWrapper> wrapper);

typedef GPMFRawDataNative = ffi.Pointer<ffi.Void> Function(
    ffi.Pointer<GPMFStreamWrapper> wrapper);
typedef GPMFRawData = ffi.Pointer<ffi.Void> Function(
    ffi.Pointer<GPMFStreamWrapper> wrapper);

typedef GPMFScaledDataNative = ffi.Int32 Function(
    ffi.Pointer<GPMFStreamWrapper> wrapper,
    ffi.Pointer<ffi.Void> buffer,
    ffi.Uint32 bufferSize,
    ffi.Uint32 sampleOffset,
    ffi.Uint32 readSamples,
    ffi.Int32 type);
typedef GPMFScaledData = int Function(
    ffi.Pointer<GPMFStreamWrapper> wrapper,
    ffi.Pointer<ffi.Void> buffer,
    int bufferSize,
    int sampleOffset,
    int readSamples,
    int type);

typedef GetGPMFSampleRateNative = ffi.Double Function(
    ffi.Size mp4handle,
    ffi.Uint32 fourcc,
    ffi.Uint32 key,
    ffi.Pointer<ffi.Double> startTime,
    ffi.Pointer<ffi.Double> endTime);
typedef GetGPMFSampleRate = double Function(
    int mp4handle,
    int fourcc,
    int key,
    ffi.Pointer<ffi.Double> startTime,
    ffi.Pointer<ffi.Double> endTime);

typedef StrToFourCCNative = ffi.Uint32 Function(ffi.Pointer<ffi.Int8> str);
typedef StrToFourCC = int Function(ffi.Pointer<ffi.Int8> str);

typedef FourCCToStrNative = ffi.Void Function(
    ffi.Uint32 fourcc, ffi.Pointer<ffi.Int8> str);
typedef FourCCToStr = void Function(int fourcc, ffi.Pointer<ffi.Int8> str);

typedef IsValidFourCCNative = ffi.Int32 Function(ffi.Uint32 fourcc);
typedef IsValidFourCC = int Function(int fourcc);

class GPMFBindings {
  static late final ffi.DynamicLibrary _lib;
  static late final OpenMP4Source openMP4Source;
  static late final CloseSource closeSource;
  static late final GetDuration getDuration;
  static late final GetNumberPayloads getNumberPayloads;
  static late final GetPayloadSize getPayloadSize;
  static late final GetPayloadResource getPayloadResource;
  static late final GetPayload getPayload;
  static late final GetPayloadTime getPayloadTime;
  static late final GetVideoFrameRateAndCount getVideoFrameRateAndCount;
  static late final GPMFInit gpmfInit;
  static late final GPMFFindNext gpmfFindNext;
  static late final GPMFResetState gpmfResetState;
  static late final GPMFKey gpmfKey;
  static late final GPMFType gpmfType;
  static late final GPMFStructSize gpmfStructSize;
  static late final GPMFElementsInStruct gpmfElementsInStruct;
  static late final GPMFRepeat gpmfRepeat;
  static late final GPMFRawDataSize gpmfRawDataSize;
  static late final GPMFRawData gpmfRawData;
  static late final GPMFScaledData gpmfScaledData;
  static late final GetGPMFSampleRate getGPMFSampleRate;
  static late final StrToFourCC strToFourCC;
  static late final FourCCToStr fourCCToStr;
  static late final IsValidFourCC isValidFourCC;

  static String _getLibraryPath() {
    if (Platform.isAndroid) {
      return 'libgpmf.so';
    } else if (Platform.isIOS) {
      return 'gpmf.framework/gpmf';
    } else if (Platform.isLinux) {
      final libPath = path.join(Directory.current.path, 'build', 'libgpmf.so');
      print('Debug: Constructed library path: $libPath');
      return libPath;
    } else if (Platform.isWindows) {
      final libPath = path.join(Directory.current.path, 'build', 'gpmf.dll');
      print('Debug: Constructed library path: $libPath');
      return libPath;
    } else if (Platform.isMacOS) {
      final libPath = path.join(Directory.current.path, 'build', 'libgpmf.dylib');
      print('Debug: Constructed library path: $libPath');
      return libPath;
    } else {
      throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
    }
  }

  static void initialize() {
    print('Debug: Starting GPMFBindings initialization');
    print('Debug: Platform is ${Platform.operatingSystem}');
    print('Debug: Current directory is ${Directory.current.path}');
    
    final libPath = _getLibraryPath();
    print('Debug: Loading native library from: $libPath');
    
    if (!Platform.isAndroid && !Platform.isIOS && !File(libPath).existsSync()) {
      print('Debug: ERROR - Library file does not exist!');
      throw Exception('Native library not found at: $libPath');
    }
    
    if (!Platform.isAndroid && !Platform.isIOS) {
      print('Debug: Library file exists: ${File(libPath).existsSync()}');
      print('Debug: Library file size: ${File(libPath).lengthSync()} bytes');
    }

    try {
      _lib = ffi.DynamicLibrary.open(libPath);
      print('Debug: Successfully loaded native library');
    } catch (e) {
      print('Debug: Failed to load native library: $e');
      rethrow;
    }

    print('Debug: Loading function bindings...');
    
    try {
      openMP4Source = _lib
          .lookupFunction<OpenMP4SourceNative, OpenMP4Source>('open_mp4_source');
      print('Debug: Loaded openMP4Source');
      
      closeSource = _lib.lookupFunction<CloseSourceNative, CloseSource>('close_source');
      print('Debug: Loaded closeSource');
      
      getDuration = _lib.lookupFunction<GetDurationNative, GetDuration>('get_duration');
      print('Debug: Loaded getDuration');
      
      getNumberPayloads = _lib
          .lookupFunction<GetNumberPayloadsNative, GetNumberPayloads>('get_number_payloads');
      print('Debug: Loaded getNumberPayloads');
      
      getPayloadSize = _lib
          .lookupFunction<GetPayloadSizeNative, GetPayloadSize>('get_payload_size');
      print('Debug: Loaded getPayloadSize');
      
      getPayloadResource = _lib
          .lookupFunction<GetPayloadResourceNative, GetPayloadResource>('get_payload_resource');
      print('Debug: Loaded getPayloadResource');
      
      getPayload = _lib.lookupFunction<GetPayloadNative, GetPayload>('get_payload');
      print('Debug: Loaded getPayload');
      
      getPayloadTime = _lib
          .lookupFunction<GetPayloadTimeNative, GetPayloadTime>('get_payload_time');
      print('Debug: Loaded getPayloadTime');
      
      getVideoFrameRateAndCount = _lib
          .lookupFunction<GetVideoFrameRateAndCountNative, GetVideoFrameRateAndCount>('get_video_frame_rate_and_count');
      print('Debug: Loaded getVideoFrameRateAndCount');
      
      gpmfInit = _lib.lookupFunction<GPMFInitNative, GPMFInit>('gpmf_init');
      print('Debug: Loaded gpmfInit');
      
      gpmfFindNext = _lib
          .lookupFunction<GPMFFindNextNative, GPMFFindNext>('gpmf_find_next');
      print('Debug: Loaded gpmfFindNext');
      
      gpmfResetState = _lib
          .lookupFunction<GPMFResetStateNative, GPMFResetState>('gpmf_reset_state');
      print('Debug: Loaded gpmfResetState');
      
      gpmfKey = _lib.lookupFunction<GPMFKeyNative, GPMFKey>('gpmf_key');
      print('Debug: Loaded gpmfKey');
      
      gpmfType = _lib.lookupFunction<GPMFTypeNative, GPMFType>('gpmf_type');
      print('Debug: Loaded gpmfType');
      
      gpmfStructSize = _lib
          .lookupFunction<GPMFStructSizeNative, GPMFStructSize>('gpmf_struct_size');
      print('Debug: Loaded gpmfStructSize');
      
      gpmfElementsInStruct = _lib
          .lookupFunction<GPMFElementsInStructNative, GPMFElementsInStruct>('gpmf_elements_in_struct');
      print('Debug: Loaded gpmfElementsInStruct');
      
      gpmfRepeat = _lib.lookupFunction<GPMFRepeatNative, GPMFRepeat>('gpmf_repeat');
      print('Debug: Loaded gpmfRepeat');
      
      gpmfRawDataSize = _lib
          .lookupFunction<GPMFRawDataSizeNative, GPMFRawDataSize>('gpmf_raw_data_size');
      print('Debug: Loaded gpmfRawDataSize');
      
      gpmfRawData = _lib.lookupFunction<GPMFRawDataNative, GPMFRawData>('gpmf_raw_data');
      print('Debug: Loaded gpmfRawData');
      
      gpmfScaledData = _lib
          .lookupFunction<GPMFScaledDataNative, GPMFScaledData>('gpmf_scaled_data');
      print('Debug: Loaded gpmfScaledData');
      
      getGPMFSampleRate = _lib
          .lookupFunction<GetGPMFSampleRateNative, GetGPMFSampleRate>('get_gpmf_sample_rate');
      print('Debug: Loaded getGPMFSampleRate');
      
      strToFourCC = _lib.lookupFunction<StrToFourCCNative, StrToFourCC>('str_to_fourcc');
      print('Debug: Loaded strToFourCC');
      
      fourCCToStr = _lib.lookupFunction<FourCCToStrNative, FourCCToStr>('fourcc_to_str');
      print('Debug: Loaded fourCCToStr');
      
      isValidFourCC = _lib
          .lookupFunction<IsValidFourCCNative, IsValidFourCC>('is_valid_fourcc');
      print('Debug: Loaded isValidFourCC');
      
      print('Debug: All bindings loaded successfully');
    } catch (e) {
      print('Debug: Failed to load function bindings: $e');
      rethrow;
    }
  }

  // Constants
  static const int MOV_GPMF_TRAK_TYPE = 0x61746564;    // 'ated'
  static const int MOV_GPMF_TRAK_SUBTYPE = 0x47504D47;  // 'GPMG'
  static const int GPMF_OK = 0;
  static const int GPMF_ERROR_MEMORY = 1;
  static const int GPMF_ERROR_BAD_STRUCTURE = 2;
  static const int GPMF_ERROR_BUFFER_END = 3;
  static const int GPMF_ERROR_FIND = 4;
  static const int GPMF_ERROR_LAST = 5;
  static const int GPMF_ERROR_TYPE_NOT_SUPPORTED = 6;
  static const int GPMF_ERROR_SCALE_NOT_SUPPORTED = 7;
  static const int GPMF_ERROR_SCALE_COUNT = 8;
  static const int GPMF_ERROR_UNKNOWN_TYPE = 9;
  static const int GPMF_ERROR_RESERVED = 10;

  static const int GPMF_CURRENT_LEVEL = 0;
  static const int GPMF_RECURSE_LEVELS = 1;
  static const int GPMF_TOLERANT = 2;
  static const int GPMF_RECURSE_LEVELS_AND_TOLERANT = 3;

  static const int GPMF_TYPE_STRING_ASCII = 0x00000063;  // 'c'
  static const int GPMF_TYPE_SIGNED_BYTE = 0x00000062;   // 'b'
  static const int GPMF_TYPE_UNSIGNED_BYTE = 0x00000042; // 'B'
  static const int GPMF_TYPE_SIGNED_SHORT = 0x00000073;  // 's'
  static const int GPMF_TYPE_UNSIGNED_SHORT = 0x00000053;// 'S'
  static const int GPMF_TYPE_FLOAT = 0x00000066;         // 'f'
  static const int GPMF_TYPE_FOURCC = 0x00000046;        // 'F'
  static const int GPMF_TYPE_SIGNED_LONG = 0x0000006C;   // 'l'
  static const int GPMF_TYPE_UNSIGNED_LONG = 0x0000004C; // 'L'
  static const int GPMF_TYPE_Q15_16_FIXED_POINT = 0x00000071;    // 'q'
  static const int GPMF_TYPE_Q31_32_FIXED_POINT = 0x00000051;    // 'Q'
  static const int GPMF_TYPE_SIGNED_64BIT_INT = 0x0000006A;      // 'j'
  static const int GPMF_TYPE_UNSIGNED_64BIT_INT = 0x0000004A;    // 'J'
  static const int GPMF_TYPE_DOUBLE = 0x00000064;        // 'd'
  static const int GPMF_TYPE_STRING_UTF8 = 0x00000075;   // 'u'
  static const int GPMF_TYPE_UTC_DATE_TIME = 0x00000055; // 'U'
  static const int GPMF_TYPE_GUID = 0x00000067;          // 'g'
  static const int GPMF_TYPE_COMPLEX = 0x00000063;       // 'c'
  static const int GPMF_TYPE_COMPRESSED = 0x00000043;    // 'C'
  static const int GPMF_TYPE_NEST = 0x0000004E;          // 'N'
  static const int GPMF_TYPE_EMPTY = 0x00000000;         // null
  static const int GPMF_TYPE_ERROR = -1;
} 
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "GPMF_parser.h"
#include "GPMF_mp4reader.h"
#include "GPMF_utils.h"

// GPMF Parser structure
typedef struct {
    uint8_t* buffer;
    size_t buffer_size;
    size_t current_position;
    GPMF_stream* stream;
    size_t mp4_handle;
} GPMFParser;

// Initialize GPMF parser
GPMFParser* gpmf_parser_init(const char* filename) {
    GPMFParser* parser = (GPMFParser*)malloc(sizeof(GPMFParser));
    if (parser) {
        parser->buffer = NULL;
        parser->buffer_size = 0;
        parser->current_position = 0;
        parser->stream = (GPMF_stream*)malloc(sizeof(GPMF_stream));
        if (!parser->stream) {
            free(parser);
            return NULL;
        }
        memset(parser->stream, 0, sizeof(GPMF_stream));
        
        parser->mp4_handle = OpenMP4Source((char*)filename, MOV_GPMF_TRAK_TYPE, MOV_GPMF_TRAK_SUBTYPE, 0);
        if (parser->mp4_handle == 0) {
            free(parser->stream);
            free(parser);
            return NULL;
        }
    }
    return parser;
}

// Clean up GPMF parser
void gpmf_parser_cleanup(GPMFParser* parser) {
    if (parser) {
        if (parser->mp4_handle) {
            CloseSource(parser->mp4_handle);
        }
        if (parser->buffer) {
            free(parser->buffer);
        }
        if (parser->stream) {
            free(parser->stream);
        }
        free(parser);
    }
}

// Get payload data
typedef struct {
    uint32_t* data;
    uint32_t size;
    double timestamp;
} PayloadData;

PayloadData* gpmf_get_payload(GPMFParser* parser, uint32_t index) {
    if (!parser || !parser->mp4_handle) {
        printf("gpmf_get_payload: Invalid parser or mp4_handle\n");
        return NULL;
    }

    printf("gpmf_get_payload: Getting payload size for index %u\n", index);
    uint32_t payloadsize = GetPayloadSize(parser->mp4_handle, index);
    if (payloadsize == 0) {
        printf("gpmf_get_payload: Payload size is 0\n");
        return NULL;
    }
    printf("gpmf_get_payload: Payload size: %u\n", payloadsize);

    printf("gpmf_get_payload: Getting payload resource\n");
    size_t res_handle = GetPayloadResource(parser->mp4_handle, index, payloadsize);
    if (res_handle == 0) {
        printf("gpmf_get_payload: Failed to get payload resource\n");
        return NULL;
    }

    printf("gpmf_get_payload: Getting payload data\n");
    uint32_t* payload = GetPayload(parser->mp4_handle, res_handle, index);
    if (!payload) {
        printf("gpmf_get_payload: Failed to get payload data\n");
        FreePayloadResource(parser->mp4_handle, res_handle);
        return NULL;
    }

    PayloadData* data = (PayloadData*)malloc(sizeof(PayloadData));
    if (!data) {
        printf("gpmf_get_payload: Failed to allocate PayloadData\n");
        FreePayloadResource(parser->mp4_handle, res_handle);
        return NULL;
    }

    data->data = (uint32_t*)malloc(payloadsize);
    if (!data->data) {
        printf("gpmf_get_payload: Failed to allocate data buffer\n");
        free(data);
        FreePayloadResource(parser->mp4_handle, res_handle);
        return NULL;
    }

    memcpy(data->data, payload, payloadsize);
    data->size = payloadsize;

    double in_time, out_time;
    GetPayloadTime(parser->mp4_handle, index, &in_time, &out_time);
    data->timestamp = in_time;
    printf("gpmf_get_payload: Got payload with timestamp %f\n", data->timestamp);

    // Print first few bytes of payload for debugging
    printf("gpmf_get_payload: First few bytes of payload: ");
    for (int i = 0; i < (payloadsize > 16 ? 16 : payloadsize); i++) {
        printf("%02x ", ((uint8_t*)data->data)[i]);
    }
    printf("\n");

    FreePayloadResource(parser->mp4_handle, res_handle);
    return data;
}

void gpmf_free_payload(PayloadData* data) {
    if (data) {
        if (data->data) {
            free(data->data);
        }
        free(data);
    }
}

// Video frame rate and count structure
typedef struct {
    uint32_t frames;
    uint32_t numer;
    uint32_t denom;
} VideoFrameInfo;

// Get video frame rate and count
VideoFrameInfo* gpmf_get_video_frame_info(GPMFParser* parser) {
    if (!parser || !parser->mp4_handle) return NULL;

    VideoFrameInfo* info = (VideoFrameInfo*)malloc(sizeof(VideoFrameInfo));
    if (!info) return NULL;

    info->frames = GetVideoFrameRateAndCount(parser->mp4_handle, &info->numer, &info->denom);
    return info;
}

// Sample rate information structure
typedef struct {
    double rate;
    double start_time;
    double end_time;
} SampleRateInfo;

// Get GPMF sample rate information
SampleRateInfo* gpmf_get_sample_rate_info(GPMFParser* parser, const char* sensor_type) {
    if (!parser || !parser->mp4_handle) return NULL;

    SampleRateInfo* info = (SampleRateInfo*)malloc(sizeof(SampleRateInfo));
    if (!info) return NULL;

    uint32_t sensor_fourcc = (sensor_type[0] << 0) | (sensor_type[1] << 8) | 
                            (sensor_type[2] << 16) | (sensor_type[3] << 24);

    mp4callbacks cbobject = {0};
    cbobject.mp4handle = parser->mp4_handle;
    cbobject.cbGetNumberPayloads = GetNumberPayloads;
    cbobject.cbGetPayload = GetPayload;
    cbobject.cbGetPayloadSize = GetPayloadSize;
    cbobject.cbGetPayloadResource = GetPayloadResource;
    cbobject.cbGetPayloadTime = GetPayloadTime;
    cbobject.cbFreePayloadResource = FreePayloadResource;
    cbobject.cbGetEditListOffsetRationalTime = GetEditListOffsetRationalTime;

    info->rate = GetGPMFSampleRate(cbobject, sensor_fourcc, 0,
        GPMF_SAMPLE_RATE_PRECISE, &info->start_time, &info->end_time);

    return info;
}

// Get sensor data for a specific FourCC code
typedef struct {
    double timestamp;
    double* data;
    uint32_t data_size;
} SensorData;

int32_t gpmf_get_sensor_data(GPMFParser* parser, const char* key_type, double* timestamps, double* values, int32_t max_samples) {
    if (!parser || !parser->mp4_handle || !key_type || !timestamps || !values || max_samples <= 0) {
        printf("Invalid parameters in gpmf_get_sensor_data\n");
        return 0;
    }

    printf("gpmf_get_sensor_data: Looking for sensor type %s\n", key_type);
    int32_t samples_found = 0;
    uint32_t payloads = GetNumberPayloads(parser->mp4_handle);
    printf("Found %d payloads\n", payloads);

    GPMF_stream gs_stack = {0}; // Initialize on stack
    GPMF_stream* gs = &gs_stack; // Use pointer for consistency

    // Get payload size first
    uint32_t payload_size = GetPayloadSize(parser->mp4_handle, 0);
    if (payload_size == 0) {
        printf("Zero payload size\n");
        return 0;
    }
    printf("Payload size: %d\n", payload_size);

    // Get payload resource
    size_t res_handle = GetPayloadResource(parser->mp4_handle, 0, payload_size);
    if (res_handle == 0) {
        printf("Failed to get payload resource\n");
        return 0;
    }
    printf("Got payload resource: %zu\n", res_handle);

    // Get payload data
    uint32_t* payload_data = GetPayload(parser->mp4_handle, res_handle, 0);
    if (!payload_data) {
        printf("Failed to get payload data\n");
        FreePayloadResource(parser->mp4_handle, res_handle);
        return 0;
    }
    printf("Got payload data at %p\n", (void*)payload_data);

    // Initialize GPMF stream with the payload data
    GPMF_ERR err = GPMF_Init(gs, payload_data, payload_size);
    if (err != GPMF_OK) {
        printf("GPMF_Init failed with error %d\n", err);
        FreePayloadResource(parser->mp4_handle, res_handle);
        return 0;
    }
    printf("GPMF_Init successful\n");

    // Find the sensor data in the stream
    uint32_t fourcc = STR2FOURCC(key_type);
    printf("Looking for FourCC: %c%c%c%c (0x%08x)\n", 
           (char)(fourcc & 0xFF),
           (char)((fourcc >> 8) & 0xFF),
           (char)((fourcc >> 16) & 0xFF),
           (char)((fourcc >> 24) & 0xFF),
           fourcc);

    if (GPMF_FindNext(gs, fourcc, GPMF_RECURSE_LEVELS) != GPMF_OK) {
        printf("Failed to find key %s\n", key_type);
        FreePayloadResource(parser->mp4_handle, res_handle);
        return 0;
    }
    printf("Found key %s in payload\n", key_type);

    // Get payload timestamp
    double in_time, out_time;
    GetPayloadTime(parser->mp4_handle, 0, &in_time, &out_time);
    printf("Payload time range: %f to %f\n", in_time, out_time);

    // Get the number of samples in this payload
    uint32_t elements = GPMF_PayloadSampleCount(gs);
    if (elements == 0) {
        printf("No elements found\n");
        FreePayloadResource(parser->mp4_handle, res_handle);
        return 0;
    }
    printf("Found %d elements in payload\n", elements);

    // Limit the number of samples to max_samples
    if (elements > max_samples) {
        printf("Limiting elements from %d to %d\n", elements, max_samples);
        elements = max_samples;
    }

    // Get the scaled data
    GPMF_ERR scale_err = GPMF_ScaledData(gs, values, elements, 0, 1, GPMF_TYPE_DOUBLE);
    if (scale_err != GPMF_OK) {
        printf("Failed to scale data with error %d\n", scale_err);
        FreePayloadResource(parser->mp4_handle, res_handle);
        return 0;
    }
    printf("Successfully scaled data\n");

    // Fill timestamps
    for (uint32_t i = 0; i < elements; i++) {
        timestamps[i] = in_time;
    }

    FreePayloadResource(parser->mp4_handle, res_handle);
    printf("Successfully processed %d samples\n", elements);
    return elements;
}

void gpmf_free_sensor_data(SensorData* data) {
    if (data) {
        if (data->data) {
            free(data->data);
        }
        free(data);
    }
}

// Export symbols for FFI
#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

EXPORT GPMFParser* init_parser(const char* filename) {
    return gpmf_parser_init(filename);
}

EXPORT void cleanup_parser(GPMFParser* parser) {
    gpmf_parser_cleanup(parser);
}

EXPORT uint32_t get_payload_count(GPMFParser* parser) {
    return parser ? GetNumberPayloads(parser->mp4_handle) : 0;
}

EXPORT VideoFrameInfo* get_video_frame_info(GPMFParser* parser) {
    return gpmf_get_video_frame_info(parser);
}

EXPORT void free_video_frame_info(VideoFrameInfo* info) {
    if (info) free(info);
}

EXPORT SampleRateInfo* get_sample_rate_info(GPMFParser* parser, const char* sensor_type) {
    return gpmf_get_sample_rate_info(parser, sensor_type);
}

EXPORT void free_sample_rate_info(SampleRateInfo* info) {
    if (info) free(info);
}

EXPORT SensorData* get_sensor_data(GPMFParser* parser, const char* fourcc, uint32_t index) {
    if (!parser || !parser->mp4_handle) {
        printf("Invalid parser or mp4_handle\n");
        return NULL;
    }

    printf("Getting payload for index %u\n", index);
    PayloadData* payload = gpmf_get_payload(parser, index);
    if (!payload) {
        printf("Failed to get payload\n");
        return NULL;
    }
    printf("Got payload with size: %u\n", payload->size);

    printf("Initializing GPMF stream\n");
    GPMF_ERR err = GPMF_Init(parser->stream, payload->data, payload->size / sizeof(uint32_t));
    if (err != GPMF_OK) {
        printf("GPMF_Init failed with error: %d\n", err);
        gpmf_free_payload(payload);
        return NULL;
    }

    uint32_t fourcc_code = (fourcc[0] << 0) | (fourcc[1] << 8) | (fourcc[2] << 16) | (fourcc[3] << 24);
    printf("Looking for FourCC: %c%c%c%c (0x%08x)\n", 
           fourcc[0], fourcc[1], fourcc[2], fourcc[3], fourcc_code);

    if (GPMF_FindNext(parser->stream, fourcc_code, GPMF_RECURSE_LEVELS) != GPMF_OK) {
        printf("Failed to find FourCC in stream\n");
        gpmf_free_payload(payload);
        return NULL;
    }
    printf("Found FourCC in stream\n");

    uint32_t elements = GPMF_ElementsInStruct(parser->stream);
    uint32_t samples = GPMF_Repeat(parser->stream);
    printf("Elements per struct: %u, Samples: %u\n", elements, samples);
    
    SensorData* data = (SensorData*)malloc(sizeof(SensorData));
    if (!data) {
        printf("Failed to allocate SensorData\n");
        gpmf_free_payload(payload);
        return NULL;
    }

    data->data_size = elements * samples;
    data->data = (double*)malloc(sizeof(double) * data->data_size);
    if (!data->data) {
        printf("Failed to allocate data buffer\n");
        free(data);
        gpmf_free_payload(payload);
        return NULL;
    }

    data->timestamp = payload->timestamp;
    printf("Timestamp: %f\n", data->timestamp);

    printf("Getting scaled data\n");
    GPMF_ERR scale_err = GPMF_ScaledData(parser->stream, data->data, data->data_size, 0, samples, GPMF_TYPE_DOUBLE);
    if (scale_err != GPMF_OK) {
        printf("GPMF_ScaledData failed with error: %d\n", scale_err);
    } else {
        printf("Successfully got scaled data\n");
        // Print first few values if available
        if (data->data_size > 0) {
            printf("First few values: ");
            for (int i = 0; i < (data->data_size > 3 ? 3 : data->data_size); i++) {
                printf("%f ", data->data[i]);
            }
            printf("\n");
        }
    }
    
    gpmf_free_payload(payload);
    return data;
}

EXPORT void free_sensor_data(SensorData* data) {
    gpmf_free_sensor_data(data);
} 
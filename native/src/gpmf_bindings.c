#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include "GPMF_parser.h"
#include "GPMF_mp4reader.h"
#include "GPMF_utils.h"

// Stream wrapper to manage memory and state
typedef struct {
    GPMF_stream stream;
    uint32_t* buffer;
    size_t buffer_size;
} GPMFStreamWrapper;

// Function to create a new stream wrapper
GPMFStreamWrapper* create_stream_wrapper(uint32_t* buffer, size_t buffer_size) {
    GPMFStreamWrapper* wrapper = (GPMFStreamWrapper*)malloc(sizeof(GPMFStreamWrapper));
    if (wrapper) {
        wrapper->buffer = buffer;
        wrapper->buffer_size = buffer_size;
        memset(&wrapper->stream, 0, sizeof(GPMF_stream));
    }
    return wrapper;
}

// Function to free a stream wrapper
void free_stream_wrapper(GPMFStreamWrapper* wrapper) {
    if (wrapper) {
        free(wrapper);
    }
}

// FFI Functions

size_t open_mp4_source(const char* filename, uint32_t trak_type, uint32_t trak_subtype, uint32_t index) {
    printf("Debug: Attempting to open file: %s\n", filename);
    printf("Debug: trak_type: 0x%x, trak_subtype: 0x%x, index: %d\n", trak_type, trak_subtype, index);
    
    // Check if file exists and is readable
    FILE* test_file = fopen(filename, "rb");
    if (test_file == NULL) {
        printf("Debug: File does not exist or is not readable! errno: %d\n", errno);
        return 0;
    }
    fclose(test_file);
    printf("Debug: File exists and is readable\n");

    char* filename_copy = strdup(filename);
    printf("Debug: Created filename copy: %s\n", filename_copy);
    
    size_t result = OpenMP4Source(filename_copy, trak_type, trak_subtype, index);
    printf("Debug: OpenMP4Source result: %zu\n", result);
    
    free(filename_copy);
    printf("Debug: Freed filename copy\n");
    
    return result;
}

void close_source(size_t handle) {
    CloseSource(handle);
}

double get_duration(size_t handle) {
    return GetDuration(handle);
}

uint32_t get_number_payloads(size_t handle) {
    return GetNumberPayloads(handle);
}

uint32_t get_payload_size(size_t handle, uint32_t index) {
    return GetPayloadSize(handle, index);
}

size_t get_payload_resource(size_t mp4handle, size_t resHandle, uint32_t payloadsize) {
    return (size_t)GetPayloadResource(mp4handle, resHandle, payloadsize);
}

uint32_t* get_payload(size_t mp4handle, size_t resHandle, uint32_t index) {
    return GetPayload(mp4handle, resHandle, index);
}

uint32_t get_payload_time(size_t handle, uint32_t index, double* in_time, double* out_time) {
    return GetPayloadTime(handle, index, in_time, out_time);
}

// Video frame rate and count
uint32_t get_video_frame_rate_and_count(size_t handle, uint32_t* numer, uint32_t* demon) {
    return GetVideoFrameRateAndCount(handle, numer, demon);
}

// GPMF Stream operations
GPMFStreamWrapper* gpmf_init(uint32_t* buffer, uint32_t datasize) {
    GPMFStreamWrapper* wrapper = create_stream_wrapper(buffer, datasize);
    if (!wrapper) return NULL;
    
    GPMF_ERR err = GPMF_Init(&wrapper->stream, buffer, datasize);
    if (err != GPMF_OK) {
        free_stream_wrapper(wrapper);
        return NULL;
    }
    return wrapper;
}

GPMF_ERR gpmf_find_next(GPMFStreamWrapper* wrapper, uint32_t fourcc, GPMF_LEVELS recurse) {
    if (!wrapper) return GPMF_ERROR_MEMORY;
    return GPMF_FindNext(&wrapper->stream, fourcc, recurse);
}

GPMF_ERR gpmf_reset_state(GPMFStreamWrapper* wrapper) {
    if (!wrapper) return GPMF_ERROR_MEMORY;
    return GPMF_ResetState(&wrapper->stream);
}

uint32_t gpmf_key(GPMFStreamWrapper* wrapper) {
    if (!wrapper) return 0;
    return GPMF_Key(&wrapper->stream);
}

uint32_t gpmf_type(GPMFStreamWrapper* wrapper) {
    if (!wrapper) return 0;
    return GPMF_Type(&wrapper->stream);
}

uint32_t gpmf_struct_size(GPMFStreamWrapper* wrapper) {
    if (!wrapper) return 0;
    return GPMF_StructSize(&wrapper->stream);
}

uint32_t gpmf_elements_in_struct(GPMFStreamWrapper* wrapper) {
    if (!wrapper) return 0;
    return GPMF_ElementsInStruct(&wrapper->stream);
}

uint32_t gpmf_repeat(GPMFStreamWrapper* wrapper) {
    if (!wrapper) return 0;
    return GPMF_Repeat(&wrapper->stream);
}

uint32_t gpmf_raw_data_size(GPMFStreamWrapper* wrapper) {
    if (!wrapper) return 0;
    return GPMF_RawDataSize(&wrapper->stream);
}

void* gpmf_raw_data(GPMFStreamWrapper* wrapper) {
    if (!wrapper) return NULL;
    return GPMF_RawData(&wrapper->stream);
}

GPMF_ERR gpmf_scaled_data(GPMFStreamWrapper* wrapper, void* buffer, uint32_t buffer_size, 
                         uint32_t sample_offset, uint32_t read_samples, GPMF_SampleType type) {
    if (!wrapper) return GPMF_ERROR_MEMORY;
    return GPMF_ScaledData(&wrapper->stream, buffer, buffer_size, sample_offset, read_samples, type);
}

double get_gpmf_sample_rate(size_t mp4handle, uint32_t fourcc, uint32_t key, 
                           double* start_time, double* end_time) {
    mp4callbacks cbobject = {0};
    cbobject.mp4handle = mp4handle;
    cbobject.cbGetNumberPayloads = GetNumberPayloads;
    cbobject.cbGetPayload = GetPayload;
    cbobject.cbGetPayloadSize = GetPayloadSize;
    cbobject.cbGetPayloadResource = GetPayloadResource;
    cbobject.cbGetPayloadTime = GetPayloadTime;
    cbobject.cbFreePayloadResource = FreePayloadResource;
    cbobject.cbGetEditListOffsetRationalTime = GetEditListOffsetRationalTime;

    return GetGPMFSampleRate(cbobject, fourcc, key, GPMF_SAMPLE_RATE_PRECISE, start_time, end_time);
}

// Helper functions
uint32_t str_to_fourcc(const char* str) {
    if (!str || strlen(str) < 4) return 0;
    return (str[0] << 0) | (str[1] << 8) | (str[2] << 16) | (str[3] << 24);
}

void fourcc_to_str(uint32_t fourcc, char* str) {
    if (!str) return;
    str[0] = (fourcc >> 0) & 0xFF;
    str[1] = (fourcc >> 8) & 0xFF;
    str[2] = (fourcc >> 16) & 0xFF;
    str[3] = (fourcc >> 24) & 0xFF;
    str[4] = '\0';
}

int is_valid_fourcc(uint32_t fourcc) {
    char c1 = (fourcc >> 0) & 0xFF;
    char c2 = (fourcc >> 8) & 0xFF;
    char c3 = (fourcc >> 16) & 0xFF;
    char c4 = (fourcc >> 24) & 0xFF;

    return (((c4 >= 'a' && c4 <= 'z') || (c4 >= 'A' && c4 <= 'Z') || (c4 >= '0' && c4 <= '9') || c4 == ' ') &&
            ((c3 >= 'a' && c3 <= 'z') || (c3 >= 'A' && c3 <= 'Z') || (c3 >= '0' && c3 <= '9') || c3 == ' ') &&
            ((c2 >= 'a' && c2 <= 'z') || (c2 >= 'A' && c2 <= 'Z') || (c2 >= '0' && c2 <= '9') || c2 == ' ') &&
            ((c1 >= 'a' && c1 <= 'z') || (c1 >= 'A' && c1 <= 'Z') || (c1 >= '0' && c1 <= '9') || c1 == ' '));
} 
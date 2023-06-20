#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
typedef struct _Dart_Handle* Dart_Handle;

typedef struct DartCObject DartCObject;

typedef int64_t DartPort;

typedef bool (*DartPostCObjectFnType)(DartPort port_id, void *message);

typedef struct wire_uint_8_list {
  uint8_t *ptr;
  int32_t len;
} wire_uint_8_list;

typedef struct wire_TransmissionToken {
  struct wire_uint_8_list *token;
  struct wire_uint_8_list *url;
} wire_TransmissionToken;

typedef struct wire_Tokens {
  struct wire_uint_8_list *token;
  struct wire_TransmissionToken transmission;
} wire_Tokens;

typedef struct DartCObject *WireSyncReturn;

void store_dart_post_cobject(DartPostCObjectFnType ptr);

Dart_Handle get_dart_object(uintptr_t ptr);

void drop_dart_object(uintptr_t ptr);

uintptr_t new_dart_opaque(Dart_Handle handle);

intptr_t init_frb_dart_api_dl(void *obj);

void wire_start_native(int64_t port_,
                       struct wire_uint_8_list *storage_path,
                       struct wire_uint_8_list *portal_base_url);

void wire_get_my_stations(int64_t port_);

void wire_authenticate_portal(int64_t port_,
                              struct wire_uint_8_list *email,
                              struct wire_uint_8_list *password);

void wire_clear_calibration(int64_t port_, struct wire_uint_8_list *device_id, uintptr_t module);

void wire_calibrate(int64_t port_,
                    struct wire_uint_8_list *device_id,
                    uintptr_t module,
                    struct wire_uint_8_list *data);

void wire_validate_tokens(int64_t port_, struct wire_Tokens *tokens);

void wire_start_download(int64_t port_, struct wire_uint_8_list *device_id);

void wire_start_upload(int64_t port_,
                       struct wire_uint_8_list *device_id,
                       struct wire_Tokens *tokens);

void wire_cache_firmware(int64_t port_, struct wire_Tokens *tokens);

void wire_rust_release_mode(int64_t port_);

void wire_create_log_sink(int64_t port_);

struct wire_Tokens *new_box_autoadd_tokens_0(void);

struct wire_uint_8_list *new_uint_8_list_0(int32_t len);

void free_WireSyncReturn(WireSyncReturn ptr);

static int64_t dummy_method_to_enforce_bundling(void) {
    int64_t dummy_var = 0;
    dummy_var ^= ((int64_t) (void*) wire_start_native);
    dummy_var ^= ((int64_t) (void*) wire_get_my_stations);
    dummy_var ^= ((int64_t) (void*) wire_authenticate_portal);
    dummy_var ^= ((int64_t) (void*) wire_clear_calibration);
    dummy_var ^= ((int64_t) (void*) wire_calibrate);
    dummy_var ^= ((int64_t) (void*) wire_validate_tokens);
    dummy_var ^= ((int64_t) (void*) wire_start_download);
    dummy_var ^= ((int64_t) (void*) wire_start_upload);
    dummy_var ^= ((int64_t) (void*) wire_cache_firmware);
    dummy_var ^= ((int64_t) (void*) wire_rust_release_mode);
    dummy_var ^= ((int64_t) (void*) wire_create_log_sink);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_tokens_0);
    dummy_var ^= ((int64_t) (void*) new_uint_8_list_0);
    dummy_var ^= ((int64_t) (void*) free_WireSyncReturn);
    dummy_var ^= ((int64_t) (void*) store_dart_post_cobject);
    dummy_var ^= ((int64_t) (void*) get_dart_object);
    dummy_var ^= ((int64_t) (void*) drop_dart_object);
    dummy_var ^= ((int64_t) (void*) new_dart_opaque);
    return dummy_var;
}

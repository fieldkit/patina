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

typedef struct wire_AddOrUpdatePortalStation {
  struct wire_uint_8_list *name;
  struct wire_uint_8_list *device_id;
  struct wire_uint_8_list *location_name;
  struct wire_uint_8_list *status_pb;
} wire_AddOrUpdatePortalStation;

typedef struct wire_WifiNetworkConfig {
  uintptr_t index;
  struct wire_uint_8_list *ssid;
  struct wire_uint_8_list *password;
  bool preferred;
  bool keeping;
} wire_WifiNetworkConfig;

typedef struct wire_list_wifi_network_config {
  struct wire_WifiNetworkConfig *ptr;
  int32_t len;
} wire_list_wifi_network_config;

typedef struct wire_WifiNetworksConfig {
  struct wire_list_wifi_network_config *networks;
} wire_WifiNetworksConfig;

typedef struct wire_Schedule_Every {
  uint32_t field0;
} wire_Schedule_Every;

typedef union ScheduleKind {
  struct wire_Schedule_Every *Every;
} ScheduleKind;

typedef struct wire_Schedule {
  int32_t tag;
  union ScheduleKind *kind;
} wire_Schedule;

typedef struct wire_WifiTransmissionConfig {
  struct wire_Tokens *tokens;
  struct wire_Schedule *schedule;
} wire_WifiTransmissionConfig;

typedef struct wire_LoraTransmissionConfig {
  uint32_t *band;
  struct wire_uint_8_list *app_key;
  struct wire_uint_8_list *join_eui;
  struct wire_Schedule *schedule;
} wire_LoraTransmissionConfig;

typedef struct wire_RecordArchive {
  struct wire_uint_8_list *device_id;
  struct wire_uint_8_list *path;
  int64_t head;
  int64_t tail;
} wire_RecordArchive;

typedef struct wire_list_record_archive {
  struct wire_RecordArchive *ptr;
  int32_t len;
} wire_list_record_archive;

typedef struct wire_LocalFirmware {
  int64_t id;
  struct wire_uint_8_list *label;
  int64_t time;
  struct wire_uint_8_list *module;
  struct wire_uint_8_list *profile;
} wire_LocalFirmware;

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

void wire_add_or_update_station_in_portal(int64_t port_,
                                          struct wire_Tokens *tokens,
                                          struct wire_AddOrUpdatePortalStation *station);

void wire_configure_wifi_networks(int64_t port_,
                                  struct wire_uint_8_list *device_id,
                                  struct wire_WifiNetworksConfig *config);

void wire_configure_wifi_transmission(int64_t port_,
                                      struct wire_uint_8_list *device_id,
                                      struct wire_WifiTransmissionConfig *config);

void wire_configure_lora_transmission(int64_t port_,
                                      struct wire_uint_8_list *device_id,
                                      struct wire_LoraTransmissionConfig *config);

void wire_clear_calibration(int64_t port_, struct wire_uint_8_list *device_id, uintptr_t module);

void wire_calibrate(int64_t port_,
                    struct wire_uint_8_list *device_id,
                    uintptr_t module,
                    struct wire_uint_8_list *data);

void wire_validate_tokens(int64_t port_, struct wire_Tokens *tokens);

void wire_start_download(int64_t port_, struct wire_uint_8_list *device_id, uint64_t *first);

void wire_start_upload(int64_t port_,
                       struct wire_uint_8_list *device_id,
                       struct wire_Tokens *tokens,
                       struct wire_list_record_archive *files);

void wire_cache_firmware(int64_t port_, struct wire_Tokens *tokens);

void wire_upgrade_station(int64_t port_,
                          struct wire_uint_8_list *device_id,
                          struct wire_LocalFirmware *firmware,
                          bool swap);

void wire_rust_release_mode(int64_t port_);

void wire_create_log_sink(int64_t port_);

struct wire_AddOrUpdatePortalStation *new_box_autoadd_add_or_update_portal_station_0(void);

struct wire_LocalFirmware *new_box_autoadd_local_firmware_0(void);

struct wire_LoraTransmissionConfig *new_box_autoadd_lora_transmission_config_0(void);

struct wire_Schedule *new_box_autoadd_schedule_0(void);

struct wire_Tokens *new_box_autoadd_tokens_0(void);

uint32_t *new_box_autoadd_u32_0(uint32_t value);

uint64_t *new_box_autoadd_u64_0(uint64_t value);

struct wire_WifiNetworksConfig *new_box_autoadd_wifi_networks_config_0(void);

struct wire_WifiTransmissionConfig *new_box_autoadd_wifi_transmission_config_0(void);

struct wire_list_record_archive *new_list_record_archive_0(int32_t len);

struct wire_list_wifi_network_config *new_list_wifi_network_config_0(int32_t len);

struct wire_uint_8_list *new_uint_8_list_0(int32_t len);

union ScheduleKind *inflate_Schedule_Every(void);

void free_WireSyncReturn(WireSyncReturn ptr);

static int64_t dummy_method_to_enforce_bundling(void) {
    int64_t dummy_var = 0;
    dummy_var ^= ((int64_t) (void*) wire_start_native);
    dummy_var ^= ((int64_t) (void*) wire_get_my_stations);
    dummy_var ^= ((int64_t) (void*) wire_authenticate_portal);
    dummy_var ^= ((int64_t) (void*) wire_add_or_update_station_in_portal);
    dummy_var ^= ((int64_t) (void*) wire_configure_wifi_networks);
    dummy_var ^= ((int64_t) (void*) wire_configure_wifi_transmission);
    dummy_var ^= ((int64_t) (void*) wire_configure_lora_transmission);
    dummy_var ^= ((int64_t) (void*) wire_clear_calibration);
    dummy_var ^= ((int64_t) (void*) wire_calibrate);
    dummy_var ^= ((int64_t) (void*) wire_validate_tokens);
    dummy_var ^= ((int64_t) (void*) wire_start_download);
    dummy_var ^= ((int64_t) (void*) wire_start_upload);
    dummy_var ^= ((int64_t) (void*) wire_cache_firmware);
    dummy_var ^= ((int64_t) (void*) wire_upgrade_station);
    dummy_var ^= ((int64_t) (void*) wire_rust_release_mode);
    dummy_var ^= ((int64_t) (void*) wire_create_log_sink);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_add_or_update_portal_station_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_local_firmware_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_lora_transmission_config_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_schedule_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_tokens_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_u32_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_u64_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_wifi_networks_config_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_wifi_transmission_config_0);
    dummy_var ^= ((int64_t) (void*) new_list_record_archive_0);
    dummy_var ^= ((int64_t) (void*) new_list_wifi_network_config_0);
    dummy_var ^= ((int64_t) (void*) new_uint_8_list_0);
    dummy_var ^= ((int64_t) (void*) inflate_Schedule_Every);
    dummy_var ^= ((int64_t) (void*) free_WireSyncReturn);
    dummy_var ^= ((int64_t) (void*) store_dart_post_cobject);
    dummy_var ^= ((int64_t) (void*) get_dart_object);
    dummy_var ^= ((int64_t) (void*) drop_dart_object);
    dummy_var ^= ((int64_t) (void*) new_dart_opaque);
    return dummy_var;
}

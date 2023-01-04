package io.mosip.tuvali.ble.central.state.message

abstract class IMessage(val commandType: CentralStates) {
  enum class CentralStates {
    SCAN_START,
    SCAN_STOP,
    SCAN_START_FAILURE,

    DEVICE_FOUND,
    CONNECT_DEVICE,
    DISCONNECT_DEVICE,
    DEVICE_CONNECTED,
    DEVICE_DISCONNECTED,

    DISCOVER_SERVICES,
    DISCOVER_SERVICES_SUCCESS,
    DISCOVER_SERVICES_FAILURE,

    REQUEST_MTU,
    REQUEST_MTU_SUCCESS,
    REQUEST_MTU_FAILURE,

    WRITE,
    WRITE_SUCCESS,
    WRITE_FAILURE,

    READ,
    READ_SUCCESS,
    READ_FAILURE,

    SUBSCRIBE,
    SUBSCRIBE_SUCCESS,
    SUBSCRIBE_FAILURE,
    UNSUBSCRIBE,
    UNSUBSCRIBE_SUCCESS,
    UNSUBSCRIBE_FAILURE,
    NOTIFICATION_RECEIVED,

    CLOSE
  }
}
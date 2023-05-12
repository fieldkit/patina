import 'package:flutter/foundation.dart';
import 'ffi.dart' if (dart.library.html) 'ffi_web.dart';

// import 'package:timeline/bridge_generated.dart';
// import 'package:timeline/common/models/phase_info.dart';

/// Global event dispatcher. All components are supposed to dispatch their events via this class.
class AppEventDispatcher {
  final List<_Listener> _listeners = [];

  void dispatch(DomainMessage m) {
    for (var listener in List.from(_listeners)) {
      try {
        if (listener.test(m)) {
          listener.callback(m);
        }
      } catch (e) {
        debugPrint("Failed to push event: $e");
      }
    }
  }

  void addListener<T>(Function(T) callback) {
    _listeners.add(_Listener(
      (event) => event is T,
      (event) => callback(event as T),
      callback.hashCode,
    ));
  }

  void removeListener<T>(Function(T) callback) {
    _listeners.removeWhere(
        (listener) => listener.callbackHashCode == callback.hashCode);
  }
}

class _Listener {
  final bool Function(DomainMessage) test;
  final Function(DomainMessage) callback;
  final int callbackHashCode;

  _Listener(this.test, this.callback, this.callbackHashCode);
}
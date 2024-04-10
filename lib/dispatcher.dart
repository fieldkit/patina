import 'diagnostics.dart';
import 'gen/api.dart';

/// Global event dispatcher. All components are supposed to dispatch their events via this class.
class AppEventDispatcher {
  final List<_Listener> _listeners = [];

  void dispatch(DomainMessage m) {
    for (var listener in List.from(_listeners)) {
      try {
        if (listener.test(m)) {
          listener.callback(m);
        }
      } catch (err) {
        Loggers.main.e("Failed to push $m: $err ($listener)");
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

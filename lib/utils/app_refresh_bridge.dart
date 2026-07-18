/// Tiny pub-sub so notification actions can refresh visible UI without
/// creating circular imports between services and screens.
class AppRefreshBridge {
  /// Private constructor — static API only.
  const AppRefreshBridge._();

  static final Set<VoidCallback> _listeners = {};

  /// Registers a reload callback (typically from [HomeScreen]).
  static void bind(VoidCallback listener) => _listeners.add(listener);

  /// Unregisters a reload callback.
  static void unbind(VoidCallback listener) => _listeners.remove(listener);

  /// Invokes all registered reload callbacks.
  static void notify() {
    for (final listener in Set<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  /// Clears all listeners (used by widget-test tearDown).
  static void clear() => _listeners.clear();
}

/// Signature alias kept local to avoid importing Flutter in this file.
typedef VoidCallback = void Function();

import 'package:flutter/foundation.dart';

/// A cache layer for rendered Mermaid diagrams.
///
/// This singleton caches PNG image data keyed by the diagram source string,
/// avoiding redundant re-rendering when widgets are rebuilt (e.g., in
/// virtualized lists).
///
/// Example:
/// ```dart
/// // Clear cache on conversation switch
/// MermaidCache.instance.clear();
///
/// // Remove a specific diagram from cache
/// MermaidCache.instance.remove(diagramSource);
///
/// // Check cache statistics
/// print('Cached diagrams: ${MermaidCache.instance.size}');
/// ```
final class MermaidCache {
  MermaidCache._();

  static final MermaidCache _instance = MermaidCache._();

  /// The singleton instance of [MermaidCache].
  static MermaidCache get instance => _instance;

  final Map<String, Uint8List> _cache = {};

  /// Returns true if the diagram is cached.
  bool contains(String diagram) => _cache.containsKey(_normalizeKey(diagram));

  /// Gets the cached image data for a diagram, or null if not cached.
  Uint8List? get(String diagram) => _cache[_normalizeKey(diagram)];

  /// Stores the rendered image data for a diagram.
  void put(String diagram, Uint8List imageData) {
    final key = _normalizeKey(diagram);
    if (!_cache.containsKey(key)) {
      _cache[key] = imageData;
    }
  }

  /// Number of diagrams currently stored in the cache.
  int get size => _cache.length;

  /// Removes a single diagram from the cache.
  void remove(String diagram) {
    _cache.remove(_normalizeKey(diagram));
  }

  /// Clears all cached diagrams.
  ///
  /// Call this when switching conversations or when you want to free memory.
  void clear() {
    if (_cache.isNotEmpty) {
      _cache.clear();
    }
  }

  String _normalizeKey(String diagram) => diagram.trim();
}

import 'package:collection/collection.dart';

/// List of supported chat providers
enum ChatProviders {
  chatGPT,
  zohoSalesiq;

  @override
  String toString() {
    return name;
  }

  static ChatProviders? fromString(String? name) {
    try {
      return ChatProviders.values.firstWhereOrNull(
        (e) => e.name == name,
      );
    } catch (e) {
      return null;
    }
  }
}

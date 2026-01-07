/// Abstract base class for objects that can be used with Field definitions.
/// This helps break circular dependencies between Field and MoneyObject.
abstract class DataInterface {
  /// All objects must have a unique identifier
  int get uniqueId;
  set uniqueId(int value);
}

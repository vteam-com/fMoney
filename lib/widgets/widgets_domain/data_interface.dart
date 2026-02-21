/// Abstract base class for objects that can be used with Field definitions.
/// This helps break circular dependencies between Field and MoneyObject.
abstract class DataInterface {
  /// Gets the unique identifier for this object.
  int get uniqueId;

  /// Sets the unique identifier for this object.
  set uniqueId(int value);
}

class PairDynamicDynamic {
  PairDynamicDynamic({required this.key, required this.value});

  dynamic key;
  dynamic value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PairDynamicDynamic) {
      return false;
    }

    return key == other.key && value == other.value;
  }

  @override
  int get hashCode => Object.hash(key, value);

  @override
  String toString() {
    return '$key:$value';
  }
}

class PairStringDouble {
  PairStringDouble({required this.key, required this.value});

  String key;
  double value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PairStringDouble) {
      return false;
    }

    return key == other.key && value == other.value;
  }

  @override
  int get hashCode => Object.hash(key, value);

  @override
  String toString() {
    return '$key:$value';
  }
}

class PairIntDouble {
  PairIntDouble({required this.key, required this.value});

  int key;
  double value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PairIntDouble) {
      return false;
    }

    return key == other.key && value == other.value;
  }

  @override
  int get hashCode => Object.hash(key, value);

  @override
  String toString() {
    return '$key:$value';
  }
}

class Pair<F, S> {
  Pair(this.first, this.second);

  F first;
  S second;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Pair<F, S> && other.first == first && other.second == second;
  }

  @override
  int get hashCode => first.hashCode ^ second.hashCode;

  @override
  String toString() => '($first, $second)';
}

class Triple<F, S, T> {
  Triple(this.first, this.second, this.third);

  F first;
  S second;
  T third;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Triple<F, S, T> && other.first == first && other.second == second && other.third == third;
  }

  @override
  int get hashCode => first.hashCode ^ second.hashCode ^ third.hashCode;

  @override
  String toString() => '($first, $second, $third)';
}

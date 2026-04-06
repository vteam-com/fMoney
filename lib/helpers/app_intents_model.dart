// ignore: fcheck_one_class_per_file

import 'package:flutter/widgets.dart';

/// Intent for rebalancing accounts
class RebalanceIntent extends Intent {
  const RebalanceIntent();
}

/// Intent for zooming in
class ZoomInIntent extends Intent {
  const ZoomInIntent();
}

/// Intent for zooming out
class ZoomOutIntent extends Intent {
  const ZoomOutIntent();
}

/// Intent for resetting zoom
class ZoomResetIntent extends Intent {
  const ZoomResetIntent();
}

/// Intent for creating new transaction
class NewTransactionIntent extends Intent {
  const NewTransactionIntent();
}

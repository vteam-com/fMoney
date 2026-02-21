// ignore: fcheck_one_class_per_file
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Base controller for managing scrollable list state.
/// Features:
/// - Track scroll position
/// - Bookmark positions
/// - Scroll to top/bottom
/// - Animated scrolling
class ListController extends GetxController {
  final ScrollController scrollController = ScrollController();
  final RxDouble scrollPosition = 0.0.obs;

  double bookmark = -1;

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    scrollController.addListener(_scrollListener);
    super.onInit();
  }

  /// Returns scroll offset for the specified index.
  double getOffsetOfIndex(final int index, final int numberOfItems) {
    final double itemHeight = scrollController.position.maxScrollExtent / numberOfItems;
    return itemHeight * index;
  }

  /// Scrolls to the bookmarked position.
  void scrollToBookmark() {
    if (bookmark != -1) {
      scrollController.animateTo(
        bookmark,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Scrolls to the bottom of the list.
  void scrollToBottom() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// Scrolls to the specified index.
  void scrollToIndex(final int index, final int numberOfItems) {
    scrollToOffSet(getOffsetOfIndex(index, numberOfItems));
  }

  /// Scrolls to the specified offset.
  void scrollToOffSet(final double offset) {
    scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// Scrolls to the top of the list.
  void scrollToTop() {
    scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollListener() {
    scrollPosition.value = scrollController.offset;
  }
}

/// List controller specialized for main content area
class ListControllerMain extends ListController {}

/// List controller specialized for side panel content
class ListControllerSidePanel extends ListController {}

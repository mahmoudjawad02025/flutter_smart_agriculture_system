import 'package:flutter/material.dart';

/// Shows [pageSize] items initially, then loads [pageSize] more when the user
/// scrolls to the bottom (shows a [CircularProgressIndicator] while loading).
class PaginatedListView extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.pageSize = 10,
    this.padding,
    this.header,
    this.separatorBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int pageSize;
  final EdgeInsetsGeometry? padding;
  final Widget? header;
  final IndexedWidgetBuilder? separatorBuilder;

  @override
  State<PaginatedListView> createState() => _PaginatedListViewState();
}

class _PaginatedListViewState extends State<PaginatedListView> {
  static const Duration _loadDelay = Duration(milliseconds: 350);

  late int _visibleCount;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _visibleCount = _initialVisibleCount();
  }

  @override
  void didUpdateWidget(covariant PaginatedListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      _visibleCount = _initialVisibleCount();
      _isLoadingMore = false;
    }
  }

  int _initialVisibleCount() {
    if (widget.itemCount <= 0) return 0;
    return widget.itemCount < widget.pageSize
        ? widget.itemCount
        : widget.pageSize;
  }

  bool get _hasMore => _visibleCount < widget.itemCount;

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    if (mounted) setState(() {});

    await Future<void>.delayed(_loadDelay);
    if (!mounted) return;

    setState(() {
      _visibleCount = (_visibleCount + widget.pageSize).clamp(
        0,
        widget.itemCount,
      );
      _isLoadingMore = false;
    });
  }

  Widget _buildLoaderFooter() {
    if (!_hasMore) return const SizedBox.shrink();

    if (!_isLoadingMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMore();
      });
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSeparator = widget.separatorBuilder != null;
    final int listItemCount = _visibleCount + (_hasMore ? 1 : 0);

    return ListView.separated(
      padding: widget.padding,
      itemCount: (widget.header == null ? 0 : 1) + listItemCount,
      separatorBuilder: (BuildContext context, int index) {
        if (widget.header != null && index == 0) {
          return const SizedBox(height: 16);
        }
        if (!hasSeparator) return const SizedBox.shrink();
        final int listIndex = widget.header == null ? index : index - 1;
        if (listIndex >= _visibleCount - 1) {
          return const SizedBox.shrink();
        }
        return widget.separatorBuilder!(context, listIndex);
      },
      itemBuilder: (BuildContext context, int index) {
        if (widget.header != null && index == 0) {
          return widget.header!;
        }

        final int listIndex = widget.header == null ? index : index - 1;
        if (listIndex >= _visibleCount) {
          return _buildLoaderFooter();
        }
        return widget.itemBuilder(context, listIndex);
      },
    );
  }
}

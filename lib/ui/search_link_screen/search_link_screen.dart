import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:openreads/core/constants/enums/enums.dart';
import 'package:openreads/core/themes/app_theme.dart';
import 'package:openreads/generated/locale_keys.g.dart';
import 'package:openreads/logic/cubit/edit_book_cubit.dart';
import 'package:openreads/model/reading.dart';
import 'package:openreads/model/book.dart';
import 'package:openreads/model/web_search_result.dart';
import 'package:openreads/resources/web_link_service.dart';
import 'package:openreads/ui/add_book_screen/add_book_screen.dart';
import 'package:openreads/ui/add_book_screen/widgets/widgets.dart';
import 'package:openreads/ui/common/keyboard_dismissable.dart';
import 'package:openreads/ui/search_link_screen/widgets/book_card_web.dart';

class SearchLinkScreen extends StatefulWidget {
  const SearchLinkScreen({
    super.key,
    required this.status,
  });

  final BookStatus status;

  @override
  State<SearchLinkScreen> createState() => _SearchLinkScreenState();
}

class _SearchLinkScreenState extends State<SearchLinkScreen>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  int offset = 0;
  final _pageSize = 10;
  String? _searchTerm;
  int? numberOfResults;
  ScanResult? scanResult;
  int searchTimestamp = 0;

  bool searchActivated = false;

  final _pagingController = PagingController<int, WebSearchResultDoc>(
    firstPageKey: 0,
  );

  void _saveNoEdition(WebSearchResultDoc searchResult) {
    final book = Book(
      title: searchResult.name == null ? '' : searchResult.name!,
      subtitle: null,
      author: searchResult.author == null ? '' : searchResult.author!,
      description: searchResult.description,
      rating: searchResult.aggregateRating == null ? null : (searchResult.aggregateRating! * 10).toInt(),
      status: widget.status,
      pages: searchResult.numberOfPages,
      publicationYear: searchResult.datePublished?.year,
      isbn: searchResult.isbn,
      //bookFormat: searchResult.bookFormat,
      readings: List<Reading>.empty(growable: true),
      tags: LocaleKeys.owned_book_tag.tr(),
      dateAdded: DateTime.now(),
      dateModified: DateTime.now(),
    );

    context.read<EditBookCubit>().setBook(book);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddBookScreen(
          fromWebUrl: true,
          coverWebUrl: searchResult.image,
        ),
      ),
    );
  }

  Future<void> _fetchPage(int pageKey) async {
    final searchTimestampSaved = DateTime.now().millisecondsSinceEpoch;
    searchTimestamp = searchTimestampSaved;

    try {
      if (_searchTerm == null) return;

      final newItems = await WebLinkService().getResults(
        rawUrl: _searchTerm!,
      );

      // Used to cancel the request if a new search is started
      // to avoid showing results from a previous search
      if (searchTimestamp != searchTimestampSaved) return;

      setState(() {
        numberOfResults = newItems.numFound;
      });

      final isLastPage = newItems.docs.length < _pageSize;

      if (isLastPage) {
        if (!mounted) return;
        _pagingController.appendLastPage(newItems.docs);
      } else {
        final nextPageKey = pageKey + newItems.docs.length;
        if (!mounted) return;
        _pagingController.appendPage(newItems.docs, nextPageKey);
      }
    } catch (error) {
      if (!mounted) return;
      _pagingController.error = error;
    }
  }

  void _startNewSearch() {
    if (_searchController.text.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      searchActivated = true;
    });

    _searchTerm = _searchController.text;
    _pagingController.refresh();
  }

  // Used when search results are empty
  _addBookManually() {
    FocusManager.instance.primaryFocus?.unfocus();

    final book = Book(
      title: '',
      author: '',
      status: BookStatus.read,
      isbn: null,
      readings: List<Reading>.empty(growable: true),
      tags: 'owned',
      dateAdded: DateTime.now(),
      dateModified: DateTime.now(),
    );

    context.read<EditBookCubit>().setBook(book);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddBookScreen(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return KeyboardDismissible(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            LocaleKeys.add_link.tr(),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 10, 5),
              child: Row(
                children: [
                  Expanded(
                    child: BookTextField(
                      controller: _searchController,
                      keyboardType: TextInputType.url,
                      maxLength: 999,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      textCapitalization: TextCapitalization.none,
                      onSubmitted: (_) => _startNewSearch(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _startNewSearch,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(cornerRadius),
                        ),
                      ),
                      child: Text(
                        LocaleKeys.search.tr(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Divider(height: 3),
            ),
            (numberOfResults != null && numberOfResults! != 0)
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$numberOfResults ${LocaleKeys.results_lowercase.tr()}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
            Expanded(
              child: (!searchActivated)
                  ? const SizedBox()
                  : Scrollbar(
                      child: PagedListView<int, WebSearchResultDoc>(
                        pagingController: _pagingController,
                        builderDelegate:
                            PagedChildBuilderDelegate<WebSearchResultDoc>(
                          firstPageProgressIndicatorBuilder: (_) => Center(
                            child: LoadingAnimationWidget.staggeredDotsWave(
                              color: Theme.of(context).colorScheme.primary,
                              size: 42,
                            ),
                          ),
                          newPageProgressIndicatorBuilder: (_) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: LoadingAnimationWidget.staggeredDotsWave(
                                color: Theme.of(context).colorScheme.primary,
                                size: 42,
                              ),
                            ),
                          ),
                          noItemsFoundIndicatorBuilder: (_) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(
                                    cornerRadius,
                                  ),
                                  onTap: _addBookManually,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      children: [
                                        Text(
                                          LocaleKeys.no_search_results.tr(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          LocaleKeys.click_to_add_book_manually
                                              .tr(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (context, item, index) =>
                              Builder(builder: (context) {
                            return BookCardWeb(
                              title: item.name ?? '',
                              subtitle: null,
                              author: (item.author != null &&
                                      item.author!.isNotEmpty)
                                  ? item.author!
                                  : '',
                              coverUrl: item.image,
                              pagesMedian: item.numberOfPages,
                              firstPublishYear: item.datePublished?.year,
                              onAddBookPressed: () => _saveNoEdition(item),
                            );
                          }),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

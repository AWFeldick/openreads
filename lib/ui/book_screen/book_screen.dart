import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:openreads/core/themes/app_theme.dart';
import 'package:openreads/logic/bloc/theme_bloc/theme_bloc.dart';
import 'package:openreads/logic/cubit/book_cubit.dart';
import 'package:openreads/model/book.dart';
import 'package:openreads/ui/add_book_screen/widgets/widgets.dart';
import 'package:openreads/ui/book_screen/widgets/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BookScreen extends StatelessWidget {
  BookScreen({
    Key? key,
    required this.id,
    required this.heroTag,
  }) : super(key: key);

  final int id;
  final String heroTag;
  Book? book;

  Future<bool?> _onLikeTap(isLiked) async {
    if (book == null) return isLiked;

    bookCubit.updateBook(Book(
      id: book!.id,
      title: book!.title,
      author: book!.author,
      status: book!.status,
      favourite: !isLiked,
      rating: book!.rating,
      startDate: book!.startDate,
      finishDate: book!.finishDate,
      pages: book!.pages,
      publicationYear: book!.publicationYear,
      isbn: book!.isbn,
      olid: book!.olid,
      tags: book!.tags,
      myReview: book!.myReview,
      cover: book!.cover,
      blurHash: book!.blurHash,
    ));

    return !isLiked;
  }

  _showDeleteDialog(BuildContext context, bool deleted) {
    if (book == null) return;

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
                  Theme.of(context).extension<CustomBorder>()?.radius ??
                      BorderRadius.circular(5.0),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Text(
              deleted
                  ? AppLocalizations.of(context)!.delete_book_question
                  : AppLocalizations.of(context)!.restore_book_question,
              style: TextStyle(
                fontSize: 18,
                fontFamily: context.read<ThemeBloc>().fontFamily,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        Theme.of(context).extension<CustomBorder>()?.radius ??
                            BorderRadius.circular(5.0),
                    side: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "No",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontFamily: context.read<ThemeBloc>().fontFamily,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _changeDeleteStatus(deleted);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        Theme.of(context).extension<CustomBorder>()?.radius ??
                            BorderRadius.circular(5.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "Yes",
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: context.read<ThemeBloc>().fontFamily,
                    ),
                  ),
                ),
              ),
            ],
          );
        });
  }

  Future<void> _changeDeleteStatus(bool deleted) async {
    await bookCubit.updateBook(Book(
      id: book!.id,
      title: book!.title,
      subtitle: book!.subtitle,
      author: book!.author,
      status: book!.status,
      favourite: book!.favourite,
      deleted: deleted,
      rating: book!.rating,
      startDate: book!.startDate,
      finishDate: book!.finishDate,
      pages: book!.pages,
      publicationYear: book!.publicationYear,
      isbn: book!.isbn,
      olid: book!.olid,
      tags: book!.tags,
      myReview: book!.myReview,
      cover: book!.cover,
      blurHash: book!.blurHash,
    ));

    bookCubit.getDeletedBooks();
  }

  IconData? _decideStatusIcon(int? status) {
    if (status == 0) {
      return Icons.done;
    } else if (status == 1) {
      return Icons.autorenew;
    } else if (status == 2) {
      return Icons.timelapse;
    } else if (status == 3) {
      return Icons.not_interested;
    } else {
      return null;
    }
  }

  String _decideStatusText(int? status, BuildContext context) {
    if (status == 0) {
      return AppLocalizations.of(context)!.book_status_finished;
    } else if (status == 1) {
      return AppLocalizations.of(context)!.book_status_in_progress;
    } else if (status == 2) {
      return AppLocalizations.of(context)!.book_status_for_later;
    } else if (status == 3) {
      return AppLocalizations.of(context)!.book_status_unfinished;
    } else {
      return '';
    }
  }

  String? _decideChangeStatusText(int? status, BuildContext context) {
    if (status == 1) {
      return AppLocalizations.of(context)!.finish_reading;
    } else if (status == 2) {
      return AppLocalizations.of(context)!.start_reading;
    } else if (status == 3) {
      return AppLocalizations.of(context)!.start_reading;
    } else {
      return null;
    }
  }

  void _changeStatusAction(BuildContext context, int status) async {
    final dateNow = DateTime.now();
    final date = DateTime(dateNow.year, dateNow.month, dateNow.day);

    if (status == 1) {
      int? rating;

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius:
                  Theme.of(context).extension<CustomBorder>()?.radius ??
                      BorderRadius.circular(5.0),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Text(
              AppLocalizations.of(context)!.rate_book,
              style: TextStyle(
                fontSize: 18,
                fontFamily: context.read<ThemeBloc>().fontFamily,
              ),
            ),
            children: [
              BookRatingBar(
                animDuration: const Duration(milliseconds: 250),
                status: 0,
                defaultHeight: 60.0,
                rating: 0.0,
                onRatingUpdate: (double newRating) {
                  rating = (newRating * 10).toInt();
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      rating = null;
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      AppLocalizations.of(context)!.skip,
                      style: TextStyle(
                        fontFamily: context.read<ThemeBloc>().fontFamily,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Theme.of(context).mainTextColor,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      AppLocalizations.of(context)!.save,
                      style: TextStyle(
                        fontFamily: context.read<ThemeBloc>().fontFamily,
                      ),
                    ),
                  )
                ],
              )
            ],
          );
        },
      );

      bookCubit.updateBook(Book(
        id: book!.id,
        title: book!.title,
        author: book!.author,
        status: 0,
        favourite: book!.favourite,
        rating: rating,
        startDate: book!.startDate,
        finishDate: date.toIso8601String(),
        pages: book!.pages,
        publicationYear: book!.publicationYear,
        isbn: book!.isbn,
        olid: book!.olid,
        tags: book!.tags,
        myReview: book!.myReview,
        cover: book!.cover,
        blurHash: book!.blurHash,
      ));
    } else if (status == 2) {
      bookCubit.updateBook(Book(
        id: book!.id,
        title: book!.title,
        author: book!.author,
        status: 1,
        favourite: book!.favourite,
        rating: book!.rating,
        startDate: date.toIso8601String(),
        finishDate: book!.finishDate,
        pages: book!.pages,
        publicationYear: book!.publicationYear,
        isbn: book!.isbn,
        olid: book!.olid,
        tags: book!.tags,
        myReview: book!.myReview,
        cover: book!.cover,
        blurHash: book!.blurHash,
      ));
    } else if (status == 3) {
      bookCubit.updateBook(Book(
        id: book!.id,
        title: book!.title,
        author: book!.author,
        status: 1,
        favourite: book!.favourite,
        rating: book!.rating,
        startDate: date.toIso8601String(),
        finishDate: book!.finishDate,
        pages: book!.pages,
        publicationYear: book!.publicationYear,
        isbn: book!.isbn,
        olid: book!.olid,
        tags: book!.tags,
        myReview: book!.myReview,
        cover: book!.cover,
        blurHash: book!.blurHash,
      ));
    }
  }

  String? _generateDate(String? date) {
    if (date == null) return null;

    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(DateTime.parse(date));
  }

  String _generateReadingTime({
    required String startDate,
    required String finishDate,
    required BuildContext context,
  }) {
    final diff = DateTime.parse(finishDate)
        .difference(DateTime.parse(startDate))
        .inDays
        .toString();

    return '$diff ${AppLocalizations.of(context)!.days}';
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final moreButtonOptions = [
      AppLocalizations.of(context)!.edit_book,
    ];

    bookCubit.getBook(id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          StreamBuilder<Book>(
              stream: bookCubit.book,
              builder: (context, AsyncSnapshot<Book> snapshot) {
                if (snapshot.hasData) {
                  if (moreButtonOptions.length == 1) {
                    moreButtonOptions.add(
                      snapshot.data?.deleted == true
                          ? AppLocalizations.of(context)!.restore_book
                          : AppLocalizations.of(context)!.delete_book,
                    );
                  }

                  return PopupMenuButton<String>(
                    onSelected: (_) {},
                    itemBuilder: (_) {
                      return moreButtonOptions.map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Text(
                            choice,
                            style: TextStyle(
                              fontFamily: context.read<ThemeBloc>().fontFamily,
                            ),
                          ),
                          onTap: () async {
                            await Future.delayed(const Duration(
                              milliseconds: 0,
                            ));

                            if (choice == moreButtonOptions[0]) {
                              showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  enableDrag: false,
                                  builder: (context) {
                                    return AddBook(
                                      topPadding: statusBarHeight,
                                      book: snapshot.data,
                                      previousThemeData: Theme.of(context),
                                      editingExistingBook: true,
                                    );
                                  });
                            } else if (choice == moreButtonOptions[1]) {
                              if (snapshot.data!.deleted == false) {
                                _showDeleteDialog(context, true);
                              } else {
                                _showDeleteDialog(context, false);
                              }
                            }
                          },
                        );
                      }).toList();
                    },
                  );
                } else {
                  return const SizedBox();
                }
              }),
        ],
      ),
      body: SingleChildScrollView(
        child: StreamBuilder<Book>(
          stream: bookCubit.book,
          builder: (context, AsyncSnapshot<Book> snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data == null) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)!.error_getting_book,
                    style: TextStyle(
                      fontFamily: context.read<ThemeBloc>().fontFamily,
                    ),
                  ),
                );
              }
              book = snapshot.data!;

              return Column(
                children: [
                  (snapshot.data!.cover == null)
                      ? const SizedBox()
                      : Center(
                          child: CoverView(
                            onPressed: null,
                            heroTag: heroTag,
                            photoBytes: snapshot.data!.cover,
                            blurHash: snapshot.data!.blurHash,
                          ),
                        ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BookTitleDetail(
                          title: snapshot.data!.title.toString(),
                          subtitle: snapshot.data!.subtitle,
                          author: snapshot.data!.author.toString(),
                          publicationYear:
                              (snapshot.data!.publicationYear ?? "").toString(),
                          tags: snapshot.data!.tags?.split('|||||'),
                        ),
                        const SizedBox(height: 10),
                        BookStatusDetail(
                          statusIcon: _decideStatusIcon(snapshot.data!.status),
                          statusText: _decideStatusText(
                            snapshot.data!.status,
                            context,
                          ),
                          rating: snapshot.data!.rating,
                          startDate: _generateDate(snapshot.data!.startDate),
                          finishDate: _generateDate(snapshot.data!.finishDate),
                          onLikeTap: _onLikeTap,
                          isLiked: snapshot.data!.favourite,
                          showChangeStatus: (snapshot.data!.status == 1 ||
                              snapshot.data!.status == 2 ||
                              snapshot.data!.status == 3),
                          changeStatusText: _decideChangeStatusText(
                            snapshot.data!.status,
                            context,
                          ),
                          changeStatusAction: () {
                            _changeStatusAction(
                              context,
                              snapshot.data!.status,
                            );
                          },
                          showRatingAndLike: snapshot.data!.status == 0,
                        ),
                        SizedBox(
                          height: (snapshot.data!.finishDate != null &&
                                  snapshot.data!.startDate != null)
                              ? 10
                              : 0,
                        ),
                        (snapshot.data!.finishDate != null &&
                                snapshot.data!.startDate != null)
                            ? BookDetail(
                                title:
                                    AppLocalizations.of(context)!.reading_time,
                                text: _generateReadingTime(
                                  finishDate: snapshot.data!.finishDate!,
                                  startDate: snapshot.data!.startDate!,
                                  context: context,
                                ),
                              )
                            : const SizedBox(),
                        SizedBox(
                          height: (snapshot.data!.pages != null) ? 10 : 0,
                        ),
                        (snapshot.data!.pages != null)
                            ? BookDetail(
                                title: AppLocalizations.of(context)!
                                    .pages_uppercase,
                                text: (snapshot.data!.pages ?? "").toString(),
                              )
                            : const SizedBox(),
                        SizedBox(
                          height: (snapshot.data!.isbn != null) ? 10 : 0,
                        ),
                        (snapshot.data!.isbn != null)
                            ? BookDetail(
                                title: AppLocalizations.of(context)!.isbn,
                                text: (snapshot.data!.isbn ?? "").toString(),
                              )
                            : const SizedBox(),
                        SizedBox(
                          height: (snapshot.data!.olid != null) ? 10 : 0,
                        ),
                        (snapshot.data!.olid != null)
                            ? BookDetail(
                                title: AppLocalizations.of(context)!
                                    .open_library_ID,
                                text: (snapshot.data!.olid ?? "").toString(),
                              )
                            : const SizedBox(),
                        SizedBox(
                          height: (snapshot.data!.myReview != null) ? 10 : 0,
                        ),
                        (snapshot.data!.myReview != null)
                            ? BookDetail(
                                title: AppLocalizations.of(context)!.my_review,
                                text:
                                    (snapshot.data!.myReview ?? "").toString(),
                              )
                            : const SizedBox(),
                        const SizedBox(height: 50.0),
                      ],
                    ),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Text(
                snapshot.error.toString(),
                style: TextStyle(
                  fontFamily: context.read<ThemeBloc>().fontFamily,
                ),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }
}

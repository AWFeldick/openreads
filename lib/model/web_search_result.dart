import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart';

WebSearchResult webSearchResultFromPage(String str) =>
    WebSearchResult.fromHtml(parse(str));

class WebSearchResult {
  WebSearchResult({
    this.numFound,
    required this.docs,
  });

  final int? numFound;
  final List<WebSearchResultDoc> docs;

  factory WebSearchResult.fromHtml(Document html) {
    final scriptElements = html.getElementsByTagName("script");

    var docs = <WebSearchResultDoc>[];
    for (var element in scriptElements) {
      if (element.attributes.containsValue("application/ld+json")) {
        final Map<String, dynamic> jsonBlob = jsonDecode(element.innerHtml);

        if (jsonBlob.containsKey("@context")) {
          var url = Uri.parse(jsonBlob["@context"]);
          if (url.host != "schema.org") {
            continue;
          }

          // There might be a top level @graph definition, which will be an array of nodes
          if (jsonBlob.containsKey("@graph")) {
            (jsonBlob["@graph"] as List).map((x) {
              if (_isBook(jsonBlob["@type"])) {
                docs.add(WebSearchResultDoc.fromJson(x));
              }
            });
          } else {
            if (_isBook(jsonBlob["@type"])) {
              docs.add(WebSearchResultDoc.fromJson(jsonBlob));
            }
          }
        }
      }
    }

    return WebSearchResult(
      numFound: docs.length,
      docs: docs,
    );
  }

  static bool _isBook(dynamic field) {
    if (field is List) {
      return field.contains("Book");
    }
    return field == "Book";
  }
}

class WebSearchResultDoc {
  WebSearchResultDoc({
    this.bookEdition,
    this.bookFormat,
    this.isbn,
    this.numberOfPages,
    this.aggregateRating,
    this.author,
    this.awards,
    this.datePublished,
    this.inLanguage,
    this.description,
    this.image,
    this.name,
    this.url,
  });

  // // schema.org Book type properties
  // final bool? abridged;
  final String? bookEdition;
  final BookFormatType? bookFormat;
  // final String? illustrator;
  final String? isbn;
  final int? numberOfPages;
  // // schema.org inherited CreativeWork type properties
  // final String? about;
  // final String? abstract;
  // final String? accessMode;
  // final List<String>? accessModeSufficient;
  // final String? accessibilityAPI;
  // final String? accessibilityControl;
  // final String? accessibilityFeature;
  // final String? accessibilityHazard;
  // final String? accessibilitySummary;
  // final String? accountablePerson;
  // final String? acquireLicensePage;
  final double? aggregateRating;
  // final String? alternativeHeadline;
  // final String? archivedAt;
  // final String? assesses;
  // final String? associatedMedia;
  // final String? audience;
  // //final audio;
  final String? author;
  // final String? award;
  final String? awards;
  // final String? character;
  // final String? citation;
  // final String? comment;
  // final int? commentCount;
  // final String? conditionsOfAccess;
  // final String? contentLocation;
  // final String? contentRating;
  // final DateTime? contentReferenceTime;
  // final String? contributor;
  // final String? copyrightHolder;
  // final String? copyrightNotice;
  // final double? copyrightYear;
  // final String? correction;
  // final String? countryOfOrigin;
  // final String? creativeWorkStatus;
  // final String? creator;
  // final String? creditText;
  // final DateTime? dateCreated;
  // final DateTime? dateModified;
  final DateTime? datePublished;
  // final String? digitalSourceType;
  // final String? discussionUrl;
  // final String? editEIDR;
  // final String? editor;
  // final String? educationalAlignment;
  // final String? educationalLevel;
  // final String? educationalUse;
  // final String? encoding;
  // final String? encodingFormat;
  // final String? exampleOfWork;
  // final DateTime? expires;
  // final String? funder;
  // final String? funding;
  // final String? genre;
  // final String? hasPart;
  // final String? headline;
  final String? inLanguage;
  // final String? interactionStatistic;
  // final String? interactivityType;
  // final String? interpretedAsClaim;
  // final bool? isAccessibleForFree;
  // final String? isBasedOn;
  // final String? isBasedOnUrl;
  // final bool? isFamilyFriendly;
  // final String? isPartOf;
  // final String? keywords;
  // final String? learningResourceType;
  // final String? license;
  // final String? locationCreated;
  // final String? mainEntity;
  // final String? maintainer;
  // final String? material;
  // final String? materialExtent;
  // final String? mentions;
  // final String? offers;
  // final String? pattern;
  // final String? position;
  // final String? producer;
  // final String? provider;
  // final String? publication;
  // final String? publisher;
  // final String? publisherImprint;
  // final String? publishingPrinciples;
  // final String? recordedAt;
  // final String? releasedEvent;
  // final String? review;
  // final String? schemaVersion;
  // final DateTime? sdDatePublished;
  // final String? sdLicense;
  // final String? sdPublisher;
  // final String? size;
  // final String? sourceOrganization;
  // final String? spatial;
  // final String? spatialCoverage;
  // final String? sponsor;
  // final String? teaches;
  // final DateTime? temporal;
  // final DateTime? temporalCoverage;
  // final String? text;
  // final String? thumbnail;
  // final String? thumbnailUrl;
  // final String? timeRequired;
  // final String? translationOfWork;
  // final String? translator;
  // final String? typicalAgeRange;
  // final String? usageInfo;
  // final double? version;
  // //final video;
  // final String? workExample;
  // final String? workTranslation;
  // // schema.org Thing type properties
  // final String? additionalType;
  // final String? alternateName;
  final String? description;
  // final String? disambiguatingDescription;
  // final String? identifier;
  final String? image;
  // final String? mainEntityOfPage;
  final String? name;
  // final String? potentialAction;
  // final String? sameAs;
  // final String? subjectOf;
  final String? url;

  factory WebSearchResultDoc.fromJson(Map<String, dynamic> json) {
    double? rating;
    if (json["aggregateRating"] != null) {
      var r = json["aggregateRating"]["ratingValue"];
      if (r is String) {
        rating = double.tryParse(r);
      } else if (r is int) {
        rating = r.toDouble();
      } else {
        rating = r;
      }
    }

    return WebSearchResultDoc(
        name: json["name"],
        author: json["author"] == null
            ? null
            : _firstElementOrObj(json["author"])["name"],
        image: json["image"],
        bookEdition: json["bookEdition"],
        bookFormat: json["bookFormat"] == null
            ? null
            : bookFormatValues.map[json["bookFormat"]],
        isbn: json["isbn"],
        numberOfPages: json["numberOfPages"] is String
            ? int.tryParse(json["numberOfPages"])
            : json["numberOfPages"],
        aggregateRating: rating,
        awards: json["awards"],
        datePublished: json["datePublished"] == null
            ? null
            : DateTime.tryParse("2002-02-27T14:00:00-0500"),
        inLanguage: json["inLanguage"],
        description: json["description"],
        url: json["url"]);
  }

  static dynamic _firstElementOrObj(dynamic field) {
    if (field is List) {
      return field[0];
    } else if (field is Map) {
      return field;
    }
    return null;
  }
}

enum BookFormatType { audioBook, ebook, graphicNovel, hardcover, paperback }

final bookFormatValues = EnumValues({
  "AudiobookFormat": BookFormatType.audioBook,
  "EBook": BookFormatType.ebook,
  "GraphicNovel": BookFormatType.graphicNovel,
  "Hardcover": BookFormatType.hardcover,
  "Paperback": BookFormatType.paperback
});

class EnumValues<T> {
  Map<String, T> map;

  EnumValues(this.map);
}

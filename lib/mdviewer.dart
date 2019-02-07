import 'package:flutter/material.dart';
import 'package:adhara_markdown/mdbean.dart';
import 'package:adhara_markdown/utils.dart';

class MarkdownViewer extends StatelessWidget {
  final String content;
  final int loggedInUser;
  final TextStyle textStyle;
  final TextStyle highlightedTextStyle;
  final TextStyle fadedStyle;
  final List<MarkdownTokenTypes> formatTypes;
  final bool collapsible;
  final List<MarkdownTokenConfig> tokenConfigs;
  final int collapseLimit;

  MarkdownViewer(
      {Key key,
      this.content: "",
      this.loggedInUser,
      this.textStyle: const TextStyle(color: Colors.black),
      this.highlightedTextStyle: const TextStyle(color: Colors.indigo),
      this.formatTypes,
      this.collapsible: false,
      this.collapseLimit: 240,
      this.tokenConfigs,
      this.fadedStyle: const TextStyle(color: Colors.grey, fontSize: 12.0)})
      : super(key: key);

  get _textSpanConfigs =>
      tokenConfigs ??
      [
        MarkdownTokenConfig.mention(textStyle: highlightedTextStyle),
        MarkdownTokenConfig.link(textStyle: highlightedTextStyle),
        MarkdownTokenConfig.hashTag(textStyle: highlightedTextStyle),
        MarkdownTokenConfig.bold(textStyle: textStyle),
        MarkdownTokenConfig.italic(textStyle: textStyle),
        MarkdownTokenConfig.strikeThrough(textStyle: textStyle),
        MarkdownTokenConfig.code(textStyle: textStyle),
      ];

  @override
  Widget build(BuildContext context) {
    int len = 0;
    List<TextSpan> richTextChildren = [];
    bool showReadMore = false;
    for (MarkdownToken span in _convertPostToTextSpans(context, content)) {
      if (!collapsible || len < collapseLimit) {
        richTextChildren.add(span.getSpan());
      } else {
        showReadMore = true;
      }
      len += span.text.length;
    }
    if (showReadMore) {
      richTextChildren.add(MarkdownToken(
              config: MarkdownTokenConfig(
                  type: null, regExp: null, textStyle: textStyle),
              text: "...")
          .getSpan());
      richTextChildren.add(TextSpan(
        text: "Read more",
        style: fadedStyle.copyWith(
            color: fadedStyle.color.withOpacity(0.6),
            decoration: TextDecoration.underline,
            height: 1.3),
        recognizer: null,
      ));
    }

    return RichText(
      text: new TextSpan(
        children: richTextChildren,
      ),
    );
  }

  _convertPostToTextSpans(BuildContext context, String content) {
    List contentSpans = [content];
    for (MarkdownTokenConfig spanConfig in _textSpanConfigs) {
      if (formatTypes == null || formatTypes.indexOf(spanConfig.type) != -1) {
        if (spanConfig.meta != null) {
          contentSpans = splitUserTokens(contentSpans, spanConfig);
        } else {
          contentSpans = splitTokensByRegex(contentSpans, spanConfig);
        }
      }
    }
    return contentSpans.map<MarkdownToken>((postSpan) {
      if (postSpan is String) {
        return MarkdownToken(
            config: MarkdownTokenConfig(
                type: null, regExp: null, textStyle: textStyle),
            text: postSpan);
      } else {
        return postSpan;
      }
    }).toList();
  }

  splitUserTokens(List strings, MarkdownTokenConfig userSpanConfig) {
    List returnTexts = [];
    for (var text in strings) {
      if (text is String) {
        int startIndex = 0;
        if (userSpanConfig.meta != null) {
          userSpanConfig.meta.collection.forEach((SelectionInfo info) {
            returnTexts.add(text.substring(startIndex, info.startIndex));
            returnTexts.add(
              MarkdownToken(
                config: userSpanConfig,
                selectionInfo: info,
                text: text.substring(info.startIndex, info.endIndex + 1),
              ),
            );
            startIndex = info.endIndex + 1;
          });
        }
        returnTexts.add(text.substring(startIndex, text.length));
      }
    }
    return returnTexts;
  }

  splitTokensByRegex(List strings, MarkdownTokenConfig spanConfig) {
    List returnTexts = [];
    for (var text in strings) {
      if (text is String) {
        Iterable<Match> matches = spanConfig.regExp.allMatches(text);
        int startIndex = 0;
        for (Match m in matches) {
          returnTexts.add(text.substring(startIndex, m.start));
          String matchedText = text.substring(m.start, m.end);
          returnTexts.add(MarkdownToken(
            config: spanConfig,
            text: (spanConfig.postProcess != null)
                ? spanConfig.postProcess(matchedText)
                : matchedText,
          ));
          startIndex = m.end;
        }
        returnTexts.add(text.substring(startIndex, text.length));
      } else {
        returnTexts.add(text);
      }
    }
    return returnTexts;
  }
}

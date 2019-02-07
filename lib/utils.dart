import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:adhara_markdown/mdbean.dart';

typedef String StringCallbackFn(String span);
typedef void AdharaRichTextSpanTapCallback(MarkdownToken richTextSpan);
typedef Future<List<TokenSuggestion>> AdharaRichTextSuggestionCallback(
    String hint);
typedef String OnSuggestionInsert();
typedef void OnSavedCallback(String content);

enum MarkdownTokenTypes {
  link,
  mention,
  hashTag,
  bold,
  italic,
  strikeThrough,
  code
}

void urlOpener(MarkdownToken span) async {
  if (await canLaunch(span.text)) {
    await launch(span.text);
  } else {
    throw 'Could not launch ${span.text}';
  }
}

String stripFirstAndLast(String text) => text.substring(1, text.length - 1);

String _baseCharacters = r'a-zA-Z0-9\/?.",:<>' + r"'";

class MarkdownTokenConfig {
  final MarkdownTokenTypes type;
  final RegExp regExp;
  final RegExp hintRegExp;
  final TextStyle textStyle;
  final StringCallbackFn postProcess;
  final MarkdownMeta meta;
  final AdharaRichTextSpanTapCallback onTap;
  final AdharaRichTextSuggestionCallback suggestions;

  MarkdownTokenConfig(
      {@required this.type,
      @required this.textStyle,
      this.regExp,
      this.hintRegExp,
      this.postProcess,
      this.meta,
      this.onTap,
      this.suggestions});

  MarkdownTokenConfig.mention(
      {this.textStyle,
      this.postProcess,
      this.meta,
      this.onTap,
      this.suggestions})
      : type = MarkdownTokenTypes.mention,
        regExp = RegExp(r'@[0-9a-zA-Z.\s]+'),
        hintRegExp = RegExp(r"@[0-9a-zA-Z.\s]*");

  MarkdownTokenConfig.link({this.textStyle, this.postProcess})
      : type = MarkdownTokenTypes.link,
        regExp = RegExp(r'((http[s]{0,1}:\/\/)[a-zA-Z0-9\.%\/?:&,\-_#="]*)'),
        hintRegExp = null,
        meta = null,
        suggestions = null,
        onTap = urlOpener;

  MarkdownTokenConfig.hashTag(
      {this.textStyle, this.suggestions, this.postProcess, this.onTap})
      : type = MarkdownTokenTypes.hashTag,
        regExp = RegExp(r'#[' + _baseCharacters + ']+'),
        hintRegExp = RegExp(r'#[' + _baseCharacters + '\-]*'),
        meta = null;

  MarkdownTokenConfig.bold({TextStyle textStyle, StringCallbackFn postProcess})
      : type = MarkdownTokenTypes.bold,
        regExp = RegExp(r'\*[' + _baseCharacters + r'_~`\-\s]*\*'),
        hintRegExp = null,
        textStyle = textStyle.copyWith(fontWeight: FontWeight.bold),
        postProcess = postProcess ?? stripFirstAndLast,
        meta = null,
        suggestions = null,
        onTap = null;

  MarkdownTokenConfig.italic(
      {TextStyle textStyle, StringCallbackFn postProcess})
      : type = MarkdownTokenTypes.italic,
        regExp = RegExp(r'_[' + _baseCharacters + r'~`\-\*\s]*_'),
        hintRegExp = null,
        textStyle = textStyle.copyWith(fontStyle: FontStyle.italic),
        postProcess = postProcess ?? stripFirstAndLast,
        meta = null,
        suggestions = null,
        onTap = null;

  MarkdownTokenConfig.strikeThrough(
      {TextStyle textStyle, StringCallbackFn postProcess})
      : type = MarkdownTokenTypes.strikeThrough,
        regExp = RegExp(r'~[' + _baseCharacters + r'_`\-\*\s]*~'),
        hintRegExp = null,
        textStyle = textStyle.copyWith(decoration: TextDecoration.lineThrough),
        postProcess = postProcess ?? stripFirstAndLast,
        meta = null,
        suggestions = null,
        onTap = null;

  MarkdownTokenConfig.code({TextStyle textStyle, StringCallbackFn postProcess})
      : type = MarkdownTokenTypes.code,
        regExp = RegExp(r'`[' + _baseCharacters + r'~_\-\*\s]*`'),
        hintRegExp = null,
        textStyle = textStyle.copyWith(fontFamily: "Monospace"),
        postProcess = postProcess ?? stripFirstAndLast,
        meta = null,
        suggestions = null,
        onTap = null;
}

class MarkdownToken {
  final MarkdownTokenConfig config;
  final SelectionInfo selectionInfo;
  final String text;

  MarkdownToken(
      {@required this.text, @required this.config, this.selectionInfo});

  TextSpan getSpan() {
    return TextSpan(
      text: text,
      style: config.textStyle,
      recognizer: (this.config.onTap != null)
          ? (TapGestureRecognizer()
            ..onTap = () {
              this.config.onTap(this);
            })
          : null,
    );
  }
}

class TokenSuggestion {
  Widget display;
  dynamic data;
  OnSuggestionInsert onInsert;

  TokenSuggestion({this.display, this.data, this.onInsert});
}

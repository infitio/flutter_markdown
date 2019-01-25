import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'mdbean.dart';
import 'package:url_launcher/url_launcher.dart';


class MarkDownViewer extends StatelessWidget{

  final String content;
  final ContentMeta meta;
  final int loggedInUser;
  final TextStyle textStyle;
  final TextStyle highlightedTextStyle;
  final List<TextSpanType> formatTypes;
  final bool enableCollapse;
  final List<AdharaRichTextSpanConfig> metaBasedConfigs;
  final List<AdharaRichTextSpanConfig> regExpConfigs;

  MarkDownViewer({
    Key key,
    this.content: "",
    this.meta,
    this.loggedInUser,
    this.textStyle : const TextStyle(
        color:  const Color(0xff273d52),
        fontWeight: FontWeight.w400,
        fontFamily: "SFProText",
        fontStyle:  FontStyle.normal,
        fontSize: 14.0,
        height: 1.3
    ),
    this.highlightedTextStyle : const TextStyle(
        color:  const Color(0xff4e78de),
        fontWeight: FontWeight.w400,
        fontFamily: "SFProText",
        fontStyle:  FontStyle.normal,
        fontSize: 14.0
    ),
    this.formatTypes,
    this.enableCollapse: true,
    this.metaBasedConfigs,
    this.regExpConfigs
  }) : super(key: key);

  get _metaBasedConfigs => metaBasedConfigs ?? [
    AdharaRichTextSpanConfig.forMeta(textStyle: highlightedTextStyle,
        contentMeta: meta,
        onTap: (AdharaRichTextSpan span){
          print("tapped on text span...${span.text}");
        }
    ),
  ];

  get _regExpConfigs => regExpConfigs ?? [
    AdharaRichTextSpanConfig.link(highlightedTextStyle),
    AdharaRichTextSpanConfig.hashTag(highlightedTextStyle),
    AdharaRichTextSpanConfig.bold(textStyle),
    AdharaRichTextSpanConfig.italic(textStyle),
    AdharaRichTextSpanConfig.strikeThrough(textStyle),
    AdharaRichTextSpanConfig.code(textStyle),
  ];

  @override
  Widget build(BuildContext context){
    String postContent = content;
    bool readMore = false;
    ContentMeta postMeta = meta;
    if(enableCollapse){
      if(postContent.length > 240){
        readMore = true;
        postContent = postContent.substring(0, 240 - 5) + ".... ";
        if(postMeta != null){
          postMeta.collection.removeWhere((selectionMeta) => selectionMeta.endIndex > 239 - 5);
        }
      }
    }
    List<TextSpan> richTextChildren = _convertPostToTextSpans(context, postContent);
    if(readMore){
      TextStyle fadedStyle = const TextStyle(
          color:  const Color(0xff273d52),
          fontWeight: FontWeight.w400,
          fontFamily: "SFProText",
          fontStyle:  FontStyle.normal,
          fontSize: 12.0
      );
      richTextChildren.add(TextSpan(
        text: "Read more",
        style: fadedStyle.copyWith(
            color: fadedStyle.color.withOpacity(0.6),
            decoration: TextDecoration.underline,
            height: 1.3
        ),
        recognizer: null,
      ));
      readMore = false;
    }

    return RichText(
      text: new TextSpan(
        children: richTextChildren,
      ),
    );
  }

  _convertPostToTextSpans(BuildContext context, String content){
    List contentSpans = [content];
    for(AdharaRichTextSpanConfig spanConfig in _metaBasedConfigs){
      if(formatTypes==null || formatTypes.indexOf(spanConfig.type) != -1){
        contentSpans = splitUserTokens(contentSpans, spanConfig);
      }
    }
    for(AdharaRichTextSpanConfig spanConfig in _regExpConfigs){
      if(formatTypes==null || formatTypes.indexOf(spanConfig.type) != -1){
        contentSpans = splitTokensByRegex(contentSpans, spanConfig);
      }
    }
    return contentSpans.map<TextSpan>((postSpan){
      if(postSpan is String){
        return AdharaRichTextSpan(
            config: AdharaRichTextSpanConfig(type: null, regExp: null, textStyle: textStyle),
            text: postSpan
        ).getSpan();
      }else{
        return postSpan;
      }
    }).toList();

  }

  splitUserTokens(List strings, AdharaRichTextSpanConfig userSpanConfig){
    List returnTexts = [];
    for(var text in strings) {
      if (text is String) {
        int startIndex = 0;
        if (userSpanConfig.contentMeta != null) {
          userSpanConfig.contentMeta.collection.forEach((SelectionInfo info) {
            returnTexts.add(text.substring(startIndex, info.startIndex));
            returnTexts.add(
              AdharaRichTextSpan(
                config: userSpanConfig,
                selectionInfo: info,
                text: text.substring(info.startIndex, info.endIndex + 1),
              ).getSpan(),
            );
            startIndex = info.endIndex + 1;
          });
        }
        returnTexts.add(text.substring(startIndex, text.length));
      }
    }
    return returnTexts;
  }

  splitTokensByRegex(List strings, AdharaRichTextSpanConfig spanConfig){
    List returnTexts = [];
    for(var text in strings){
      if(text is String){
        Iterable<Match> matches = spanConfig.regExp.allMatches(text);
        int startIndex = 0;
        for (Match m in matches) {
          returnTexts.add(text.substring(startIndex, m.start));
          String matchedText = text.substring(m.start, m.end);
          returnTexts.add(AdharaRichTextSpan(
              config: spanConfig,
              text: (spanConfig.postProcess!=null)?spanConfig.postProcess(matchedText):matchedText,
          ).getSpan());
          startIndex = m.end;
        }
        returnTexts.add(text.substring(startIndex, text.length));
      }else{
        returnTexts.add(text);
      }
    }
    return returnTexts;
  }

}

enum TextSpanType{
  link,
  mention,
  hashTag,
  bold,
  italic,
  strikeThrough,
  code
}

typedef String StringCallbackFn(String span);
typedef void AdharaRichTextSpanTapCallback(AdharaRichTextSpan richTextSpan);

class AdharaRichTextSpanConfig{

  final TextSpanType type;
  final RegExp regExp;
  final TextStyle textStyle;
  final StringCallbackFn postProcess;
  final ContentMeta contentMeta;
  final AdharaRichTextSpanTapCallback onTap;

  AdharaRichTextSpanConfig({
    @required this.type,
    @required this.regExp,
    @required this.textStyle,
    this.postProcess,
    this.contentMeta,
    this.onTap
  });

  AdharaRichTextSpanConfig.forMeta({
    this.contentMeta,
    this.textStyle,
    this.postProcess,
    this.onTap,
    this.type: TextSpanType.mention
  }): regExp = RegExp(r'((http[s]{0,1}:\/\/)[a-zA-Z0-9\.%\/=?:&,"]*)');

  AdharaRichTextSpanConfig.link(TextStyle textStyle, [StringCallbackFn postProcess]):
        type = TextSpanType.link,
        regExp = RegExp(r'((http[s]{0,1}:\/\/)[a-zA-Z0-9\.%\/?:&,\-_#="]*)'),
        textStyle = textStyle,
        postProcess = postProcess,
        contentMeta = null,
        onTap = urlOpener;

  AdharaRichTextSpanConfig.hashTag(TextStyle textStyle, [StringCallbackFn postProcess]):
        type = TextSpanType.hashTag,
        regExp = RegExp(r'#[a-zA-Z0-9\/?.",:<>]*'),
        textStyle = textStyle,
        postProcess = postProcess,
        contentMeta = null,
        onTap = null;

  AdharaRichTextSpanConfig.bold(TextStyle textStyle, [StringCallbackFn postProcess]):
        type = TextSpanType.bold,
        regExp = RegExp(r'\*[a-zA-Z0-9\/?.",:<>_~`\s]*\*'),
        textStyle = textStyle.copyWith(fontWeight: FontWeight.bold),
        postProcess = postProcess ?? stripFirstAndLast,
        contentMeta = null,
        onTap = null;

  AdharaRichTextSpanConfig.italic(TextStyle textStyle, [StringCallbackFn postProcess]):
        type = TextSpanType.italic,
        regExp = RegExp(r'_[a-zA-Z0-9\/?.",:<>\*~`\s]*_'),
        textStyle = textStyle.copyWith(fontStyle: FontStyle.italic),
        postProcess = postProcess ?? stripFirstAndLast,
        contentMeta = null,
        onTap = null;

  AdharaRichTextSpanConfig.strikeThrough(TextStyle textStyle, [StringCallbackFn postProcess]):
        type = TextSpanType.strikeThrough,
        regExp = RegExp(r'~[a-zA-Z0-9\/?.",:<>\*_`\s]*~'),
        textStyle = textStyle.copyWith(decoration: TextDecoration.lineThrough),
        postProcess = postProcess ?? stripFirstAndLast,
        contentMeta = null,
        onTap = null;

  AdharaRichTextSpanConfig.code(TextStyle textStyle, [StringCallbackFn postProcess]):
        type = TextSpanType.code,
        regExp = RegExp(r'`[a-zA-Z0-9\/?.",:<>\*~_\s]*`'),
        textStyle = textStyle.copyWith(fontFamily: "Monospace"),
        postProcess = postProcess ?? stripFirstAndLast,
        contentMeta = null,
        onTap = null;

}

class AdharaRichTextSpan{

  final AdharaRichTextSpanConfig config;
  final SelectionInfo selectionInfo;
  final String text;

  AdharaRichTextSpan({
    @required this.text,
    @required this.config,
    this.selectionInfo
  });

  TextSpan getSpan(){
    return TextSpan(
      text: text,
      style: config.textStyle,
      recognizer: (this.config.onTap!=null)
          ?(TapGestureRecognizer()..onTap = (){this.config.onTap(this);})
          :null,
    );
  }

}

void urlOpener(AdharaRichTextSpan span) async {
  if (await canLaunch(span.text)) {
    await launch(span.text);
  } else {
    throw 'Could not launch ${span.text}';
  }
}

String stripFirstAndLast(String text) => text.substring(1, text.length-1);
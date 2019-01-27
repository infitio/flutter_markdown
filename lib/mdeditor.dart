import 'package:flutter/material.dart';
import 'package:adhara_markdown/mdbean.dart';
import 'package:adhara_markdown/mdviewer.dart';
import 'package:adhara_markdown/utils.dart';


class MarkdownEditor extends StatefulWidget {

  final String value;
  final String hint;
  final OnSavedCallback onSaved;
  final List<MarkdownTokenConfig> tokenConfigs;
  final TextStyle textStyle;
  final TextStyle highlightedTextStyle;
  final MarkDownBean bean;
  final MarkdownEditorController controller;


  MarkdownEditor({
    Key key,
    this.value,
    this.hint,
    this.onSaved,
    this.controller,
    this.tokenConfigs,
    this.textStyle,
    this.highlightedTextStyle,
    MarkDownBean bean
  }) :
        bean = bean ?? MarkDownBean(),
        super(key: key);

  @override
  _MarkdownEditorState createState() => _MarkdownEditorState();

}

class _MarkdownEditorState extends State<MarkdownEditor>{

  String get tag => "AdharaTextField";

  TextEditingController textEditingController;
  int currentContentLength;
  Match match;
  List<TokenSuggestion> suggestions = [];
  MarkdownTokenConfig tokenConfig;

  TextStyle baseTextStyle = TextStyle(
    color:  const Color(0xff273d52),
    fontWeight: FontWeight.w400,
    fontFamily: "SFProText",
    fontStyle:  FontStyle.normal,
    fontSize: 14.0,
  );

  GlobalKey _editorKey = GlobalKey();
  OverlayState overlayState;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    textEditingController = TextEditingController(text: widget.value);
    currentContentLength = textEditingController.text.length;
    overlayState = Overlay.of(context);
    textEditingController.addListener(_listenTextInput);
  }

  _listenTextInput() async {
    setState((){
      suggestions = [];
      match = null;
    });
    if(textEditingController != null){
        if(textEditingController.text.length < 1){
          suggestions = [];
        }else{
          int indexNow = textEditingController.selection.baseOffset-1;
          if(indexNow < 0) return;
          for(MarkdownTokenConfig _tokenConfig in widget.tokenConfigs){
            if(_tokenConfig.hintRegExp!=null) {
              for (Match m in _tokenConfig.hintRegExp.allMatches(
                  textEditingController.text)) {
                if (m.start < indexNow && m.end >= indexNow) {
                  suggestions = await _tokenConfig.suggestions(m.group(0));
                  match = m;
                  tokenConfig = _tokenConfig;
                }
              }
            }
          }
          // postMeta index update
          if(suggestions.isNotEmpty) {
            int textLength = textEditingController.text.length;
            if (currentContentLength != textEditingController.text.length) {
              for(MarkdownTokenConfig _tokenConfig in widget.tokenConfigs){
                if(_tokenConfig.meta != null){
                  _tokenConfig.meta.collection.forEach((SelectionInfo info) {
                    if (textLength > currentContentLength) {
                      if (info.startIndex <=
                          indexNow - (textLength - currentContentLength) &&
                          indexNow - (textLength - currentContentLength) <
                              info.endIndex) {
                        _tokenConfig.meta.collection.remove(info);
                      }
                      else if (info.startIndex >
                          indexNow - (textLength - currentContentLength)) {
                        info.updateIndex(
                            info.startIndex + (textLength - currentContentLength));
                      }
                    }
                    else {
                      if (info.startIndex - 1 <= indexNow &&
                          indexNow < info.endIndex) {
                        _tokenConfig.meta.collection.remove(info);
                      }
                      else if (info.startIndex - 1 > indexNow) {
                        info.updateIndex(
                            info.startIndex - (currentContentLength - textLength));
                      }
                    }
                  });
                }
              }
            }
          }
        }
        currentContentLength = textEditingController.text.length;
        setState(() {});
    }
    showSuggestions(context);
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> stackList = [
      //highlighted rich text
      PositionedDirectional(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: MarkdownViewer(
              content: textEditingController.text,
              collapsible: false,
              textStyle: widget.textStyle,
              highlightedTextStyle: widget.highlightedTextStyle,
              tokenConfigs: widget.tokenConfigs,
              /*formatTypes: [
                MarkdownTokenTypes.link,
                MarkdownTokenTypes.mention,
                MarkdownTokenTypes.hashTag
              ]*/
            ),
          )
      ),
      //Text input box
      TextFormField(
          controller: textEditingController,
          autofocus: true,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          style: baseTextStyle.copyWith(color: const Color(0xff273d52).withOpacity(0.1)),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            hintText: widget.hint,
            hintStyle: baseTextStyle.copyWith(color: const Color(0x80273d52)),
            border: InputBorder.none,
          ),
          onSaved: widget.onSaved
      ),
    ];

    return Stack(
      key: _editorKey,
      children: stackList,
    );
  }

  OverlayEntry overlaySuggestions;
  showSuggestions(BuildContext context) async {
    final RenderBox renderBoxRed = _editorKey.currentContext.findRenderObject();
    final editorSize = renderBoxRed.size;
    final editorPosition = renderBoxRed.localToGlobal(Offset.zero);
    if(suggestions.length==0){
      overlaySuggestions?.remove();
      overlaySuggestions = null;
      return;
    }
    overlaySuggestions = OverlayEntry(
      builder: (context) => Positioned(
        top: editorPosition.dy + editorSize.height,
        child: _getStackForSuggestions(context),
      )
    );
    overlayState.insert(overlaySuggestions);
  }

  Widget _getStackForSuggestions(BuildContext context){
    if(suggestions.isNotEmpty) {
      return Material(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery
              .of(context)
              .size
              .width, maxHeight: 400.0),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
                color: Colors.white,
//                border: Border.all(color: Theme.of(context).primaryColorLight),
                border: Border.all(color: const Color(0x32273d52)),
                borderRadius: BorderRadius.circular(4.0)
            ),
            child: _buildSuggestions(),
          )
        )
      );
    }
    return Container();
  }

  ListView _buildSuggestions(){
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      children: suggestions.map<Widget>((TokenSuggestion suggestion) {
        return InkWell(
          child: Builder(builder: (BuildContext context) {
            return suggestion.display;
          }),
          onTap: () {
            int indexNow = textEditingController.selection.baseOffset;
            int indexAt = match.start;
            String addToInput = suggestion.onInsert();
            int offSet = indexAt + 1;
            textEditingController.text =
                textEditingController.text.substring(0, indexAt) + addToInput
                    + textEditingController.text.substring(indexNow);
            offSet = offSet + addToInput.length;
            textEditingController.selection = TextSelection(
                baseOffset: textEditingController.selection.baseOffset + offSet,
                extentOffset: textEditingController.selection.extentOffset +
                    offSet
            );
            if (tokenConfig.meta != null) {
              tokenConfig.meta.collection.add(SelectionInfo(
                  indexAt, indexAt + addToInput.length - 1,
                  suggestion.data));
            }
            setState(() {});
          }
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

}

class MarkdownEditorController{

  _MarkdownEditorState _state;

  String get content => _state.textEditingController.text;

}
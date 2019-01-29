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
  final InputDecoration decoration;
  final FormFieldSetter<String> onChange;


  MarkdownEditor({
    Key key,
    this.value,
    this.hint,
    this.onSaved,
    this.onChange,
    this.controller,
    this.tokenConfigs,
    this.textStyle,
    this.highlightedTextStyle,
    this.decoration,
    MarkDownBean bean
  }) :
        bean = bean ?? MarkDownBean(),
        super(key: key);

  @override
  _MarkdownEditorState createState() => _MarkdownEditorState();

}

class _MarkdownEditorState extends State<MarkdownEditor>{

  TextEditingController textEditingController;
  FocusNode focusNode;
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
    textEditingController = TextEditingController(text: widget.value);
    widget.controller?._state = this; //must be called after setting textEditingController
    currentContentLength = textEditingController.text.length;
    overlayState = Overlay.of(context);
    textEditingController.addListener(_listenTextInput);
//    focusNode = FocusNode()..addListener(_listenTextInput);
  }

  InputDecoration get _decoration => widget.decoration ?? InputDecoration(
    contentPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
    hintText: widget.hint,
    hintStyle: baseTextStyle.copyWith(color: const Color(0x80273d52)),
    border: InputBorder.none,
  );

  @override
  Widget build(BuildContext context) {
    double topOffset = _decoration.labelStyle?.fontSize ?? 0.0;
    if(_decoration.hintStyle!=null){
      topOffset += _decoration.hintStyle.fontSize - widget.textStyle.fontSize;
    }
    return Stack(
      key: _editorKey,
      children: [
        //highlighted rich text
        PositionedDirectional(
            child: Container(
              padding: _decoration.contentPadding?.add(
                  EdgeInsets.only(top: topOffset)
              ),
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
            focusNode: focusNode,
            autofocus: true,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            style: widget.textStyle.copyWith(color: Colors.transparent),
//            style: widget.textStyle.copyWith(color: Colors.grey.withOpacity(0.1)),
            decoration: _decoration,
            onSaved: widget.onSaved
        ),
      ],
    );
  }

  _listenTextInput() async {
    setState((){
      suggestions = [];
      match = null;
    });
    if(textEditingController != null){
      if(textEditingController.text.length < 1){
        suggestions = [];
        for(MarkdownTokenConfig _tokenConfig in widget.tokenConfigs){
          _tokenConfig.meta?.collection = [];
        }
      }else{
        int indexNow = textEditingController.selection.baseOffset-1;
        if(indexNow < 0) return;
        for(MarkdownTokenConfig _tokenConfig in widget.tokenConfigs){
          if(_tokenConfig.hintRegExp!=null) {
            for (Match m in _tokenConfig.hintRegExp.allMatches(
                textEditingController.text)) {
              if (m.start < indexNow && m.end >= indexNow) {
                suggestions = await _tokenConfig.suggestions(textEditingController.text.substring(m.start, indexNow));
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
    if(widget.onChange!=null) {
      widget.onChange(textEditingController.text);
    }
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
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    double visibleHeight = MediaQuery.of(context).size.height - keyboardHeight;
    double top = editorPosition.dy + editorSize.height;
    double bottom;
    if(top > visibleHeight/2){
      top = null;
      bottom = keyboardHeight + editorSize.height;
    }
    overlaySuggestions = OverlayEntry(
      builder: (context) => Positioned(
        top: top,
        bottom: bottom,
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

  triggerSave(){
    if(widget.onSaved!=null) {
      widget.onSaved(textEditingController.text);
    }
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

}

class MarkdownEditorController{

  _MarkdownEditorState __state;
  List<VoidCallback> listeners = [];

  set _state(_MarkdownEditorState state){
    __state = state;
    updateListeners();
  }
  _MarkdownEditorState get _state => __state;

  TextEditingController get controller => _state?.textEditingController;
  String get text => _state?.textEditingController?.text;

  triggerSave(){
    _state?.triggerSave();
  }

  updateListeners(){
    if(controller == null) return;
    for(VoidCallback listener in listeners){
      controller.addListener(listener);
    }
    listeners = [];
  }

  addListener(VoidCallback listener){
    listeners.add(listener);
    updateListeners();
  }

}
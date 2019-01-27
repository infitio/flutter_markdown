import 'package:flutter/material.dart';
import 'package:adhara_markdown/mdbean.dart';
import 'package:adhara_markdown/mdviewer.dart';


class MarkDownEditor extends StatefulWidget {

  final String value;
  final String hint;
  final Function onSaved;
  final Widget nonPositionedChild;
  final List<AdharaRichTextSpanConfig> textSpanConfigs;
  final MarkDownBean bean;

  MarkDownEditor({
    Key key,
    this.value,
    this.hint,
    this.onSaved,
    this.nonPositionedChild,
    this.textSpanConfigs,
    MarkDownBean bean
  }) :
        bean = bean ?? MarkDownBean(),
        super(key: key);

  @override
  _MarkDownEditorState createState() => _MarkDownEditorState();

}

class _MarkDownEditorState extends State<MarkDownEditor>{

  String get tag => "AdharaTextField";

  TextEditingController textEditingController;
  ContentMeta contentMeta;
  int currentContentLength;
  Match match;
  List<Suggestion> suggestions = [];
  AdharaRichTextSpanConfig matchedSpanConfig;

  TextStyle baseTextStyle = TextStyle(
    color:  const Color(0xff273d52),
    fontWeight: FontWeight.w400,
    fontFamily: "SFProText",
    fontStyle:  FontStyle.normal,
    fontSize: 14.0,
  );

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController(text: widget.value);
    currentContentLength = textEditingController.text.length;
    textEditingController.addListener(_listenTextInput);
    contentMeta = widget.bean.meta ?? ContentMeta([]);
  }

  _listenTextInput() async {
    setState((){
      suggestions = [];
      match = null;
      matchedSpanConfig = null;
    });
    if(textEditingController != null){
        if(textEditingController.text.length < 1){
          contentMeta = ContentMeta([]);
          suggestions = [];
        }else{
          int indexNow = textEditingController.selection.baseOffset-1;
          if(indexNow < 0) return;
          for(AdharaRichTextSpanConfig spanConfig in widget.textSpanConfigs){
            if(spanConfig.hintRegExp!=null) {
              for (Match m in spanConfig.hintRegExp.allMatches(
                  textEditingController.text)) {
                if (m.start < indexNow && m.end >= indexNow) {
                  suggestions = await spanConfig.suggestions(m.group(0), contentMeta);
                  match = m;
                  matchedSpanConfig = spanConfig;
                }
              }
            }
          }
          // postMeta index update
          int textLength = textEditingController.text.length;
          if(currentContentLength != textEditingController.text.length){
            contentMeta.collection.forEach((SelectionInfo info){
              if(textLength > currentContentLength){
                if(info.startIndex <= indexNow-(textLength-currentContentLength) && indexNow-(textLength-currentContentLength) < info.endIndex){
                  contentMeta.collection.remove(info);
                }
                else if(info.startIndex > indexNow - (textLength-currentContentLength)){
                  info.updateIndex(info.startIndex+(textLength-currentContentLength));
                }
              }
              else{
                if(info.startIndex-1 <= indexNow && indexNow < info.endIndex){
                  contentMeta.collection.remove(info);
                }
                else if(info.startIndex-1 > indexNow){
                  info.updateIndex(info.startIndex-(currentContentLength-textLength));
                }
              }
            });
          }
        }
        currentContentLength = textEditingController.text.length;
        setState(() {});
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree
//    textEditingController.removeListener(_listenTextInput);
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> contentBoxChildren = [];
    List<Widget> stackList = [];
    stackList.add(TextFormField(
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
    ));

    stackList.insert(0, PositionedDirectional(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: MarkDownViewer(
              content: textEditingController.text,
              meta: contentMeta,
              enableCollapse: false,
              textStyle: baseTextStyle.copyWith(color: const Color(0xff273d52)),
              highlightedTextStyle: baseTextStyle.copyWith(color: const Color(0xff006ce0)),
              formatTypes: [
                TextSpanType.link,
                TextSpanType.mention,
                TextSpanType.hashTag
              ]
          ),
        )
    ));

    contentBoxChildren.add(
        Stack(
          children: stackList,
        )
    );
    contentBoxChildren.add(_getStackForSuggestions());
    return Container(
      child: ListView(
        shrinkWrap: true,
        children: contentBoxChildren,
      ),
    );
  }

  Stack _getStackForSuggestions(){
    List<Widget> stackChildren = [];
    stackChildren.add(widget.nonPositionedChild);
    if(suggestions.isNotEmpty){
      stackChildren.add(PositionedDirectional(
        child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width, maxHeight: 400.0),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0x32273d52)),
                  borderRadius: BorderRadius.circular(4.0)
              ),
              child: ListView(
                shrinkWrap: true,
                children: suggestions.map<Widget>((Suggestion suggestion){
                  return InkWell(
                    child: Builder(builder: (BuildContext context){
                      return suggestion.display;
                    }),
                    onTap: (){
                      setState(() {
                        int indexAt;
                        String addToInput;
                        int indexNow = textEditingController.selection.baseOffset;
                        indexAt = match.start;
                        addToInput = suggestion.onInsert();
                        int offSet = indexAt + 1;
                        textEditingController.text = textEditingController.text.substring(0, indexAt) + addToInput + textEditingController.text.substring(indexNow);
                        offSet = offSet + addToInput.length;
                        textEditingController.selection = TextSelection(
                            baseOffset: textEditingController.selection.baseOffset+offSet,
                            extentOffset: textEditingController.selection.extentOffset+offSet
                        );
                        if(matchedSpanConfig.hintRegExp != null && matchedSpanConfig.regExp == null){
                          contentMeta.collection.add(SelectionInfo(indexAt, indexAt+addToInput.length - 1, suggestion.data));
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            )
        ),
      ));
    }

    return Stack(
      children: stackChildren,
    );
  }
}
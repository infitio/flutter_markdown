import 'package:flutter/material.dart';
import 'package:adhara_markdown/mdbean.dart';
import 'package:adhara_markdown/mdviewer.dart';


class MarkDownEditor extends StatefulWidget {

  final String value;
  final String hint;
  final Function onSaved;
  final Widget nonPositionedChild;
  final MarkDownBean bean;

  MarkDownEditor({
    Key key,
    this.value,
    this.hint,
    this.onSaved,
    this.nonPositionedChild,
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
  bool showProfileTags;
  int indexP;
  RegExp regExpProfile;
  bool showHashTags;
  int indexH;
  RegExp regExpHashTag;

  ContentMeta contentMeta;
  int length;

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
    length = textEditingController.text.length;
    textEditingController.addListener(_listenTextInput);
    showProfileTags = false;
    regExpProfile = new RegExp("");
    showHashTags = false;
    regExpHashTag = new RegExp("");
    contentMeta = widget.bean.meta ?? ContentMeta([]);
  }

  /*void fetchDataForTag() async{
    if(userList == null || userList.isEmpty){
      userList = await (r.dataInterface as AppDataInterface).getUsers();
    }
    setState(() {});
  }*/

  _listenTextInput(){

    if(textEditingController != null){
      setState(() {
        if(textEditingController.text.length < 1){
          showProfileTags = false;
          regExpProfile = new RegExp("");
          showHashTags = false;
          regExpHashTag = new RegExp("");
          contentMeta = ContentMeta([]);
        }else{
          int indexNow = textEditingController.selection.baseOffset-1;
          if(indexNow < 0) return;
          if(textEditingController.text.contains("@")){
            showProfileTags = true;
            indexP = textEditingController.text.lastIndexOf("@", indexNow);
//            fetchDataForTag();
            regExpProfile = new RegExp(
                (indexP < textEditingController.text.length - 1)
                    ?textEditingController.text.substring(indexP + 1, indexNow + 1)
                    :"",
                caseSensitive: false
            );
            if(indexH != null && indexH < indexP) showHashTags = false;
          }else{
            showProfileTags = false;
            regExpProfile = new RegExp("");
          }
          if(textEditingController.text.contains("#")){
            showHashTags = true;
            indexH = textEditingController.text.lastIndexOf("#", indexNow);
            if(indexH < textEditingController.text.length - 1){
              int nextSpace = textEditingController.text.indexOf(" ", indexH+1);
              if(nextSpace == -1){
                nextSpace = textEditingController.text.length;
              }
              /*(widget.categories.where((Category category) => category.name == textEditingController.text.substring(indexH+1, nextSpace)).length) > 0
                  ? showHashTags =false
                  : regExpHashTag = new RegExp(textEditingController.text.substring(indexH + 1, indexNow + 1), caseSensitive: false);*/
            }
            else{
              regExpHashTag = new RegExp("");
            }
            if(indexP != null && indexP < indexH)
              showProfileTags = false;
          }
          else{
            showHashTags = false;
            regExpHashTag = new RegExp("");
          }
          // postMeta index update
          int textLength = textEditingController.text.length;
          if(length != textEditingController.text.length){
            contentMeta.collection.forEach((SelectionInfo info){
              if(textLength > length){
                if(info.startIndex <= indexNow-(textLength-length) && indexNow-(textLength-length) < info.endIndex){
                  contentMeta.collection.remove(info);
                }
                else if(info.startIndex > indexNow - (textLength-length)){
                  info.updateIndex(info.startIndex+(textLength-length));
                }
              }
              else{
                if(info.startIndex-1 <= indexNow && indexNow < info.endIndex){
                  contentMeta.collection.remove(info);
                }
                else if(info.startIndex-1 > indexNow){
                  info.updateIndex(info.startIndex-(length-textLength));
                }
              }
            });
          }
        }
        length = textEditingController.text.length;
      });
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

    Function onSaved = (value){
      widget.onSaved(value);
      //TODO revisit
//      widget.post.meta = (contentMeta.collection.length > 0) ? contentMeta : null;
    };

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
        onSaved: onSaved
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

    /*contentBoxChildren.add(getStackForTags());*/

    return Container(
      child: ListView(
        shrinkWrap: true,
        children: contentBoxChildren,
      ),
    );
  }

  /*Stack getStackForTags(){
    List<Widget> stackChildren = [];
    stackChildren.add(widget.nonPositionedChild);
    if(showProfileTags || showHashTags){
      List<Bean> filteredList = showProfileTags
      //TODO work on the below comment...
          ? userList.where((User user) => user.name.contains(regExpProfile) *//*&& !contentMeta.users.contains(user.id)*//*).toList()
          : widget.categories.where((Category category) => category.name.contains(regExpHashTag)).toList();
      (filteredList.length > 0)? stackChildren.add(PositionedDirectional(
        child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width, maxHeight: 400.0),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                  color: InfitioColors.white_seven,
                  border: Border.all(color: InfitioColors.dark_grey_blue_8_20),
                  borderRadius: BorderRadius.circular(4.0)
              ),
              child: CustomScrollView(
                shrinkWrap: true,
                slivers: <Widget>[
                  SliverList(
                    delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                      return InkWell(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: showProfileTags?16.0:0.0),
                          decoration: BoxDecoration(
                            border: (index == filteredList.length-1)
                                ? null: Border(bottom: BorderSide(color: InfitioColors.dark_grey_blue.withOpacity(0.1))),
                          ),
                          child: showProfileTags ? ProfileRow(
                            user: (filteredList[index] as User),
                            forMentions: true,
                          ): ListTile(
                            title: Text("#"+(filteredList[index] as Category).name.toString().replaceAll(" ", ""), style: baseTextStyle,),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        onTap: (){
                          setState(() {
                            int indexAt;
                            String addToInput;
                            int indexNow = textEditingController.selection.baseOffset;
                            bool addMeta = false;
                            if(showProfileTags){
                              indexAt = textEditingController.text.lastIndexOf("@");
                              addToInput = (filteredList[index] as User).name;
                              addMeta = true;
                              regExpProfile = new RegExp("");
                              showProfileTags = false;
                            }else{
                              indexAt = textEditingController.text.lastIndexOf("#");
                              addToInput =  "#"+(filteredList[index] as Category).name.toString().replaceAll(" ", "");
                              regExpHashTag = new RegExp("");
                              showHashTags = false;
                            }
                            int offSet = indexAt + 1;
                            textEditingController.text = textEditingController.text.substring(0, indexAt) + addToInput + textEditingController.text.substring(indexNow);
                            offSet = offSet + addToInput.length;
                            textEditingController.selection = TextSelection(
                                baseOffset: textEditingController.selection.baseOffset+offSet,
                                extentOffset: textEditingController.selection.extentOffset+offSet
                            );
                            if(addMeta){
                              contentMeta.collection.add(SelectionInfo(indexAt, indexAt+addToInput.length - 1, (filteredList[index] as User)));
                            }
                          });
                        },
                      );
                    }, childCount: filteredList.length),
                  )
                ],
              ),
            )
        ),
      )): print("filteredList.length = "+filteredList.length.toString());
    }

    return Stack(
      children: stackChildren,
    );
  }*/
}
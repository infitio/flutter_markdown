import 'package:flutter/material.dart';
import 'package:adhara_markdown/adhara_markdown.dart';

main() => runApp(App());

List<String> storyPieces = [
  "There were once *two brothers* who lived on the *edge of a forest*."
      " The elder brother was very _mean_ to his younger brother and _ate up all the food and took all his good clothes_."
      " One day, the elder brother went into the forest to find some `firewood` to `sell in the market`."
      " As he went around chopping the branches of a tree after tree, he came upon a `magical tree`."
      " The tree said to him, 'Oh kind sir, please do not cut my branches. If you spare me, I will give you my golden apples'."
      " The elder brother agreed but was ~disappointed~ with the number apples the tree gave him. Greed overcame him, and he threatened to cut the entire trunk if the tree didn’t give him more apples. The magical tree instead showered upon the elder brother hundreds upon hundreds of tiny needles. The elder brother lay on the ground crying in pain as the sun began to lower down the horizon.",
  "*The younger brother grew worried and went in search of his elder brother.*"
      " He found him with hundreds of needles on his skin."
      " He rushed to his brother and removed each needle with painstaking love."
      " After he finished, the elder brother apologised for treating him badly and promised to be better."
      " The tree saw the change in the elder brother’s heart and gave them all the golden apples they could ever need."
];

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePage(),
        theme: new ThemeData(
            primaryColor: Colors.blue, backgroundColor: Colors.white),
        color: Colors.blue);
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int editingPiece = -1;
  late MarkdownEditorController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MD Viewer & Editor"),
        actions: <Widget>[
          IconButton(
              icon: Icon(
                Icons.info,
                color: Colors.white,
              ),
              onPressed: () {
                showAboutDialog(
                    context: context,
                    applicationName: "Adhara MD Editor",
                    children: [
                      Text(
                        "How to use",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18.0),
                      ),
                      Text("Tap on the paragraphs to change to edit mode."),
                      Text("edit and click on update FAB")
                    ]);
//              showDialog(
//                context: context,
//                builder: (BuildContext context){
//                  return Text("ad");
//                }
//              );
              })
        ],
      ),
      floatingActionButton: (editingPiece == -1)
          ? null
          : FloatingActionButton(
              child: Icon(Icons.check),
              onPressed: () {
                setState(() {
                  storyPieces[editingPiece] = controller.text;
                  editingPiece = -1;
                });
              },
            ),
      body: Container(
        padding: EdgeInsets.all(12.0),
        child: ListView(
          children: <Widget>[
            _buildStory(storyPieces[0], 0),
            SizedBox(height: 8.0),
            _buildStory(storyPieces[1], 1)
          ],
        ),
      ),
    );
  }

  get textStyle => TextStyle(fontSize: 18.0, color: Colors.black);
  get highlightedTextStyle =>
      TextStyle(fontSize: 18.0, color: Colors.lightBlue);

  _buildStory(String storyPiece, int pieceIndex) {
    if (editingPiece == pieceIndex) {
      return _buildStoryEditor(storyPiece, pieceIndex);
    }
    return GestureDetector(
      child: MarkdownViewer(
        content: storyPiece,
        textStyle: textStyle,
        formatTypes: [
          MarkdownTokenTypes.bold,
          MarkdownTokenTypes.italic,
          MarkdownTokenTypes.strikeThrough,
          MarkdownTokenTypes.code
        ],
      ),
      onTap: () {
        setState(() {
          editingPiece = pieceIndex;
        });
      },
    );
  }

  _buildStoryEditor(String storyPiece, pieceIndex) {
    controller = MarkdownEditorController();
    return Container(
      child: Column(
        children: <Widget>[
          MarkdownEditor(
            value: storyPiece,
            textStyle: TextStyle(fontSize: 18.0, color: Colors.black),
            controller: controller,
            tokenConfigs: [
              MarkdownTokenConfig.mention(textStyle: highlightedTextStyle),
              MarkdownTokenConfig.link(textStyle: highlightedTextStyle),
              MarkdownTokenConfig.hashTag(textStyle: highlightedTextStyle),
            ],
          ),
        ],
      ),
    );
  }
}

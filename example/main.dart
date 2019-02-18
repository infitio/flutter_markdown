import 'package:flutter/material.dart';
import 'package:adhara_markdown/adhara_markdown.dart';

main() => runApp(App());


class App extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePage(),
        theme: new ThemeData(
            scaffoldBackgroundColor: Colors.white,//Color(0xFFF5F5F5),
            primaryColor: Colors.blue,
            backgroundColor: Colors.white
        ),
        color: Colors.blue
    );
  }

}

class HomePage extends StatefulWidget{

  @override
  State<StatefulWidget> createState() => HomePageState();

}

class HomePageState extends State<HomePage>{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("MD Viewer"),),
      body: Container(
        padding: EdgeInsets.all(12.0),
        child: ListView(
          children: <Widget>[
            _buildStory("There were once *two brothers* who lived on the *edge of a forest*."
                " The elder brother was very _mean_ to his younger brother and _ate up all the food and took all his good clothes_."
                " One day, the elder brother went into the forest to find some `firewood` to `sell in the market`."
                " As he went around chopping the branches of a tree after tree, he came upon a `magical tree`."
                " The tree said to him, 'Oh kind sir, please do not cut my branches. If you spare me, I will give you my golden apples'."
                " The elder brother agreed but was ~disappointed~ with the number apples the tree gave him. Greed overcame him, and he threatened to cut the entire trunk if the tree didn’t give him more apples. The magical tree instead showered upon the elder brother hundreds upon hundreds of tiny needles. The elder brother lay on the ground crying in pain as the sun began to lower down the horizon.",),
            SizedBox(height: 8.0),
            _buildStory("*The younger brother grew worried and went in search of his elder brother."
                " He found him with hundreds of needles on his skin."
                " He rushed to his brother and removed each needle with painstaking love."
                " After he finished, the elder brother apologised for treating him badly and promised to be better."
                " The tree saw the change in the elder brother’s heart and gave them all the golden apples they could ever need.*"
            )
          ],
        ),
      ),
    );
  }

  _buildStory(String storyPiece){
    return MarkdownViewer(
      content: storyPiece,
      textStyle: TextStyle(fontSize: 18.0, color: Colors.black),
      formatTypes: [
        MarkdownTokenTypes.bold,
        MarkdownTokenTypes.italic,
        MarkdownTokenTypes.strikeThrough,
        MarkdownTokenTypes.code
      ],
    );
  }

}
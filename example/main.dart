import 'package:flutter/material.dart';
import 'package:adhara_markdown/adhara_markdown.dart';

main() => runApp(App());


class App extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage()
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
    return MarkdownViewer(
      content: "Hello *World*, _How ya doin!_",
      formatTypes: [
        MarkdownTokenTypes.bold,
        MarkdownTokenTypes.italic,
        MarkdownTokenTypes.strikeThrough,
        MarkdownTokenTypes.code
      ],
    );
  }

}
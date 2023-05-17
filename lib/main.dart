import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:puzzle_app/puzzle_piece.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Puzzle',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Puzzle'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  // int rows = 3;
  // int cols = 3;

  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _image;
  List<Widget> pieces = [];
  int _correct = 0;
  int _currentTime = 0;
  Timer _timer;
  int rows = 3;
  int cols = 3;
  static final AudioPlayer _audioPlayer = AudioPlayer();

  Future getImage(ImageSource source) async {
    var imageFile = File(await ImagePicker()
        .pickImage(source: source)
        .then((pickedFile) => pickedFile.path));
    if (imageFile != null) {
      setState(() {
        _image = imageFile;
        pieces.clear();
      });

      splitImage(Image.file(imageFile));
      _currentTime = 0;
      _correct = 0;
      _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
        setState(() {
          _currentTime++;
        });
      });
    }
  }

  // we need to find out the image size, to be used in the PuzzlePiece widget
  Future<Size> getImageSize(Image image) async {
    final Completer<Size> completer = Completer<Size>();

    image.image
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener(
      (ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      },
    ));

    final Size imageSize = await completer.future;

    return imageSize;
  }

  // here we will split the image into small pieces using the rows and columns defined above; each piece will be added to a stack
  void splitImage(Image image) async {
    Size imageSize = await getImageSize(image);

    for (int x = 0; x < this.rows; x++) {
      for (int y = 0; y < this.cols; y++) {
        setState(() {
          pieces.add(PuzzlePiece(
              key: GlobalKey(),
              image: image,
              imageSize: imageSize,
              row: x,
              col: y,
              maxRow: this.rows,
              maxCol: this.cols,
              bringToTop: this.bringToTop,
              sendToBack: this.sendToBack));
        });
      }
    }
  }

  // when the pan of a piece starts, we need to bring it to the front of the stack
  void bringToTop(Widget widget) {
    setState(() {
      pieces.remove(widget);
      pieces.add(widget);
    });
  }

  // when a piece reaches its final position, it will be sent to the back of the stack to not get in the way of other, still movable, pieces
  void sendToBack(Widget widget) {
    setState(() {
      pieces.remove(widget);
      pieces.insert(0, widget);
      _correct = _correct + 1;
      if (_correct == pieces.length) {
        _audioPlayer.play(AssetSource('tada.mp3'));
        _timer.cancel();
      }
    });
  }

  TextEditingController rowsController = TextEditingController(text: "3");
  TextEditingController colsController = TextEditingController(text: "3");
  Color _selectedColor = Colors.white;
  List<Map<String, dynamic>> _colorOptions = [
    {'name': 'White', 'color': Colors.white},
    {'name': 'Blue', 'color': Colors.blue},
    {'name': 'Black', 'color': Colors.black},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _selectedColor, // Set the desired background color here
      appBar: AppBar(
        title: Text('${widget.title} - $_currentTime'),
      ),
      body: SafeArea(
        child: new Center(
          child: _image == null
              ? new Text('No image selected.')
              : Stack(children: pieces),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return SafeArea(
                  child: new Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      new ListTile(
                        leading: new Icon(Icons.camera),
                        title: new Text('Camera'),
                        onTap: () {
                          getImage(ImageSource.camera);
                          // this is how you dismiss the modal bottom sheet after making a choice
                          Navigator.pop(context);
                        },
                      ),
                      new ListTile(
                        leading: new Icon(Icons.image),
                        title: new Text('Gallery'),
                        onTap: () {
                          getImage(ImageSource.gallery);
                          // dismiss the modal sheet
                          Navigator.pop(context);
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Text('Rows: '),
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  if (this.rows > 2) {
                                    this.rows--;
                                    rowsController.text = this.rows.toString();
                                  }
                                });
                              },
                            ),
                            SizedBox(
                              width: 50.0,
                              child: TextFormField(
                                controller: rowsController,
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    var result =
                                        int.tryParse(value) ?? this.rows;
                                    if (result >= 1) {
                                      this.rows = result;
                                    }
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  this.rows++;
                                  rowsController.text = this.rows.toString();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Text('Columns: '),
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  if (this.cols > 2) {
                                    this.cols--;
                                    colsController.text = this.cols.toString();
                                  }
                                });
                              },
                            ),
                            SizedBox(
                              width: 50.0,
                              child: TextFormField(
                                controller: colsController,
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    var result =
                                        int.tryParse(value) ?? this.rows;
                                    if (result >= 1) {
                                      this.rows = result;
                                    }
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  this.cols++;
                                  colsController.text = this.cols.toString();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.color_lens),
                        title: Text('Change Background Color'),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Select a color'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    children: _colorOptions.map((option) {
                                      Color color = option['color'];
                                      String name = option['name'];
                                      return ListTile(
                                        title: Text(name),
                                        onTap: () {
                                          setState(() {
                                            _selectedColor = color;
                                          });
                                          Navigator.pop(context);
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text('Close'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              });
        },
        tooltip: 'New Image',
        child: Icon(Icons.add),
      ),
    );
  }
}

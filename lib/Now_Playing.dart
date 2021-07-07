import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:share/share.dart';

import 'Helper/Constant.dart';
import 'main.dart';

final _text = TextEditingController();
bool _validate = false;

///now playing inside class
class Now_Playing extends StatefulWidget {
  final VoidCallback _play, _pause, _next, _prev, _refresh;

  ///constructor
  Now_Playing(
      {VoidCallback play,
      VoidCallback pause,
      VoidCallback next,
      VoidCallback prev,
      VoidCallback refresh})
      : _play = play,
        _pause = pause,
        _next = next,
        _prev = prev,
        _refresh = refresh;

  @override
  State<StatefulWidget> createState() {
    return _PlayerWidgetState();
  }
}

class _PlayerWidgetState extends State<Now_Playing> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: curPlayList.isEmpty ? Container() : getContent());
  }

  getBackground() {
    return BoxDecoration(
      // Box decoration takes a gradient
      gradient: LinearGradient(
        // Where the linear gradient begins and ends
        begin: Alignment.topRight,
        end: Alignment.bottomCenter,
        // Add one stop for each color. Stops should increase from 0 to 1
        stops: [0.4, 0.6, 0.8],
        colors: [
          Colors.white70,
          primary.withOpacity(0.5),
          secondary,
        ],
      ),
    );
  }

  getContent() {
    return Container(
      decoration: getBackground(),
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height * .32,
            child: Center(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: FadeInImage(
                    placeholder: AssetImage('assets/image/placeholder.png'),
                    image: NetworkImage(curPlayList[curPos].image),
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  )),
            ),
          ),
          Text(
            curPlayList[curPos].name,
            style: Theme.of(context).textTheme.title,
            textAlign: TextAlign.center,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              curPlayList[curPos].description,
              style: Theme.of(context)
                  .textTheme
                  .subtitle
                  .copyWith(color: Colors.black45),
              textAlign: TextAlign.center,
            ),
          ),
          getMiddleButton(),
          getMediaButton()
        ],
      ),
    );
  }

  getMiddleButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              if (Platform.isAndroid) {
                Share.share('I am listening to-\n'
                    '${curPlayList[curPos].name}\n'
                    '$appname\n'
                    'https://play.google.com/store/apps/details?id=$androidPackage&hl=en');
              } else {
                Share.share('I am listening to-\n'
                    '${curPlayList[curPos].name}\n'
                    '$appname\n'
                    '$iosPackage');
              }
            },
            color: Colors.white,
          ),
          FutureBuilder(
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return snapshot.data == true
                    ? IconButton(
                        icon: Icon(
                          Icons.favorite,
                          size: 30,
                          color: primary,
                        ),
                        onPressed: () async {
                          await db.removeFav(curPlayList[curPos].id);
                          if (!mounted) {
                            return;
                          }
                          setState(() {});
                          widget._refresh();
                        })
                    : IconButton(
                        icon: Icon(
                          Icons.favorite_border,
                          size: 30,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          await db.setFav(
                              curPlayList[curPos].id,
                              curPlayList[curPos].name,
                              curPlayList[curPos].description,
                              curPlayList[curPos].image,
                              curPlayList[curPos].radio_url);
                          setState(() {});
                          widget._refresh();
                        });
              } else {
                return Container();
              }
            },
            future: db.getFav(curPlayList[curPos].id),
          ),
          IconButton(
            icon: Icon(Icons.queue_music),
            onPressed: () {
              panelController.close();
            },
            color: Colors.white,
          ),
          IconButton(
            icon: Icon(Icons.report),
            onPressed: () {
              if (!mounted) {
                return;
              }
              setState(() {
                showDialog(
                    context: context,
                    builder: (_) {
                      return ReportDialog();
                    });
              });
            },
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  getMediaButton() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.all(Radius.circular(20.0)),
              ),
              width: MediaQuery.of(context).size.width - 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.fast_rewind),
                    iconSize: 35,
                    onPressed: widget._prev,
                    color: Colors.white,
                  ),
                  IconButton(
                    icon: Icon(Icons.fast_forward),
                    iconSize: 35,
                    onPressed: widget._next,
                    color: Colors.white,
                  ),
                ],
              )),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: Colors.white12, offset: Offset(2, 2))
                    ],
                    shape: BoxShape.circle,
                    // Box decoration takes a gradient
                    gradient: LinearGradient(
                      // Where the linear gradient begins and ends
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      // Add one stop for each color. Stops should increase from 0 to 1
                      stops: [0.2, 0.5, 0.9],
                      colors: [
                        Colors.deepOrange.withOpacity(0.5),
                        primary.withOpacity(0.7),
                        primary,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child:

                        (Platform.isIOS)
                            ? (isPlaying == true &&
                                    playerState == PlayerState.playing)
                                ? IconButton(
                                    icon: Icon(Icons.pause),
                                    iconSize: 50,
                                    color: Colors.white,
                                    onPressed: widget._pause)
                                : IconButton(
                                    icon: Icon(Icons.play_arrow),
                                    iconSize: 50,
                                    color: Colors.white,
                                    onPressed: widget._play)
                            : (duration == null &&
                                    playerState != PlayerState.stopped)
                                ? Container(
                                    width: 50,
                                    height: 50,
                                    child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white)),
                                  )
                                : IconButton(
                                    icon: Icon(isPlaying == true
                                        ? Icons.pause
                                        : Icons.play_arrow),
                                    iconSize: 50,
                                    color: Colors.white,
                                    onPressed: isPlaying == true
                                        ? widget._pause
                                        : widget._play,
                                  ),
                  )),
            ],
          )
        ],
      ),
    );
  }
}

///report dialog
class ReportDialog extends StatefulWidget {
  @override
  _MyDialogState createState() => _MyDialogState();
}

class _MyDialogState extends State<ReportDialog> {
  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 15.0),
        child: Text(
          'Report',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: primary, fontSize: 20),
        ),
      ),
      content: Column(
        children: <Widget>[
          Text('Your issue with this radio will be checked.'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: Material(
              color: Colors.transparent,
              child: TextField(
                controller: _text,
                decoration: InputDecoration(
                    hintText: 'Write your issue',
                    errorText: _validate ? 'Value Can\'t Be Empty' : null,
                    border: OutlineInputBorder()),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(
              'CANCEL',
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () {
              _validate = false;
              Navigator.pop(context, 'Cancel');
            }),
        CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(
              'SEND',
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () {
              if (!mounted) {
                return;
              }
              setState(() {
                _text.text.isEmpty ? _validate = true : _validate = false;
                if (_validate == false) {
                  radioReport(curPlayList[curPos].id, _text.text);
                  Navigator.pop(context, 'Cancel');
                }
              });
            }),
      ],
    );
  }

  Future<void> radioReport(String station_id, String msg) async {
    var data = {
      'access_key': '6808',
      'radio_station_id': station_id.toString(),
      'message': msg
    };
    var response = await http.post(report_api, body: data);

    // print("responce***getting**${response.body.toString()}");

    var getdata = json.decode(response.body);
    total = int.parse(getdata['total'].toString());
    //String error = getdata["error"].toString();

    //msg1 = getdata['message'].toString();
  }
}

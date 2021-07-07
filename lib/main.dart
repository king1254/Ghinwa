import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:app_review/app_review.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:phone_state_i/phone_state_i.dart';

import 'package:share/share.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'About_Us.dart';
import 'All_Radio_Station.dart';
import 'BottomPanel.dart';
import 'Category.dart';
import 'City.dart';
import 'Favorite.dart';
import 'Helper/Constant.dart';
import 'Helper/Favourite_Helper.dart';
import 'Helper/Model.dart';
import 'Home.dart';
import 'Now_Playing.dart';
import 'Privacy_Policy.dart';
import 'Splash.dart';
import 'Terms.dart';

void main() {
  Admob.initialize(getAppId());
  runApp(MyApp());
}

///root of your application, starting point of execution
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radio App',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: Directionality(
        textDirection: direction, // set this property
        child: Splash(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

///all radio station is loading
bool loading = true;

///offset for load more
int offset = 0;

///total radio station
int total = 0;

///no of item to load in one time
int perPage = 10;

///temp radio list for load more
List<Model> tempSongList = [];

///is error exist
bool errorExist = false;

///search list
List<Model> searchList = [];

///favorite database
var db = Favourite_Helper();

///bottom panel
PanelController panelController;

///after search result list
List<Model> searchresult = [];

///currently is searching
bool isSearching;

///home tab controller
TabController tabController;

///main contianer of app
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  StreamSubscription _streamSubscription;
  GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  final TextEditingController _controller = TextEditingController();
  DateTime _currentBackPressTime;

  Icon iconSearch = Icon(
    Icons.search,
    color: Colors.white,
  );

  Widget appBarTitle = Text(
    appname,
    style: TextStyle(color: Colors.white),
  );

  _MyHomePageState() {
    _controller.addListener(() {
      if (_controller.text.isEmpty) {
        if (!mounted) return;
        setState(() {
          isSearching = false;
          // _searchText = "";
        });
      } else {
        isSearching = true;
        // _searchText = _controller.text;
      }
    });
  }

  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    isSearching = false;
    panelController = PanelController();
    // Initialize the Tab Controller
    tabController = TabController(length: 3, vsync: this);
    firebaseCloudMessaging_Listeners();

    tempSongList.clear();
    radioList.clear();

    getRadioStation();

    initAudioPlayer();

    AudioPlayer.logEnabled = false;

    firNotInitialize();

    handlePhoneCall();
  }

  @override
  void dispose() {
    // print("disposing");
    _streamSubscription.cancel();

    if (!panelController.isPanelClosed()) {
      panelController.close();
    }
    // Dispose of the Tab Controller
    tabController.dispose();

    playerState = PlayerState.stopped;
    audioPlayer.stop();
    durationSubscription?.cancel();
    positionSubscription?.cancel();
    playerCompleteSubscription?.cancel();
    playerErrorSubscription?.cancel();
    playerStateSubscription?.cancel();

    super.dispose();
  }

  Future onDidReceiveLocalNotification(
      int id, String title, String body, String payload) {
    return showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyApp(),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Future onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(25.0),
      topRight: Radius.circular(25.0),
    );

    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            key: _globalKey,
            appBar: getAppbar(),
            drawer: getDrawer(),
            body: SlidingUpPanel(
                borderRadius: radius,
                panel: Now_Playing(
                  play: _play,
                  pause: _pause,
                  next: _next,
                  prev: _previous,
                  refresh: _refresh,
                ),
                minHeight: 65,
                controller: panelController,
                maxHeight: MediaQuery.of(context).size.height,
                backdropEnabled: true,
                backdropOpacity: 0.5,
                parallaxEnabled: true,
                collapsed: GestureDetector(
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: radius),
                    child: BottomPanel(
                      play: _play,
                      pause: _pause,
                    ),
                  ),
                  onTap: () {
                    panelController.open();
                  },
                ),
                body: getTabBarView(<Widget>[
                  Directionality(
                    textDirection: direction, // set this property
                    child: Home(
                      play: _play,
                      pause: _pause,
                      next: _next,
                      previous: _previous,
                    ),
                  ),
                  Directionality(
                    textDirection: direction, // set this property
                    child: cityMode
                        ? City(
                            play: _play,
                            refresh: _refresh,
                            next: _next,
                            previous: _previous,
                            pause: _pause)
                        : Category(
                            play: _play,
                            refresh: _refresh,
                            next: _next,
                            previous: _previous,
                            pause: _pause),
                  ),
                  Directionality(
                    textDirection: direction, // set this property
                    child: Radio_Station(
                      play: _play,
                      getCat: getRadioStation,
                      refresh: _refresh,
                      textController: _controller,
                    ),
                  ),
                ]))));
  }

  void firebaseCloudMessaging_Listeners() {
    if (Platform.isIOS) iOS_Permission();

    _firebaseMessaging.getToken().then((token) {
      _registerToken(token);
    });

    _firebaseMessaging.configure(
      onMessage: (message) async {
        //print('onmessage $message');
        await myBackgroundMessageHandler(message);
      },
      onResume: (message) async {
        // print('onresume $message');
        await myBackgroundMessageHandler(message);
      },
      onLaunch: (message) async {
        // print('onlaunch $message');
        await myBackgroundMessageHandler(message);
      },
      /*    onBackgroundMessage:(Map<String, dynamic> message) async {
        print('on message $message');
        myBackgroundMessageHandler(message);
      },*/
    );
  }

  static Future<dynamic> myBackgroundMessageHandler(
      Map<String, dynamic> message) async {
    if (message.containsKey('data') || message.containsKey('notification')) {
      // Handle data message

      var data = message['notification'];

      var image = data['image'].toString();
      var title = data['title'].toString();
      var msg = data['message'].toString();
      // String radio_id = data["radio_station_id"].toString();

      //  print("data***$image**$title**$msg***$data1***$data");

      if (image != null) {
        var bigPicturePath = await _downloadAndSaveImage(image, 'bigPicture');
        var bigPictureStyleInformation = BigPictureStyleInformation(
            bigPicturePath, BitmapSource.FilePath,
            hideExpandedLargeIcon: true,
            contentTitle: '$title',
            htmlFormatContentTitle: true,
            summaryText: '$msg',
            htmlFormatSummaryText: true);
        var androidPlatformChannelSpecifics = AndroidNotificationDetails(
            'big text channel id',
            'big text channel name',
            'big text channel description',
            largeIcon: bigPicturePath,
            largeIconBitmapSource: BitmapSource.FilePath,
            style: AndroidNotificationStyle.BigPicture,
            styleInformation: bigPictureStyleInformation);
        var platformChannelSpecifics =
            NotificationDetails(androidPlatformChannelSpecifics, null);
        await flutterLocalNotificationsPlugin.show(
            0, '$title', '$msg', platformChannelSpecifics);
      } else {
        var androidPlatformChannelSpecifics = AndroidNotificationDetails(
            'your channel id', 'your channel name', 'your channel description',
            importance: Importance.Max,
            priority: Priority.High,
            ticker: 'ticker');
        var iOSPlatformChannelSpecifics = IOSNotificationDetails();
        var platformChannelSpecifics = NotificationDetails(
            androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
        await flutterLocalNotificationsPlugin
            .show(0, title, msg, platformChannelSpecifics, payload: 'item x');
      }

      // print('on message $data');
    }
  }

  static Future<String> _downloadAndSaveImage(
      String url, String fileName) async {
    var directory = await getApplicationDocumentsDirectory();
    var filePath = '${directory.path}/$fileName';
    var response = await http.get(url);

    // print("path***$filePath");
    var file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  void _registerToken(String token) async {
    var data = {'access_key': '6808', 'token': token};

    var response = await http.post(
      token_api,
      body: data,
    );
    // print('Response status: ${response.statusCode}');
    //  print('Response body: ${response.body}***$token_api**$data');

    var getdata = json.decode(response.body);
    //var error = getdata['error'].toString();
    // if (error.compareTo('false') == 0) {}
  }

  void iOS_Permission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      //  print("Settings registered: $settings");
    });
  }

  Future<bool> _onWillPop() async {
    print('on back********$catVisible***$cityVisible*****$radioVisible');

    if (!panelController.isPanelClosed()) {
      panelController.close();
      return Future<bool>.value(false);
    }/* else if (!cityMode && !catVisible && tabController.index == 1) {
      setState(() {
        catVisible = true;
      });
      return Future<bool>.value(false);
    } else if (cityMode && catVisible && tabController.index == 1) {
      setState(() {
        catVisible = false;
        cityVisible = true;
      });
      return Future<bool>.value(false);
    } else if (cityMode && radioVisible && tabController.index == 1) {
      setState(() {
        radioVisible = false;
        catVisible = true;
        cityVisible = false;
      });
      return Future<bool>.value(false);
    }*/ else if (_globalKey.currentState.isDrawerOpen) {
      Navigator.pop(context); // closes the drawer if opened
      return Future.value(false); // won't exit the app
    } else {
      // dispose();
      //return Future.value(true);

      var now = DateTime.now();
      if (_currentBackPressTime == null ||
          now.difference(_currentBackPressTime) > Duration(seconds: 2)) {
        _currentBackPressTime = now;
        _globalKey.currentState.showSnackBar(SnackBar(
          content: Text(
            'Double tap to exit app',
            textAlign: TextAlign.center,
          ),
          backgroundColor: primary,
          behavior: SnackBarBehavior.floating,
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.0),
          ),
        ));
        return Future.value(false);
      }
      dispose();
      return Future.value(true);
    }
  }

  TabBarView getTabBarView(List<Widget> tabs) {
    return TabBarView(
      // Add tabs as widgets
      children: tabs,
      // set the controller
      controller: tabController,
      //  dragStartBehavior: DragStartBehavior.down,
    );
  }

  TabBar getTabBar() {
    return TabBar(
      tabs: <Tab>[
        Tab(
          text: 'Home',
        ),
        Tab(
          text: cityMode ? 'City' : 'Category',
        ),
        Tab(
          text: 'All Radio',
        ),
      ],
      // setup the controller
      controller: tabController,
    );
  }

  void getRadioStation() async {
    var data = {
      'access_key': '6808',
      'limit': perPage.toString(),
      'offset': offset.toString()
    };
    var response = await http.post(radio_station, body: data);

    //print("responce***getting**${response.body.toString()}");

    var getdata = json.decode(response.body);
    total = int.parse(getdata['total'].toString());
    var error = getdata['error'].toString();

    setState(() {
      if (error == 'true' || (total) == 0) {
        loading = false;
        errorExist = true;
      } else {
        var gData = getdata['data'];

        loading = false;

        if ((offset) < total) {
          tempSongList.clear();

          tempSongList = (gData as List)
              .map((data) => Model.fromJson(data as Map<String, dynamic>))
              .toList();

          radioList.addAll(tempSongList);

          curPlayList = radioList;
          url = curPlayList[0].radio_url;

          offset = offset + perPage;
        }
      }
    });
  }

  void initAudioPlayer() {
    audioPlayer = AudioPlayer(mode: mode);

    durationSubscription = audioPlayer.onDurationChanged.listen((duration1) {
      //print("duration change***$duration1");
      if (!mounted) {
        return;
      }
      setState(() => duration = duration1);

      // if (Theme.of(context).platform == TargetPlatform.iOS) {
      if (Platform.isIOS) {
        // set atleast title to see the notification bar on ios.
        audioPlayer.startHeadlessService();

        audioPlayer.setNotification(
            title: '$appname',
            artist: '${curPlayList[curPos].description}',
            albumTitle: '${curPlayList[curPos].cat_name}',
            imageUrl: '${curPlayList[curPos].image}',
            forwardSkipInterval: const Duration(seconds: 30),
            // default is 30s
            backwardSkipInterval: const Duration(seconds: 30),
            // default is 30s
            duration: duration1,
            elapsedTime: Duration(seconds: 0));
      }
    });

    positionSubscription =
        audioPlayer.onAudioPositionChanged.listen((p) => setState(() {
              position = p;
            }));

    playerCompleteSubscription = audioPlayer.onPlayerCompletion.listen((event) {
      _next();
      if (!mounted) {
        return;
      }
      setState(() {
        position = duration;
      });
    });

    playerErrorSubscription = audioPlayer.onPlayerError.listen((msg) {
      // print('audioPlayer error : $msg');
      if (!mounted) {
        return;
      }
      setState(() {
        playerState = PlayerState.stopped;
        duration = Duration(seconds: 0);
        position = Duration(seconds: 0);
      });
    });

    audioPlayer.onPlayerStateChanged.listen((state) {
      // print('audioPlayer state : $state');

      if (!mounted) {
        return;
      }
      setState(() {
        audioPlayerState = state;
      });
    });
    //  AudioPlayer.logEnabled = true;
    audioPlayer.onNotificationPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => audioPlayerState = state);
    });
  }

  void _next() async {
    curPos = curPos + 1;
    if (curPos < curPlayList.length) {
      final result = await audioPlayer.pause();
      if (result == 1) setState(() => playerState = PlayerState.paused);

      position = null;
      duration = null;
      url = curPlayList[curPos].radio_url;
      _play();
    } else {
      curPos = curPos - 1;
    }
  }

  void _previous() {
    curPos = curPos - 1;
    if (curPos >= 0) {
      // _pause();
      audioPlayer.pause();
      position = null;
      duration = null;
      url = curPlayList[curPos].radio_url;
      _play();
    } else {
      curPos = curPos + 1;
    }
  }

  void _play() async {
    final playPosition = (position != null &&
            duration != null &&
            position.inMilliseconds > 0 &&
            position.inMilliseconds < duration.inMilliseconds)
        ? position
        : null;

    print("play current**$url");
    final result =
        await audioPlayer.play(url, isLocal: isLocal, position: playPosition);
    if (!mounted) {
      return;
    }
    if (result == 1) {
      setState(() {
        playerState = PlayerState.playing;
      });
    }

    if (Platform.isIOS) {
      await audioPlayer.setPlaybackRate(playbackRate: 1.0);
    }
  }

  void _pause() async {

    if(Platform.isIOS){
      final result = await audioPlayer.pause();
      if (result == 1) {
        setState(() => playerState = PlayerState.paused);
      }
    }else {
      if (duration != null) {
        final result = await audioPlayer.pause();
        if (result == 1) {
          setState(() => playerState = PlayerState.paused);
        }
      }
    }
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> searchOperation(String searchText) async {
    if (isSearching != null) {
      var data = {'access_key': '6808', 'keyword': searchText};

      var response = await http.post('$search_api', body: data);
      var getdata = json.decode(response.body);

      var error = getdata['error'].toString();

      if (error == 'false') {
        searchresult.clear();
        searchList.clear();

        var data = (getdata['data']);

        searchList = (data as List)
            .map((data) => Model.fromJson(data as Map<String, dynamic>))
            .toList();
      }

      for (var i = 0; i < searchList.length; i++) {
        Model data = searchList[i];

        if (data.name.toLowerCase().contains(searchText.toLowerCase())) {
          searchresult.add(data);
        }
      }
      if (!mounted) return;
      setState(() {});
    }
  }

  void _handleSearchStart() {
    if (!mounted) return;
    setState(() {
      isSearching = true;
      tabController.animateTo(2);
      //_myTabbedPageKey.currentState.tabController.animateTo(2);
    });
  }

  void _handleSearchEnd() {
    if (!mounted) return;
    setState(() {
      iconSearch = Icon(
        Icons.search,
        color: Colors.white,
      );
      appBarTitle = Text(
        appname,
        style: TextStyle(color: Colors.white),
      );
      isSearching = false;
      _controller.clear();
      //searchresult.clear();
    });
  }

  void firNotInitialize() {
    ///for firebase push notification
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  void handlePhoneCall() {
    _streamSubscription = phoneStateCallEvent.listen((event) {
      //  print('Call is Incoming/Connected ' + event.stateC);

      var state = event.stateC;

      if (state.compareTo('true') == 0) {
        _pause();
        //print('Call is Incoming/Connected ' + event.stateC);
      } else {
        // print('Call is Incoming/Connected not' + event.stateC);

      }
    });
  }

  AppBar getAppbar() {
    return AppBar(
      title: appBarTitle,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [
                secondary,
                primary.withOpacity(0.5),
                primary.withOpacity(0.8)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              // Add one stop for each color. Stops should increase from 0 to 1
              stops: [0.15, 0.5, 0.7]),
        ),
      ),
      centerTitle: true,
      bottom: getTabBar(),
      actions: <Widget>[
        IconButton(
          icon: iconSearch,
          onPressed: () {
            //print("call search");
            if (!mounted) return;
            setState(() {
              if (iconSearch.icon == Icons.search) {
                iconSearch = Icon(
                  Icons.close,
                  color: Colors.white,
                );
                appBarTitle = TextField(
                  controller: _controller,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.white),
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.white),
                  ),
                  onChanged: searchOperation,
                );
                _handleSearchStart();
              } else {
                _handleSearchEnd();

                //print("cur list**${curPlayList.length}");
              }
            });
          },
        )
      ],
    );
  }

  Drawer getDrawer() {
    return Drawer(
      child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  secondary,
                  primary.withOpacity(0.5),
                  primary.withOpacity(0.8)
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                // Add one stop for each color. Stops should increase from 0 to 1
                stops: [0.2, 0.4, 0.9],
                tileMode: TileMode.clamp),
          ),
          child: ListView(
            physics: BouncingScrollPhysics(),
            children: <Widget>[
              Image.asset(
                'assets/image/logo.png',
                width: 150,
                height: 150,
              ),
              ListTile(
                  leading: Icon(Icons.home, color: Colors.white),
                  title: Text(
                    'Home',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    tabController.animateTo(0);
                  }),
              ListTile(
                  leading: Icon(Icons.category, color: Colors.white),
                  title: Text(
                    'Category',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    tabController.animateTo(1);
                  }),
              ListTile(
                  leading: Icon(Icons.radio, color: Colors.white),
                  title: Text(
                    'All Radio',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    tabController.animateTo(2);
                  }),
              ListTile(
                  leading: Icon(Icons.favorite, color: Colors.white),
                  title: Text(
                    'Favourite',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Directionality(
                            textDirection: direction,
                            // set this property
                            child: Favorite(
                              play: _play,
                              pause: _pause,
                              next: _next,
                              previous: _previous,
                            ),
                          ),
                        ));
                  }),
              Divider(),
              ListTile(
                  leading: Icon(Icons.share, color: Colors.white),
                  title: Text(
                    'Share App',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (Platform.isAndroid) {
                      Share.share('I am listening to-\n'
                          '$appname\n'
                          'https://play.google.com/store/apps/details?id=$androidPackage&hl=en');
                    } else {
                      Share.share('I am listening to-\n'
                          '$appname\n'
                          '$iosPackage');
                    }
                  }),
              ListTile(
                  leading: Icon(Icons.security, color: Colors.white),
                  title: Text(
                    'Privacy Policy',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Directionality(
                              textDirection: direction,
                              // set this property
                              child: Privacy_Policy()),
                        ));
                  }),
              ListTile(
                  leading: Icon(Icons.warning, color: Colors.white),
                  title: Text(
                    'Terms & Conditions',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Directionality(
                              textDirection: direction,
                              // set this property
                              child: Terms()),
                        ));
                  }),
              ListTile(
                  leading: Icon(Icons.info, color: Colors.white),
                  title: Text(
                    'About Us',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Directionality(
                              textDirection: direction,
                              // set this property
                              child: AboutUS()),
                        ));
                  }),
              ListTile(
                  leading: Icon(Icons.star, color: Colors.white),
                  title: Text(
                    'Rate App',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    AppReview.requestReview.then((onValue) {});
                  }),
            ],
          )),
    );
  }
}

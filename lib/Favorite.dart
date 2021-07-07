import 'dart:io';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'BottomPanel.dart';
import 'Helper/Constant.dart';
import 'Helper/Model.dart';
import 'Home.dart';
import 'Now_Playing.dart';
import 'main.dart';

///for bottom panel
PanelController panelController;

///list of search
List<Model> searchresult = [];

///currently searching
bool isSearching;

///radio station list
List<Model> radioStationList = [];

///sub category loading
bool subloading = true;


///favorite class
class Favorite extends StatefulWidget {
  VoidCallback _play, _pause, _next, _previous;

  ///constructor
  Favorite(
      {VoidCallback play,
      VoidCallback pause,
      VoidCallback next,
      VoidCallback previous})
      : _play = play,
        _pause = pause,
        _previous = previous,
        _next = next;

  @override
  _FavoriteState createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  final TextEditingController _controller = TextEditingController();
  AdmobInterstitial interstitialAd;

  Icon iconSerch = Icon(
    Icons.search,
    color: Colors.white,
  );

  Widget appBarTitle = Text(
    'Favorite',
    style: TextStyle(color: Colors.white),
  );

  _FavoriteState() {
    _controller.addListener(() {
      if (_controller.text.isEmpty) {
        if (!mounted) return;
        setState(() {
          isSearching = false;
          // _searchText = "";
        });
      } else {
        if (!mounted) return;
        setState(() {
          isSearching = true;
          //_searchText = _controller.text;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    isSearching = false;
    panelController = PanelController();

    admobInitalize();
    playerInitialize();
  }

  Future<bool> _onWillPop() async {
    if (await interstitialAd.isLoaded)
      interstitialAd.show();
    else
      Navigator.pop(context, true);
  }

  @override
  void dispose() {
    if (!panelController.isPanelClosed()) {
      panelController.close();
    }
    super.dispose();
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
            body: SlidingUpPanel(
                borderRadius: radius,
                panel: Now_Playing(
                  play: widget._play,
                  pause: widget._pause,
                  next: widget._next,
                  prev: widget._previous,
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
                      play: widget._play,
                      pause: widget._pause,
                    ),
                  ),
                  onTap: () {
                    panelController.open();
                  },
                ),
                body: getContent())));
  }

  Widget getFavorite() {
    return FutureBuilder(
      builder: (context, projectSnap) {
        if (projectSnap.connectionState == ConnectionState.none ||
            projectSnap.data == null) {
          return Center(child: CircularProgressIndicator());
        } else {
          favSize = int.parse(projectSnap.data.length.toString());
          radioStationList = projectSnap.data as List<Model>;

          return favSize == 0
              ? Material(
                  child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        child: Center(child: Text('No Favorites Found..!')),
                        height: MediaQuery.of(context).size.height -
                            150 -
                            kToolbarHeight -
                            24,
                      )),
                )
              : Padding(
                  padding: const EdgeInsets.only(bottom: 150),
                  child: ListView.builder(
                      physics: BouncingScrollPhysics(),
                      itemCount: int.parse(projectSnap.data.length.toString()),
                      shrinkWrap: true,
                      // projectSnap.data.length,

                      itemBuilder: (context, i) {
                        // print(projectSnap.data[i].name);
                        return GestureDetector(
                          child: Card(
                              elevation: 5.0,
                              child: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Row(
                                    children: <Widget>[
                                      Padding(
                                          padding: EdgeInsets.all(5.0),
                                          child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              child: FadeInImage(
                                                placeholder: AssetImage(
                                                  'assets/image/placeholder.png',
                                                ),
                                                image: NetworkImage(
                                                  projectSnap.data[i].image
                                                      .toString(),
                                                ),
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                              ))),
                                      Expanded(
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    //radioList[index].name,
                                                    projectSnap.data[i].name
                                                        .toString(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .subhead
                                                        .copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    // dense: true,
                                                  ),
                                                  Text(
                                                    projectSnap
                                                        .data[i].description
                                                        .toString(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .caption,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    // dense: true,
                                                  ),
                                                ],
                                              ))),
                                      IconButton(
                                          icon: Icon(
                                            Icons.play_arrow,
                                            size: 40,
                                            color: primary,
                                          ),
                                          onPressed: null),
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
                                                      await db.removeFav(
                                                          projectSnap.data[i].id
                                                              .toString());
                                                      setState(() {});

                                                      //widget.refresh();
                                                    })
                                                : IconButton(
                                                    icon: Icon(
                                                      Icons.favorite_border,
                                                      size: 30,
                                                      color: primary,
                                                    ),
                                                    onPressed: () async {
                                                      await db.setFav(
                                                          projectSnap.data[i].id
                                                              .toString(),
                                                          projectSnap
                                                              .data[i].name
                                                              .toString(),
                                                          projectSnap.data[i]
                                                              .description
                                                              .toString(),
                                                          projectSnap
                                                              .data[i].image
                                                              .toString(),
                                                          projectSnap
                                                              .data[i].radio_url
                                                              .toString());
                                                      setState(() {});

                                                      // widget.refresh();
                                                    });
                                          } else {
                                            return Container();
                                          }
                                        },
                                        future: db.getFav(
                                            projectSnap.data[i].id.toString()),
                                      ),
                                    ],
                                  ))),
                          onTap: () {
                            curPos = i;
                            curPlayList = projectSnap.data as List<Model>;
                            url = projectSnap.data[i].radio_url.toString();
                            position = null;
                            duration = null;
                            widget._play();

                            // print("current len**${curPlayList.length}");
                          },
                        );
                      }),
                );
        }
      },
      future: db.getAllFav(),
    );
  }

  Widget radiolistItem(int index, List<Model> catRadioList) {
    return GestureDetector(
      child: Card(
          elevation: 5.0,
          child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.all(5.0),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: FadeInImage(
                            placeholder: AssetImage(
                              'assets/image/placeholder.png',
                            ),
                            image: NetworkImage(
                              catRadioList[index].image,
                            ),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ))),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Text(
                      catRadioList[index].name,
                      style: Theme.of(context)
                          .textTheme
                          .subhead
                          .copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // dense: true,
                    ),
                  )),
                  IconButton(
                      icon: Icon(
                        Icons.play_arrow,
                        size: 40,
                        color: primary,
                      ),
                      onPressed: null),
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
                                  await db.removeFav(catRadioList[index].id);
                                  setState(() {});
                                  // widget.refresh();
                                })
                            : IconButton(
                                icon: Icon(
                                  Icons.favorite_border,
                                  size: 30,
                                  color: primary,
                                ),
                                onPressed: () async {
                                  await db.setFav(
                                      catRadioList[index].id,
                                      catRadioList[index].name,
                                      catRadioList[index].description,
                                      catRadioList[index].image,
                                      catRadioList[index].radio_url);
                                  if (!mounted) return;
                                  setState(() {});

                                  //  widget.refresh();
                                });
                      } else {
                        return Container();
                      }
                    },
                    future: db.getFav(catRadioList[index].id),
                  ),
                ],
              ))),
      onTap: () {
        curPos = index;
        curPlayList = catRadioList;
        url = catRadioList[curPos].radio_url;
        position = null;
        duration = null;
        if (!mounted) {
          return;
        }
        setState(() {
          widget._play();
        });
      },
    );
  }

  void _refresh() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void searchOperation(String searchText) {
    searchresult.clear();
    if (isSearching != null) {
      for (int i = 0; i < radioStationList.length; i++) {
        Model data = radioStationList[i];

        if (data.name.toLowerCase().contains(searchText.toLowerCase())) {
          //print("search**${searchText.toLowerCase()}***${data.name.toLowerCase()}**$i");
          searchresult.add(data);
        }
      }

      //  print("search**${searchresult.length}");
    }
  }

  void _handleSearchStart() {
    if (!mounted) {
      return;
    }
    setState(() {
      isSearching = true;

      //_myTabbedPageKey.currentState.tabController.animateTo(2);
    });
  }

  void _handleSearchEnd() {
    if (!mounted) {
      return;
    }
    setState(() {
      iconSerch = Icon(
        Icons.search,
        color: Colors.white,
      );
      appBarTitle = Text(
        appname,
        style: TextStyle(color: Colors.white),
      );
      isSearching = false;
      _controller.clear();
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
      actions: <Widget>[
        IconButton(
          icon: iconSerch,
          onPressed: () {
            setState(() {
              if (iconSerch.icon == Icons.search) {
                iconSerch = Icon(
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

                //  print("cur list**${curPlayList.length}");
              }
            });
          },
        )
      ],
    );
  }

  void playerInitialize() {
    durationSubscription = audioPlayer.onDurationChanged.listen((duration1) {
      //print("duration change***$duration1");
      if (!mounted) return;
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

    positionSubscription = audioPlayer.onAudioPositionChanged.listen((p) {
      if (!mounted) {
        return;
      }
      setState(() {
        position = p;
      });
    });

    playerCompleteSubscription = audioPlayer.onPlayerCompletion.listen((event) {
      widget._next();
      setState(() {
        position = duration;
      });
    });

    playerErrorSubscription = audioPlayer.onPlayerError.listen((msg) {
      // print('audioPlayer error : $msg');
      if (!mounted) return;
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
      if (!mounted) {
        return;
      }
      setState(() => audioPlayerState = state);
    });
  }

  void admobInitalize() {
    interstitialAd = AdmobInterstitial(
      adUnitId: getInterstitialAdUnitId(),
      listener: (AdmobAdEvent event, Map<String, dynamic> args) {
        if (event == AdmobAdEvent.closed) {
          interstitialAd.load();
          Navigator.pop(context, true);
        }
      },
    );

    interstitialAd.load();
  }

  getContent() {
    return isSearching &&
            (searchresult.isNotEmpty || _controller.text.isNotEmpty)
        ? ListView.builder(
            physics: BouncingScrollPhysics(),
            itemCount: searchresult.length,
            itemBuilder: (context, index) {
              return radiolistItem(index, searchresult);
            },
          )
        : getFavorite();
  }
}

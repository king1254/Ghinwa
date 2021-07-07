import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'All_Radio_Station.dart';
import 'BottomPanel.dart';
import 'Category.dart';
import 'City.dart';
import 'Helper/Constant.dart';
import 'Helper/Model.dart';
import 'Home.dart';
import 'Now_Playing.dart';
import 'main.dart';

///bottom panel
PanelController panelController;

///search result list
List<Model> searchresult = [];

///is currently searching
bool isSearching;
/*//String _searchText = "";
///is error exist
bool errorRadio = false;

///sub cat list
List<Model> catRadioList = [];

///is subcategory loading
bool subloading = true;*/

///sub category class
class SubCategory extends StatefulWidget {
  final VoidCallback _play, _pause, _next, _previous;

  final String _catId, _cityId;

  ///constructor
  SubCategory(
      {VoidCallback play,
      VoidCallback pause,
      VoidCallback next,
      VoidCallback previous,
      String cityId,
      String catId})
      : _play = play,
        _pause = pause,
        _next = next,
        _previous = previous,
        _cityId = cityId,
        _catId = catId;

  @override
  _SubCategoryState createState() => _SubCategoryState();
}

class _SubCategoryState extends State<SubCategory> {
  GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  final TextEditingController _controller = TextEditingController();
  List<Model> _radioList = [];

  bool _errorCat = false, _errorRadio = false;
  bool _catLoading = false, _radioLoading = false;

  Icon iconSearch = Icon(
    Icons.search,
    color: Colors.white,
  );

  Widget appBarTitle = Text(
    appname,
    style: TextStyle(color: Colors.white),
  );

  _SubCategoryState() {
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

    print('getting city mode*********$cityMode****${widget._cityId}****${widget._catId}');
    if (widget._catId.isNotEmpty) {
      catVisible = false;
      _radioLoading = true;
      getRadioCat(widget._catId);
    }else {
      catVisible = true;
      _errorCat = false;
      _catLoading = true;
      getCategory(widget._cityId);
    }/*else{
      catVisible = true;
      _errorCat = false;
      _catLoading = true;
      getCategory(widget._cityId);
    }*/
    playerInitialize();
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
    return WillPopScope(
        onWillPop: _onWillPop,
        child:
            Scaffold(key: _globalKey, appBar: getAppbar(), body: getContent()));
  }

  Widget subcatLayout() {
    return _radioLoading
        ? getLoader()
        : _errorRadio
            ? Container(
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  'No Radio Station Available..!!',
                  textAlign: TextAlign.center,
                ))
            : Padding(
                padding: const EdgeInsets.only(bottom: 150.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    itemCount: _radioList.length,
                    itemBuilder: (context, index) {
                      return radiolistItem(index, _radioList);
                    },
                  ),
                ));
  }

  Widget radiolistItem(int index, List<Model> catRadioList) {
    print("category*****${catRadioList[index].title}****$index");

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
                                  if (!mounted) {
                                    return;
                                  }
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
                                  if (!mounted) {
                                    return;
                                  }
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
      for (var i = 0; i < radioList.length; i++) {
        Model data = radioList[i];

        if (data.name.toLowerCase().contains(searchText.toLowerCase())) {
          searchresult.add(data);
        }
      }
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
    });
  }

  Future<void> getRadioCat(String catId) async {
    var data = {'access_key': '6808', 'category_id': catId};
    var response = await http.post(radio_bycat_api, body: data);

    var getdata = json.decode(response.body);

    var error = getdata['error'].toString();

    setState(() {
      _radioLoading = false;
      if (error == 'false') {
        var data1 = getdata['data'] as List;

        _radioList = data1
            .map((data) => Model.fromJson(data as Map<String, dynamic>))
            .toList();

        _errorRadio = false;
      } else {
        _errorRadio = true;
      }
    });
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
      if (!mounted) {
        return;
      }
      widget._next();

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
      if (!mounted) {
        return;
      }
      setState(() => audioPlayerState = state);
    });
  }

  getAppbar() {
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
          icon: iconSearch,
          onPressed: () {
            // print("call search");
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

                // print("cur list**${curPlayList.length}");
              }
            });
          },
        )
      ],
    );
  }

  getContent() {
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(25.0),
      topRight: Radius.circular(25.0),
    );
    return SlidingUpPanel(
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
            decoration:
                BoxDecoration(color: Colors.white, borderRadius: radius),
            child: BottomPanel(
              play: widget._play,
              pause: widget._pause,
            ),
          ),
          onTap: () {
            panelController.open();
          },
        ),
        body: isSearching &&
                (searchresult.isNotEmpty || _controller.text.isNotEmpty)
            ? ListView.builder(
                physics: BouncingScrollPhysics(),
                // controller: _controller,
                itemCount: searchresult.length,
                itemBuilder: (context, index) {
                  return radiolistItem(index, searchresult);
                },
              )
            : catVisible ? catLayout() : subcatLayout()

        //subcatLayout(),
        );
  }

  Widget catLayout() {
    return _catLoading ? getLoader() : _errorCat ? getErrorMsg() : getCatGrid();
  }

  getErrorMsg() {
    return Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.only(top: 20),
        child: Text(
          'No Category Available..!!',
          textAlign: TextAlign.center,
        ));
  }

  getLoader() {
    return Container(
        // height: 200,
        child: Center(child: CircularProgressIndicator()));
  }

/*  Widget catRadioLayout() {
    return _radioLoading
        ? getLoader()
        : _errorRadio
        ? Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.only(top: 20),
        child: Text(
          'No Radio Station Available..!!',
          textAlign: TextAlign.center,
        ))
        : Padding(
        padding: const EdgeInsets.only(bottom: 200.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: BouncingScrollPhysics(),
                  itemCount: int.parse(_catRadioList.length.toString()),
                  controller: _controller,
                  itemBuilder: (context, index) {
                    return radiolistItem(index);
                  },
                ),
              ),
            ),
            AdmobBanner(
              adUnitId: getBannerAdUnitId(),
              adSize: AdmobBannerSize.BANNER,
            ),
          ],
        ));
  }*/

  getCatGrid() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        physics: BouncingScrollPhysics(),
        shrinkWrap: true,
        itemCount: catList.length,
        //  controller: _controller,
        itemBuilder: (context, index) {
          return catListITem(index);
        },
      ),
    );
  }

  Widget catListITem(int index) {
    return GestureDetector(
      child: Card(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          elevation: 5.0,
          child: Stack(alignment: Alignment.bottomCenter, children: <Widget>[
            ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: FadeInImage(
                  placeholder: AssetImage(
                    'assets/image/placeholder.png',
                  ),
                  image: NetworkImage(
                    catList[index].image,
                  ),
                  height: double.maxFinite,
                  width: double.maxFinite,
                  fit: BoxFit.cover,
                )),
            Container(
              width: double.infinity,
              color: Colors.black.withOpacity(0.6),
              padding: const EdgeInsets.all(5.0),
              child: Text(
                catList[index].cat_name,
                style: Theme.of(context)
                    .textTheme
                    .subtitle
                    .copyWith(color: Colors.white),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ])),
      onTap: () {
        if (!mounted) return;
        setState(() {
          cityVisible = false;
          radioVisible = true;
          catVisible = false;
          _errorCat = false;

          _errorRadio = false;
          _radioLoading = true;
          getRadioCat(catList[index].id);
        });
      },
    );
  }

  Future<bool> _onWillPop() {
    print('cat back****$catVisible***$cityMode');

    if (cityMode && !catVisible) {
      setState(() {
        catVisible = true;
        //_catLoading=true;
        //_errorCat=false;
      });
      return Future<bool>.value(false);
    }
    else {
      dispose();
      return Future.value(true);
    }
  }

  Future getCategory(String id) async {
    var data = {'access_key': '6808', 'city_id': id};
    var response = await http.post(city_by_id, body: data);

    print('responce*****cat${response.body.toString()}');

    var getData = json.decode(response.body);

    var error = getData['error'].toString();

    setState(() {
      _catLoading = false;
      if (error == 'false') {
        var data1 = (getData['data']);
        // catList = (data as List).map((Map<String, dynamic>) => Model.fromJson(data)).toList();

        catList = (data1 as List)
            .map((data) => Model.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        _errorCat = true;
      }
    });
  }

}

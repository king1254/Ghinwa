import 'dart:convert';

import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:radio_app/City.dart';

import 'Helper/Constant.dart';
import 'Helper/Model.dart';
import 'Home.dart';
import 'SubCategory.dart';
import 'main.dart';

///for managing cat, sub-cat visibility in single layout
bool catVisible = false;

///category sub-cat claass
class Category extends StatefulWidget {
  final VoidCallback _play, _refresh, _next, _previous, _pause;

  ///constructor
  Category(
      {VoidCallback play,
      VoidCallback refresh,
      VoidCallback next,
      VoidCallback previous,
      VoidCallback pause})
      : _play = play,
        _refresh = refresh,
        _next = next,
        _previous = previous,
        _pause = pause;

  _Player_State createState() => _Player_State();
}

class _Player_State extends State<Category>
    with AutomaticKeepAliveClientMixin<Category> {
  //bool _errorRadio = false;
  ScrollController _controller;
  List<Model> _catRadioList = [];

  // bool _subloading = true;
  bool _errorExist = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(body: catLayout());
    //catVisible ? catLayout() : catRadioLayout());
  }

  Widget catLayout() {
    return catloading
        ? getLoader()
        : _errorExist ? getErrorMsg() : getCatGrid();
  }

/*
  Widget catRadioLayout() {
    return _subloading
        ? Container(
            height: 200, child: Center(child: CircularProgressIndicator()))
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
  }
*/

  @override
  void initState() {
    super.initState();
    //catVisible = true;
  }

  @override
  bool get wantKeepAlive => true;

  Widget listItem(int index) {
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
        /*    setState(() {
          catVisible = false;
          _errorExist = false;
          _errorRadio = false;
          _subloading = true;
          getRadioCat(catList[index].id);
        });*/

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SubCategory(
                      play: widget._play,
                      pause: widget._pause,
                      next: widget._next,
                      previous: widget._previous,
                      catId: catList[index].id,
                      cityId: "",
                    )));
      },
    );
  }

  Widget radiolistItem(int index) {
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
                              _catRadioList[index].image,
                            ),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ))),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Text(
                      _catRadioList[index].name,
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
                                  await db.removeFav(_catRadioList[index].id);
                                  if (!mounted) return;
                                  setState(() {});
                                  widget._refresh();
                                })
                            : IconButton(
                                icon: Icon(
                                  Icons.favorite_border,
                                  size: 30,
                                  color: primary,
                                ),
                                onPressed: () async {
                                  await db.setFav(
                                      _catRadioList[index].id,
                                      _catRadioList[index].name,
                                      _catRadioList[index].description,
                                      _catRadioList[index].image,
                                      _catRadioList[index].radio_url);
                                  if (!mounted) return;
                                  setState(() {});

                                  widget._refresh();
                                });
                      } else {
                        return Container();
                      }
                    },
                    future: db.getFav(_catRadioList[index].id),
                  ),
                ],
              ))),
      onTap: () {
        curPos = index;
        curPlayList = _catRadioList;
        url = _catRadioList[curPos].radio_url;
        position = null;
        duration = null;

        widget._play();
      },
    );
  }

  Future<void> getRadioCat(String catId) async {
    var data = {'access_key': '6808', 'category_id': catId};
    var response = await http.post(radio_bycat_api, body: data);

    //print("responce****cat**${response.toString()}");

    var getdata = json.decode(response.body);

    var error = getdata['error'].toString();
    if (!mounted) return null;
    setState(() {
      //_subloading = false;
      if (error == 'false') {
        var data1 = getdata['data'] as List;

        _catRadioList = data1
            .map((data) => Model.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        // _errorRadio = true;
      }
    });
  }

  getLoader() {
    return Container(
        height: 200, child: Center(child: CircularProgressIndicator()));
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

  getCatGrid() {
    return Padding(
        padding: const EdgeInsets.only(bottom: 200.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3),
                  physics: BouncingScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: catList.length,
                  controller: _controller,
                  itemBuilder: (context, index) {
                    return listItem(index);
                  },
                ),
              ),
            ),
            //  Spacer(),
            AdmobBanner(
              adUnitId: getBannerAdUnitId(),
              adSize: AdmobBannerSize.BANNER,
            ),
          ],
        ));
  }
}

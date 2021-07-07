import 'dart:async';

import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'Model.dart';
import 'package:flutter/material.dart';
import 'dart:io';

//app general string

///app name for your app
String appname='Radio Online';
///package name of your app
String androidPackage='com.app.radioonline';
///ios bundle name
String iosPackage='iosPackage';



///app id android
const String AD_MOB_APP_ID = 'ca-app-pub-4894557581829964~2745494539';
///banner ad id android
const String AD_MOB_BANNER_ANDROID='ca-app-pub-3940256099942544/6300978111';
///Interstitial ad id android
const String AD_MOB_INSTER_ANDROID = 'ca-app-pub-3940256099942544/1033173712';



///app id ios
const String AD_MOB_APP_ID_IOS = 'ca-app-pub-4894557581829964~8311943097';
///banner ad id ios
const String AD_MOB_BANNER_IOS='ca-app-pub-3940256099942544/2934735716';
///Interstitial id ios
const String AD_MOB_INSTER_IOS = 'ca-app-pub-3940256099942544/4411468910';
///in all radio no of item, after which ad should be display
const int AD_AFTER_ITEM=3;


///for rtl, ltr support change this to your value here
TextDirection direction=TextDirection.ltr;


///api url
String base_url='https://www.radio.wrteam.in/Api/';

///category api
String cat_api='$base_url''get_categories';
///get station by category
String radio_bycat_api='$base_url''get_radio_station_by_category';
///get radio station
String radio_station='$base_url''get_radio_station';
///get report api
String report_api='$base_url''radio_station_report';
///privacy policy api
String privacy_api='$base_url''get_privacy_policy';
/// about us api
String about_api='$base_url''get_about_us';
///terms and conditions api
String terms_api='$base_url''get_terms_conditions';
///firebase token register api
String token_api='$base_url''register_token';
///home page slider api
String slider_api='$base_url''get_slider';
///search api
String search_api='$base_url''search_station';
///city api
String city_api='$base_url''get_city';
///city by id
String city_by_id='$base_url''get_categories_by_city';
///get city mode
String city_mode='$base_url''get_city_mode';


//color

///primary color of your app
Color primary=Color(0xff1346fd);
///secondary color of your app
Color secondary=Color(0xff1399fd);



///common variable
bool useMobileLayout;
bool cityMode=false;



///music player variable
int curPos = 0;
List<Model> curPlayList = List();



///current player state
enum PlayerState { stopped, playing, paused }
///music player state
AudioPlayerState audioPlayerState;
///music player instance
AudioPlayer audioPlayer;
///player state
PlayerState playerState = PlayerState.stopped;
///get is currently playing
dynamic get isPlaying => playerState == PlayerState.playing;
///get is currently paushed
dynamic get isPaused => playerState == PlayerState.paused;
///song total duration
Duration duration;
/// song current position
Duration position;
///is song play from local
bool isLocal = false;
///media player mode
PlayerMode mode = PlayerMode.MEDIA_PLAYER;
///remote url
String url;


///duration listner
StreamSubscription durationSubscription;
///position change listner
StreamSubscription positionSubscription;
///complete listner
StreamSubscription playerCompleteSubscription;
///player error listner
StreamSubscription playerErrorSubscription;
///player state listner
StreamSubscription playerStateSubscription;





///get total duration
dynamic get durationText => duration?.toString()?.split('.')?.first ?? '';
///get current position
dynamic get positionText => position?.toString()?.split('.')?.first ?? '';


String getBannerAdUnitId() {
  if (Platform.isIOS) {
    return 'ca-app-pub-3940256099942544/2934735716';
  } else if (Platform.isAndroid) {
    return 'ca-app-pub-3940256099942544/6300978111';
  }
  return null;
}

String getInterstitialAdUnitId() {
  if (Platform.isIOS) {
    return AD_MOB_INSTER_IOS;
  } else if (Platform.isAndroid) {
    return AD_MOB_INSTER_ANDROID;
  }
  return null;
}

String getAppId() {
  if (Platform.isIOS) {
    return AD_MOB_APP_ID_IOS;
  } else if (Platform.isAndroid) {
    return AD_MOB_APP_ID;
  }
  return null;
}




import 'dart:isolate';
import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';


import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:nyimbo_za_injili_flutter/uploadSong.dart';

import 'FloatingAudioPlayer.dart';

import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'package:nyimbo_za_injili_flutter/dataStore.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

import 'downloadSong.dart';
import 'downloasTwo.dart';

import 'dart:isolate';
import 'dart:ui';
import 'dart:async';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

const debug = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await FlutterDownloader.initialize(debug: debug);

  runApp(new downloadTwox());
}


// You can also test with your own ad unit IDs by registering your device as a
// test device. Check the logs for your device's ID value.
//const String testDevice = 'YOUR_DEVICE_ID';
const int maxFailedLoadAttempts = 3;

class downloadTwox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    return new MaterialApp(
      title: 'Nyimbo za dini',
      theme: new ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: new MyHomePage(
        title: 'Nyimbo za injili',
        platform: platform,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget with WidgetsBindingObserver {
  final TargetPlatform? platform;

  MyHomePage({Key? key, this.title, this.platform}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}




class _MyHomePageState extends State<MyHomePage> {


  ////////////////////////////////////////

  static final AdRequest request = AdRequest(
    nonPersonalizedAds: true,
  );

  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;

  BannerAd? _anchoredBannerChini;
  bool _loadingAnchoredBannerChini = false;

  BannerAd? _anchoredBanner;
  bool _loadingAnchoredBanner = false;


  //////////////////////////////////////////////




  static bool isPlayerOpened = false;

  late bool searching, error,dataAvailable;
  var data;
  late String query;


  String dataurl = "https://www.zimaapps.com/APPS/NYIMBOZAINJILI/NYIMBOZAINJILI/newSongSearch.php";


  late List<dynamic> _videos = [
    {
      'name': 'Big Buck Bunny',
      'link':
      'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
    }
  ];

  List<_TaskInfo>? _tasks;
  late List<_ItemHolder> _items;
  late bool _isLoading;
  late bool _permissionReady;
  late String _localPath;
  ReceivePort _port = ReceivePort();


  onPaused() {
    setState(() {
      isPlayerOpened = false;
    });
  }


  get floatingActionItem {
    Widget floatingPlayer = FloatingAudioPlayer(onPaused: onPaused);

    Widget floatingActionButton = FloatingActionButton(
        backgroundColor: Colors.teal,
      onPressed: () {
        setState(() {
          //isPlayerOpened = true;
        });

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => uploadSong()),
        );
      },
      child: Icon(Icons.upload_file_outlined),
    );

    return AnimatedSwitcher(
      reverseDuration: Duration(milliseconds: 0),
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(child: child, scale: animation);
      },
      child: isPlayerOpened ? floatingPlayer : floatingActionButton,
    );
  }





  @override
  void initState() {
    super.initState();

    _createInterstitialAd();
    _createRewardedAd();



    searching = false;
    dataAvailable = false;
    error = false;

    const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz';
    Random _rnd = Random();

    String getRandomString(int length) => String.fromCharCodes(Iterable.generate(length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));


    query = getRandomString(5); //update the value of query
    print(query);
    getSuggestion();



    _bindBackgroundIsolate();

    FlutterDownloader.registerCallback(downloadCallback);

    _isLoading = true;
    _permissionReady = false;

    //isPlayerOpened = true;

    //_prepare();
  }





  //////////////////////////////////////////////////ADS/////////////////////
  ///////////////////////////////////////////////////////////////////////////



  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: 'ca-app-pub-4482019772887748/3676654894',
        request: request,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            print('$ad loaded');
            _interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('InterstitialAd failed to load: $error.');
            _numInterstitialLoadAttempts += 1;
            _interstitialAd = null;
            if (_numInterstitialLoadAttempts <= maxFailedLoadAttempts) {
              _createInterstitialAd();
            }
          },
        ));
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      print('Warning: attempt to show interstitial before loaded.');
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  void _createRewardedAd() {
    RewardedAd.load(
        adUnitId: 'ca-app-pub-4482019772887748/7244790691',
        request: request,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            print('$ad loaded.');
            _rewardedAd = ad;
            _numRewardedLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('RewardedAd failed to load: $error');
            _rewardedAd = null;
            _numRewardedLoadAttempts += 1;
            if (_numRewardedLoadAttempts <= maxFailedLoadAttempts) {
              _createRewardedAd();
            }
          },
        ));
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      print('Warning: attempt to show rewarded before loaded.');
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createRewardedAd();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (RewardedAd ad, RewardItem reward) {
      print('$ad with reward $RewardItem(${reward.amount}, ${reward.type}');
    });
    _rewardedAd = null;
  }

  Future<void> _createAnchoredBanner(BuildContext context) async {
    final AnchoredAdaptiveBannerAdSize? size =
    await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      MediaQuery.of(context).size.width.truncate(),
    );

    if (size == null) {
      print('Unable to get height of anchored banner.');
      return;
    }

    final BannerAd banner = BannerAd(
      size: size,
      request: request,
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-4482019772887748/6740682378'
          : 'ca-app-pub-4482019772887748/4800205152',
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('$BannerAd loaded.');
          setState(() {
            _anchoredBanner = ad as BannerAd?;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$BannerAd failedToLoad: $error');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => print('$BannerAd onAdOpened.'),
        onAdClosed: (Ad ad) => print('$BannerAd onAdClosed.'),
      ),
    );
    return banner.load();


  }


  Future<void> _createAnchoredBannerChini(BuildContext context) async {
    final AnchoredAdaptiveBannerAdSize? size =
    await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      MediaQuery.of(context).size.width.truncate(),
    );

    if (size == null) {
      print('Unable to get height of anchored banner.');
      return;
    }

    final BannerAd banner = BannerAd(
      size: size,
      request: request,
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-4482019772887748/1581724961'
          : 'ca-app-pub-4482019772887748/8683609848',
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('$BannerAd loaded.');
          setState(() {
            _anchoredBannerChini = ad as BannerAd?;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$BannerAd failedToLoad: $error');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => print('$BannerAd onAdOpened.'),
        onAdClosed: (Ad ad) => print('$BannerAd onAdClosed.'),
      ),
    );
    return banner.load();


  }


  @override
  void dispose() {
    super.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _anchoredBanner?.dispose();
    _anchoredBannerChini?.dispose();

    _unbindBackgroundIsolate();
  }





  ////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////////



  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      if (debug) {
        print('UI Isolate Callback: $data');
      }
      String? id = data[0];
      DownloadTaskStatus? status = data[1];
      int? progress = data[2];

      if (_tasks != null && _tasks!.isNotEmpty) {
        final task = _tasks!.firstWhere((task) => task.taskId == id);
        setState(() {
          task.status = status;
          task.progress = progress;
        });
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    if (debug) {
      print(
          'Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
    }
    final SendPort send =
    IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }




  _appBar(height) => PreferredSize(
    preferredSize:  Size(MediaQuery.of(context).size.width, height+43 ),
    child: Stack(
      children: <Widget>[
        Container(     // Background
          child: Center(
            child: Text("Nyimbo Za Dini", style: TextStyle(fontSize: 25.0,
                fontWeight: FontWeight.w600,
                color: Colors.white),),),
          color:Theme.of(context).primaryColor,
          height: height+75,
          width: MediaQuery.of(context).size.width,
        ),

        Container(),   // Required some widget in between to float AppBar

        Positioned(    // To take AppBar Size only
          top: 90.0,
          left: 20.0,
          right: 20.0,
          child: AppBar(
            backgroundColor: Colors.white,
            leading: Icon(Icons.menu, color: Theme.of(context).primaryColor,),
            primary: false,
            title: TextField(
                decoration: InputDecoration(
                    hintText: "Search",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey)),
              onChanged: (value){
                query = value; //update the value of query
                getSuggestion(); //start to get suggestion
              },),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.search,
                    color: Theme.of(context).primaryColor),
                onPressed: () {
                  setState(() {
                    searching = true;
                  });
                },),
              IconButton(icon: Icon(Icons.notifications, color: Theme.of(context).primaryColor),
                onPressed: () {},)
            ],
          ),
        ),



      ],
    ),
  );


  @override
  Widget build(BuildContext context) {

    return MaterialApp(
        home: Builder(builder: (BuildContext context)
        {
          if (!_loadingAnchoredBannerChini) {
            _loadingAnchoredBannerChini = true;
            _createAnchoredBannerChini(context);
          }
          if (!_loadingAnchoredBanner) {
            _loadingAnchoredBanner = true;
            _createAnchoredBanner(context);
          }

          return new Scaffold(
            appBar: _appBar(AppBar().preferredSize.height),


            body: Builder(builder: (context) =>_isLoading ? new Center(child: new CircularProgressIndicator(),)
                    : _permissionReady
                    ? _buildDownloadList()
                    : _buildNoPermissionWarning()),

            floatingActionButton: floatingActionItem,

              bottomNavigationBar: BottomAppBar(
              color: Colors.white,
              child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 00.0, vertical: 00.0),
                      child: Stack(
                      alignment: AlignmentDirectional.bottomCenter,
                      children: <Widget>[
                      //ReusableInlineExample(),
                      if (_anchoredBannerChini != null)
                      Container(
                      color: Colors.white,
                      width: _anchoredBannerChini!.size.width.toDouble(),
                      height: _anchoredBannerChini!.size.height.toDouble(),
                      child: AdWidget(ad: _anchoredBannerChini!),
                      ),
                      ],
                      ),
              ),
             ),

          );


        }

       )
    );



  }

  Widget _buildDownloadList() => Container(
    child: ListView(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      children: _items.map(
          (item) => item.task == null ?
          _buildListSection(item.title!)
          : DownloadItem(
              data: item,
              onItemClick: (task) {

                print("Ni Hapa?");

                _openDownloadedFile(task).then((success) {
                  if (!success) {
                    Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text('Cannot open this file')));
                  }
                });


              },
        onActionClick: (task) {
          if (task.status == DownloadTaskStatus.undefined) {
            _requestDownload(task);
          } else if (task.status == DownloadTaskStatus.running) {
            _pauseDownload(task);
          } else if (task.status == DownloadTaskStatus.paused) {
            _resumeDownload(task);
          } else if (task.status == DownloadTaskStatus.complete) {
            _delete(task);
          } else if (task.status == DownloadTaskStatus.failed) {
            _retryDownload(task);
          }

        },

          playClick: (task) {



          if (task.status == DownloadTaskStatus.complete) {

            _openDownloadedFile(task).then((success) {

              _showInterstitialAd();

              if (!success) {
                Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text('Cannot open this file')));
              }
            });
          }else{

            print(task.id!); //pint student id
            dataStore.currentSongSource = task.id!;
            dataStore.currentSongName = item.title!;

            setState(() {
              if(isPlayerOpened){
                isPlayerOpened = false;
              }else{
                isPlayerOpened = true;
              }
            });

            _showInterstitialAd();

          }

          },

      )
      ).toList(),


    ),
  );

  Widget _buildListSection(String title) =>   Stack(
          alignment: AlignmentDirectional.bottomCenter,
          children: <Widget>[
            //ReusableInlineExample(),
            if (_anchoredBanner != null)
              Container(
                color: Colors.white,
                width: _anchoredBanner!.size.width.toDouble(),
                height: _anchoredBanner!.size.height.toDouble(),
                child: AdWidget(ad: _anchoredBanner!),
              ),

          ]

  );

  Widget _buildNoPermissionWarning() => Container(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Please grant accessing storage permission to continue -_-',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey, fontSize: 18.0),
            ),
          ),
          SizedBox(
            height: 32.0,
          ),
          FlatButton(
              onPressed: () {
                _retryRequestPermission();
              },
              child: Text(
                'Retry',
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0),
              ))
        ],
      ),
    ),
  );

  Future<void> _retryRequestPermission() async {
    final hasGranted = await _checkPermission();

    if (hasGranted) {
      await _prepareSaveDir();
    }

    setState(() {
      _permissionReady = hasGranted;
    });
  }

  void _requestDownload(_TaskInfo task) async {

    _showRewardedAd();

    print(task.name);

    print(task.id);

    task.taskId = await FlutterDownloader.enqueue(
        url: task.id!,
        headers: {"auth": "test_for_sql_encoding"},
        savedDir: _localPath,
        showNotification: true,
        openFileFromNotification: true);
  }

  void _cancelDownload(_TaskInfo task) async {
    await FlutterDownloader.cancel(taskId: task.taskId!);
  }

  void _pauseDownload(_TaskInfo task) async {
    await FlutterDownloader.pause(taskId: task.taskId!);
  }

  void _resumeDownload(_TaskInfo task) async {
    String? newTaskId = await FlutterDownloader.resume(taskId: task.taskId!);
    task.taskId = newTaskId;
  }

  void _retryDownload(_TaskInfo task) async {
    String? newTaskId = await FlutterDownloader.retry(taskId: task.taskId!);
    task.taskId = newTaskId;
  }

  Future<bool> _openDownloadedFile(_TaskInfo? task) {
    if (task != null) {
      return FlutterDownloader.open(taskId: task.taskId!);
    } else {
      return Future.value(false);
    }
  }

  void _delete(_TaskInfo task) async {
    await FlutterDownloader.remove(
        taskId: task.taskId!, shouldDeleteContent: true);
    await _prepare();
    setState(() {});
  }

  Future<bool> _checkPermission() async {
    if (widget.platform == TargetPlatform.android) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  Future<Null> _prepare() async {
    final tasks = await FlutterDownloader.loadTasks();

    int count = 0;
    _tasks = [];
    _items = [];

    print("XXXXX" +_videos.toString());


    _tasks!.addAll(_videos.map((video) => _TaskInfo(name: video['title'], id: "https://www.zimaapps.com/APPS/NYIMBOZAINJILI/NYIMBOZAINJILI/nyimbo/"+video['source'])));

    //_tasks!.addAll(_videos.map((video) => _TaskInfo(name: video['title'], id: "https://www.zimaapps.com/APPS/NYIMBOZAINJILI/NYIMBOZAINJILI/")));




    print(_tasks);

    _items.add(_ItemHolder(title: 'Nyimbo latest'));
    for (int i = count; i < _tasks!.length; i++) {
      _items.add(_ItemHolder(title: _tasks![i].name, task: _tasks![i]));
      count++;
    }

    tasks!.forEach((task) {
      for (_TaskInfo info in _tasks!) {
        if (info.id == task.url) {
          info.taskId = task.taskId;
          info.status = task.status;
          info.progress = task.progress;
        }
      }
    });

    _permissionReady = await _checkPermission();

    if (_permissionReady) {
      await _prepareSaveDir();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _prepareSaveDir() async {
    _localPath =
        (await _findLocalPath())! + Platform.pathSeparator + 'Download';

    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
  }

  Future<String?> _findLocalPath() async {
    final directory = widget.platform == TargetPlatform.android
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    return directory?.path;
  }







  void getSuggestion() async{  //get suggestion function
    var res = await http.post(Uri.parse((dataurl + "?query=")+ Uri.encodeComponent(query)));
    //var res = await http.get(Uri.parse(link), headers: {"Accept": "application/json"});
    //in query there might be unwant character so, we encode the query to url
    if (res.statusCode == 200) {
      setState(() {
        data = json.decode(res.body);

        _videos =data["data"];

        List suggestionlist = List.from(
            data["data"].map((i){
              return SearchSuggestion.fromJSON(i);
            })
        );


        print(_videos);

        _prepare();


        dataAvailable = true;
        //update data value and UI
        //_prepare();

      });
    }else{
      //there is error
      setState(() {
        error = true;
      });
    }
  }









  Widget searchField(){ //search input field
    return Container(
        child:TextField(
          autofocus: true,
          style: TextStyle(color:Colors.white, fontSize: 18),
          decoration:InputDecoration(
            hintStyle: TextStyle(color:Colors.white, fontSize: 18),
            hintText: "Search Songs",
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color:Colors.white, width:2),
            ),//under line border, set OutlineInputBorder() for all side border
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color:Colors.white, width:2),
            ), // focused border color
          ), //decoration for search input field
          onChanged: (value){
            query = value; //update the value of query
            getSuggestion(); //start to get suggestion
          },
        )
    );
  }

















}




//serarch suggestion data model to serialize JSON data
class SearchSuggestion{
  String id, name;
  SearchSuggestion({required this.id, required this.name});

  factory SearchSuggestion.fromJSON(Map<String, dynamic> json){
    return SearchSuggestion(
      id: json["source"],
      name: json["title"],

    );
  }
}





class DownloadItem extends StatelessWidget {
  final _ItemHolder? data;
  final Function(_TaskInfo?)? onItemClick;
  final Function(_TaskInfo)? onActionClick;
  final Function(_TaskInfo)? playClick;

  DownloadItem({this.data, this.onItemClick, this.onActionClick, required this.playClick});





  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16.0, right: 8.0),
      child: InkWell(
        onTap: data!.task!.status == DownloadTaskStatus.complete
            ? () {

          //print(data);
          onItemClick!(data!.task);
        }: null,





        child: Stack(
          children: <Widget>[


            Column(
                children: [
                  ListTile(
                    title: Text(data!.title!,
                      style: TextStyle(fontSize: 12.0, color: Colors.grey, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,),
                    //subtitle: Text("The battery is full."),
                    //leading: Icon(Icons.play_arrow_outlined, size: 28.0),
                    leading: ClipOval(
                        child: Material(
                          color: Colors.teal, // Button color
                          child: InkWell(
                            splashColor: Colors.red, // Splash color
                            onTap: () {},
                            child: SizedBox(width: 40, height: 40, child: Icon(Icons.play_arrow_outlined, size: 30.0,  color: Colors.white),
                            ),
                          ),
                        ) ),
                    //trailing: Icon(Icons.star),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        new Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: _buildActionForTask(data!.task!),
                        ),
                        //Icon(Icons.person, size: 38.0),
                      ],


                    ),

                    onTap: () {
                      print("Tapped mbali");

                      //_MyHomePageState.isPlayerOpened = true;
                      playClick!(data!.task!);
                    }


                  ),



                  data!.task!.status == DownloadTaskStatus.running ||
                      data!.task!.status == DownloadTaskStatus.paused
                      ? LinearProgressIndicator(
                      value: data!.task!.progress! / 100,
                      backgroundColor: Colors.grey,
                      valueColor: new AlwaysStoppedAnimation<Color>(Colors.teal),
                    ):Container(),




                  Divider(),
                ]

            ),







          ].toList(),
        ),
      ),
    );
  }

  Widget? _buildActionForTask(_TaskInfo task) {
    if (task.status == DownloadTaskStatus.undefined) {
      return RawMaterialButton(
        onPressed: () {
          onActionClick!(task);
        },
        child: Icon(Icons.file_download),
        shape: CircleBorder(),
        constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
      );
    } else if (task.status == DownloadTaskStatus.running) {
      return RawMaterialButton(
        onPressed: () {
          onActionClick!(task);
        },
        child: Icon(
          Icons.pause,
          color: Colors.red,
        ),
        shape: CircleBorder(),
        constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
      );
    } else if (task.status == DownloadTaskStatus.paused) {
      return RawMaterialButton(
        onPressed: () {
          onActionClick!(task);
        },
        child: Icon(
          Icons.play_arrow,
          color: Colors.green,
        ),
        shape: CircleBorder(),
        constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
      );
    } else if (task.status == DownloadTaskStatus.complete) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Tayari',
            style: TextStyle(color: Colors.green),
          ),
          RawMaterialButton(
            onPressed: () {
              onActionClick!(task);
            },
            child: Icon(
              Icons.delete_forever,
              color: Colors.red,
            ),
            shape: CircleBorder(),
            constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
          )
        ],
      );
    } else if (task.status == DownloadTaskStatus.canceled) {
      return Text('Canceled', style: TextStyle(color: Colors.red));
    } else if (task.status == DownloadTaskStatus.failed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Failed', style: TextStyle(color: Colors.red)),
          RawMaterialButton(
            onPressed: () {
              onActionClick!(task);
            },
            child: Icon(
              Icons.refresh,
              color: Colors.green,
            ),
            shape: CircleBorder(),
            constraints: BoxConstraints(minHeight: 32.0, minWidth: 32.0),
          )
        ],
      );
    } else if (task.status == DownloadTaskStatus.enqueued) {
      return Text('Pending', style: TextStyle(color: Colors.orange));
    } else {
      return null;
    }
  }




  openPlayer(_ItemHolder data) {
    //when tapped on suggestion
    print(data.task!.id); //pint student id
    dataStore.currentSongSource = data.task!.id!;
    dataStore.currentSongName = data.title!;
    //Navigator.push(context, MaterialPageRoute(builder: (context) => new kikobaProfilePage()));

    print("Au  ni huku!");

    // setState(() {
    //
    //
    //   if(isPlayerOpened){
    //     isPlayerOpened = false;
    //   }else{
    //     isPlayerOpened = true;
    //   }
    //
    //
    //
    // });

        }



}




class _TaskInfo {
  final String? name;
  final String? id;

  String? taskId;
  int? progress = 0;
  DownloadTaskStatus? status = DownloadTaskStatus.undefined;

  _TaskInfo({this.name, this.id});
}

class _ItemHolder {
  final String? title;
  final _TaskInfo? task;

  _ItemHolder({this.title, this.task});
}




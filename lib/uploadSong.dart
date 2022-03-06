import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path/path.dart';

import 'main.dart';


class uploadSong extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
        home: CustomFilePicker() //set the class here
    );
  }
}

class CustomFilePicker extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _CustomFilePicker();
  }
}

class _CustomFilePicker extends State<CustomFilePicker>{

  static final AdRequest request = AdRequest(
    keywords: <String>['foo', 'bar'],
    contentUrl: 'http://foo.com/bar.html',
    nonPersonalizedAds: true,
  );


  BannerAd? _anchoredBanner;
  bool _loadingAnchoredBanner = false;

  BannerAd? _anchoredBannerChini;
  bool _loadingAnchoredBannerChini = false;

  late File selectedfile;
  late Response response;
  late String progress = "0";
  Dio dio = new Dio();

  String songname = "";
  String songsize = "";



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


  @override
  void dispose() {
    super.dispose();

    _anchoredBanner?.dispose();
    _anchoredBannerChini?.dispose();

  }


  selectFile() async {


    //for file_pocker plugin version 2 or 2+

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
      //allowed extension to choose
    );

    if (result != null) {
      //if there is selected file
      selectedfile = File(result.files.single.path!);

      PlatformFile file = result.files.first;
      //File file = File(result.files.first.path);

      print(file.name);
      setState(() {
        songname = file.name;
        //songsize = 'the value is $file.size' file.size.toString();
      });

      print(file.bytes);
      print(file.size);
      print(file.extension);
      print(file.path);

    }

    setState((){}); //update the UI so that file name is shown
  }

  uploadFile() async {
    String uploadurl = "https://www.zimaapps.com/APPS/NYIMBOZAINJILI/NYIMBOZAINJILI/uploadSong.php";
    //dont use http://localhost , because emulator don't get that address
    //insted use your local IP address or use live URL
    //hit "ipconfig" in windows or "ip a" in linux to get you local IP

    print(uploadurl);

    print(selectedfile.path);

    FormData formdata = FormData.fromMap({
      "file": await MultipartFile.fromFile(
          selectedfile.path,
          filename: basename(selectedfile.path)
        //show only filename from path
      ),
    });

    response = await dio.post(uploadurl,
      data: formdata,
      onSendProgress: (int sent, int total) {
        String percentage = (sent/total*100).toStringAsFixed(2);
        setState(() {
          progress = percentage + " %";
          //update the progress
        });
      },);

    if(response.statusCode == 200){
      print(response);
      //print response from server

      Navigator.push(
        this.context,
        MaterialPageRoute(builder: (context) => downloadTwox()),
      );
    }else{
      print("Error during connection to server.");
    }
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
        home: Builder(builder: (BuildContext context)
    {
      if (!_loadingAnchoredBanner) {
        _loadingAnchoredBanner = true;
        _createAnchoredBanner(context);
      }

      return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  this.context,
                  MaterialPageRoute(builder: (context) => downloadTwox()),
                );
              },
            ),
            title: Text("Upload Wimbo"),
            backgroundColor: Colors.teal,
          ), //set appbar
          body: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(40),
              child: Column(children: <Widget>[

                Stack(
                        alignment: AlignmentDirectional.bottomCenter,
                        children: <Widget>[
                          //ReusableInlineExample(),
                          if (_anchoredBannerChini != null)
                            Container(
                              color: Colors.white,
                              width: _anchoredBanner!.size.width.toDouble(),
                              height: _anchoredBanner!.size.height.toDouble(),
                              child: AdWidget(ad: _anchoredBanner!),
                            ),

                        ]

                ),


                Container(
                  margin: const EdgeInsets.only(top: 80, bottom:20, left: 20.0, right: 20.0),
                  //show file name here
                  // ignore: unnecessary_null_comparison
                  child: Text(
                    "Sambaza upendo wa bwana kwa ku shea nyimbo za dini ulizo nazo kwenye simu yako. Bonyeza 'Chagua nyimbo' sasa",
                    style: TextStyle(fontSize: 14),),
                  //basename is from path package, to get filename from path
                  //check if file is selected, if yes then show file name
                ),


                Container(
                    child: RaisedButton.icon(
                      onPressed: () {
                        selectFile();
                      },
                      icon: Icon(Icons.folder_open),
                      label: Text("CHAGUA WIMBO"),
                      color: Colors.teal,
                      colorBrightness: Brightness.dark,
                    )
                ),


                Container(
                  margin: EdgeInsets.all(20),
                  //show file name here
                  child: Text(basename("Progress: $progress"),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),),
                  //show progress status here
                ),


                Container(
                  margin: EdgeInsets.all(10),
                  //show file name here
                  // ignore: unnecessary_null_comparison
                  child: Text(songname),
                  //basename is from path package, to get filename from path
                  //check if file is selected, if yes then show file name
                ),


                //if selectedfile is null then show empty container
                //if file is selected then show upload button
                Container(
                    child: RaisedButton.icon(
                      onPressed: () {
                        uploadFile();
                      },
                      icon: Icon(Icons.upload_outlined),
                      label: Text("UPLOAD WIMBO"),
                      color: Colors.teal,
                      colorBrightness: Brightness.dark,
                    )
                )

              ],)
          )
      );
    }
    )
    );

  }
}
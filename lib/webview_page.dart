import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key, required this.uri});

  final String uri;  

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
   _WebViewPageState();

  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);
  final urlController = TextEditingController();

  String url       = "";
  double progress  = 0;
  int    countLoad = 0;
  //bool   onHome    = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
        PopScope<Object?>(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) {
              return;
            }

            if (webViewController != null) {
              webViewController!.evaluateJavascript(
                source:'''
                  window.app.onHome();
                ''',
              ).then((val) {
                if (val.runtimeType == bool) {
                  if (val) {
                    //webViewController?.evaluateJavascript(source:'''alert("1 onHome");''',);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  } else {
                    //webViewController?.evaluateJavascript(source:'''alert("1 NOT onHome");''',);
                    webViewController?.evaluateJavascript(source: """            
                        var keyEvent = new KeyboardEvent("keydown", {key : "GoBack"});
                        document.dispatchEvent(keyEvent);
                      """);
                  }
                } 
              });
            }
          },
          child:
            Focus( //KeyboardListener
              //focusNode: FocusNode(),
              //autofocus: true,
              onKeyEvent: (node, event) => handleKey(event, context, webViewController),
              child: 
                SafeArea(
                  child: Column(children: <Widget>[
                    Expanded(
                      child: Stack(
                        children: [
                          InAppWebView(
                            key: webViewKey,
                            initialUrlRequest:
                              URLRequest(url: WebUri(widget.uri)),
                           initialSettings: settings,
                             onWebViewCreated: (controller) {
                              webViewController = controller;
                            },
                            onLoadStart: (controller, url) {
                              setState(() {
                                this.url = url.toString();
                                urlController.text = this.url;
                              });
                            },
                            onPermissionRequest: (controller, request) async {
                              return PermissionResponse(
                                resources: request.resources,
                                action: PermissionResponseAction.GRANT);
                            },
                            onLoadStop: (InAppWebViewController controller, url) async {
                              // every time a page is re-loaded this method is called
                              // we want to focus the controller the first time, that's the reason we use this control
                              // but every subsequent time it will reset the focus, which we dont want
                              // current solution is only do it once
                              // if this is not good enough we will need to 
                              // 1. get current element id
                              // 2. requestFocus()
                              // 3. setFocus()
                              if (countLoad == 0) {
                                setState(() {
                                  this.url = url.toString();
                                  urlController.text = this.url;
                                });
                                controller.requestFocus();
                              }
                              countLoad++;
                            },
                            onReceivedError: (controller, request, error) {
                            },
                            onProgressChanged: (controller, progress) {
                              if (progress == 100) {
                              }
                               setState(() {
                                 this.progress = progress / 100;
                                 urlController.text = url;
                              });
                            },
                            onUpdateVisitedHistory: (controller, url, androidIsReload) {
                              setState(() {
                                this.url = url.toString();
                                urlController.text = this.url;
                              });
                            },
                            onConsoleMessage: (controller, consoleMessage) {
                              if (kDebugMode) {
                                print(consoleMessage);
                              }
                            },
                          ),
                          progress < 1.0
                            ? LinearProgressIndicator(value: progress)
                            : Container(),
                        ],
                      ),
                    ),
                  ]
                )
              )
            )
      )
    );
  }

  KeyEventResult handleKey(KeyEvent event, BuildContext context, InAppWebViewController? controller) {
    if (controller != null) {
      if (event is KeyDownEvent) {
        String? keyName;
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          keyName = "ArrowUp";
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          keyName = "ArrowDown";
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          keyName = "ArrowRight";
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          keyName = "ArrowLeft";
        } /*
        else if (event.logicalKey == LogicalKeyboardKey.goBack) {
          // check if we have back-keyed all the way back to Home
          if (webViewController != null) {
            webViewController!.evaluateJavascript(
              source:'''
                window.app.onHome();
              ''',
            ).then((val) {
              if (val.runtimeType == bool) {
                onHome = val;
                if (onHome) {
                  webViewController?.evaluateJavascript(source:'''alert("1 onHome");''',);
                } else {
                  webViewController?.evaluateJavascript(source:'''alert("1 NOT onHome");''',);
                }
              } 
            });
          }
          keyName = "GoBack";
        }
        */
        if (keyName != null) {
          controller.evaluateJavascript(source: """            
            var keyEvent = new KeyboardEvent("keydown", {key : "$keyName"});
            document.dispatchEvent(keyEvent);
            """);
          return KeyEventResult.handled;
        }
      }      
    }
    return KeyEventResult.ignored;
  }
}

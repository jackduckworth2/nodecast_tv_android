import 'dart:async';
import 'package:custom_tv_text_field/custom_tv_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import './webview_page.dart';

class AppColors {
  //static final Color focusColor    = Colors.blue;
  //static final Color unfocusColor  = Colors.white;

  static final Color bgPrimary     = const Color(0xff0a0a0f);
  static final Color bgSecondary   = const Color(0xff12121a);
  static final Color bgTertiary    = const Color(0xff1a1a25);
  static final Color bgHover       = const Color(0xff22222f);
  static final Color bgActive      = const Color(0xff2a2a3a);
  static final Color textPrimary   = const Color(0xfff1f1f5);
  static final Color textSecondary = const Color(0xffa1a1aa);
  static final Color textMuted     = const Color(0xff71717a);
  static final Color accent        = const Color(0xff6366f1);
  static final Color accentHover   = const Color(0xff818cf8);
  static final Color success       = const Color(0xff10b981);
  static final Color warning       = const Color(0xfff59e0b);
  static final Color error         = const Color(0xffef4444);
  static final Color border        = const Color(0xff27272a);
  static final Color borderLight   = const Color(0xff3f3f46);
  
}

class LoginPage extends StatefulWidget {
  const LoginPage ({super.key, required this.uri});

  final String uri;
  @override
  LoginPageState createState() => LoginPageState();
}

enum ConnectSection { url, connectButton }

class LoginPageState extends State<LoginPage> {

  final FocusNode                         _screenFocusNode = FocusNode();
  final GlobalKey<FormState>              _formKey         = GlobalKey<FormState>();
  final ValueNotifier<ConnectSection>     _currentSection  = ValueNotifier<ConnectSection>(ConnectSection.url);
  final ValueNotifier<bool>               _hasKeyboardOpen = ValueNotifier<bool>(false);

  late  TextEditingController             _urlController;
  final GlobalKey<CustomTVTextFieldState> _urlKey          = GlobalKey<CustomTVTextFieldState>();

  LoginPageState ();
    
  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.uri);
    _screenFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _screenFocusNode.dispose();
    _urlController.dispose();
    _currentSection.dispose();
    _hasKeyboardOpen.dispose();
    super.dispose();
  }

  bool _canHandleKeys() => _screenFocusNode.hasFocus && !_hasKeyboardOpen.value;

  KeyEventResult _handleKeyEvent(KeyEvent event, BuildContext context) {
    if (!_canHandleKeys() ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }

    final handlers = {
      LogicalKeyboardKey.arrowUp: () => _navigate(-1),
      LogicalKeyboardKey.arrowDown: () => _navigate(1),
      LogicalKeyboardKey.enter: () => _handleSelect(context),
      LogicalKeyboardKey.select: () => _handleSelect(context),
    };

    final handler = handlers[event.logicalKey];
    if (handler != null) {
      handler();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _navigate(int delta) {
    final nextIndex = (ConnectSection.values.indexOf(_currentSection.value) + delta);
    if (nextIndex >= 0 && nextIndex < ConnectSection.values.length) {
      _currentSection.value = ConnectSection.values[nextIndex];
    }
  }

  void _handleSelect(BuildContext context) {
    switch (_currentSection.value) {
      case ConnectSection.url:
        _urlKey.currentState?.toggleKeyboard();
        break;
      case ConnectSection.connectButton:
        _submitConnect(context);
        break;
    }
  }

  void _submitConnect(BuildContext context) async {

    // basic validation
    final Uri?   uri = Uri.tryParse(_urlController.value.text);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid url ${_urlController.value.text}'),),);
      return;
    }
    // stupid package expects a trailing slash for soem reason => append trailing slash
    if ( !uri.hasAbsolutePath && (!_urlController.value.text.endsWith('\\')) ) {
      _urlController.text = '${_urlController.value.text}/';
    }

    final String url = _urlController.value.text;
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connecting to $url'),),);
      if (await validateUrl(url)) {

        // Save url value to shared preferences
        SharedPreferences.getInstance().then ((prefs) => prefs.setString('url', url));

        if (context.mounted) {
          // open webview
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewPage(uri: url,)
            ),
          );
        }
      } else { // error loading url
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error connecting to $url'),),);
        }
      }

    } else { // url failed validation
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid url: $url'),),);
    }
  }
  
  Future<bool> validateUrl (String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        // peek at html and validate if it is a valid nodecast tv url 
        final String html = response.body;
        return ( (html.contains('nodecast-tv')) || (html.contains('NodeCast TV')) );
      }
      return false;
    }
    catch (ex) { // error connecting to url
      return false;
    }
  }  

  @override
  Widget build(BuildContext context) {
  
    return Focus (
      focusNode: _screenFocusNode,
      onKeyEvent: (_, event) => _handleKeyEvent(event, context),
      child: 
        Scaffold(
          appBar: AppBar(title: const Text("Connect to nodecast-tv")),
          backgroundColor: AppColors.bgPrimary,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: ValueListenableBuilder<ConnectSection>(
                  valueListenable: _currentSection,
                  builder: (context, section, _) => ValueListenableBuilder<bool>(
                    valueListenable: _hasKeyboardOpen,
                    builder: (context, hasKeyboardOpen, _) => 
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [

                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              'nodecast-tv',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                              textAlign: TextAlign.center,
                            )
                          ),

                          SizedBox(
                            width: double.infinity,
                            height: 80,
                            child: 
                              CustomTVTextField(
                                key: _urlKey,
                                controller: _urlController,
                                textStyle: TextStyle(color: AppColors.textPrimary),
                                hint: "Enter URL",
                                prefixIcon: const Icon(Icons.tv, color: Colors.white70),
                                isFocused: section == ConnectSection.url && !hasKeyboardOpen,
                                onVisibilityChanged: (v) => _hasKeyboardOpen.value = v,
                                onFieldSubmitted: (_) {}, // Removed unused onSubmitted parameter
                                keyboardType: KeyboardType.alphabetic,
                                backgroundColor: AppColors.bgTertiary,
                                focusedBorderColor: AppColors.accent,
                                borderColor: AppColors.border,
                                borderRadius: 10,
                                isRequired: true, // Removed unused validator parameter
                                textFieldType: TextFieldType.url,
                                maxLines: 1,
                              ),
                          ),

                          SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 49,
                            child: 
                              ConnectButton(
                                isSelected: section == ConnectSection.connectButton && !hasKeyboardOpen,
                                onTap: _submitConnect,
                                context: context,
                              ),
                          ),

                        ]
                      ),
                  ),
                ),
              ),
            )
          )
        )
    );
  }

}

class ConnectButton extends StatelessWidget {
  final bool isSelected;
  final Function(BuildContext) onTap;
  final BuildContext context;

  const ConnectButton({super.key, required this.isSelected, required this.onTap, required this.context});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onTap(context),
      style: 
        ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.accent : AppColors.accentHover,
          side: BorderSide(width: 2, color: isSelected ? AppColors.accent : AppColors.border,)
          ),
      //style: ButtonStyle(
      //  backgroundColor: WidgetStateProperty.all<Color>(AppColors.accent),),
      child: Text(
        'Open URL',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold 
        ),
      ),
    );
  }
}

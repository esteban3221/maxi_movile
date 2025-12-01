class GlobalVar {
  static final GlobalVar _instance = GlobalVar._internal();
  factory GlobalVar() {
    return _instance;
  }
  GlobalVar._internal();

  String apiIp = '';
  String get apiUrl => 'http://$apiIp:44333/';
  String appVersion = '1.0.0';

  String userToken = '';
}

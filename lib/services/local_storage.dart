import 'dart:async';
import 'package:flibusta/route.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<List<String>> getPreviousBookSearches() async {
    var prefs = await _prefs;
    try {
      var previousBookSearches = prefs.getStringList('previousBookSearches');
      return previousBookSearches ?? [];
    } catch (e) {
      print('getPreviousBookSearches Error: ' + e);
      return [];
    }
  }

  Future<bool> setPreviousBookSearches(List<String> previousBookSearches) async {
    var prefs = await _prefs;
    try {
      return prefs.setStringList('previousBookSearches', previousBookSearches ?? []);
    } catch (e) {
      print('setPreviousBookSearches Error: ' + e);
      return false;
    }
  }

  Future<bool> getIntroCompleted() async {
    var prefs = await _prefs;
    try {
      var introCompleted = prefs.getBool('IntroCompleted');
      if (introCompleted == null) {
        prefs.setBool('IntroCompleted', false);
        introCompleted = false;
      }
      return introCompleted;
    } catch (e) {
      prefs.setBool('IntroCompleted', false);
      return false;
    }
  }

  Future<bool> setIntroCompleted() async {
    var prefs = await _prefs;
    return prefs.setBool('IntroCompleted', true);
  }

  Future<String> getActualProxy() async {
    var prefs = await _prefs;
    try {
      var actualProxy = prefs.getString('ActualProxy');
      if (actualProxy == null) {
        prefs.setString('ActualProxy', '');
        actualProxy = '';
      }
      return actualProxy;
    } catch (e) {
      prefs.setString('ActualProxy', '');
      return '';
    }
  }

  Future<bool> setActualProxy(String ipPort) async {
    var prefs = await _prefs;
    return prefs.setString('ActualProxy', ipPort);
  }

  Future<List<String>> getProxies() async {
    var prefs = await _prefs;
    try {
      var proxies = prefs.getStringList('Proxies');
      if (proxies == null) {
        prefs.setStringList('Proxies', List<String>());
        proxies = List<String>();
      }
      return proxies;
    } catch (e) {
      prefs.setStringList('Proxies', List<String>());
      return List<String>();
    }
  }

  Future<bool> addProxy(String proxy) async {
    var prefs = await _prefs;
    var proxies = await getProxies();
    if (proxies.contains(proxy))
      return true;
    
    proxies.add(proxy);
    return prefs.setStringList('Proxies', proxies);
  }

  Future<bool> deleteProxy(String proxy) async {
    var prefs = await _prefs;
    var proxies = await getProxies();
    if (!proxies.contains(proxy))
      return true;

    proxies.remove(proxy);
    return prefs.setStringList('Proxies', proxies);
  }

  Future<String> getFlibustaHostAddress() async {
    var prefs = await _prefs;
    try {
      var flibustaHostAddress = prefs.getString('FlibustaHostAddress');
      if (flibustaHostAddress == null) {
        prefs.setString('FlibustaHostAddress', 'flibusta.is');
        flibustaHostAddress = 'flibusta.is';
      }
      return flibustaHostAddress;
    } catch (e) {
      prefs.setString('FlibustaHostAddress', 'flibusta.is');
      return '';
    }
  }

  Future<bool> setFlibustaHostAddress(String hostAddress) async {
    var prefs = await _prefs;
    return prefs.setString('FlibustaHostAddress', hostAddress);
  }

  Future<void> checkVersion() async {
    var prefs = await _prefs;
    if (prefs.getString('VersionCode') != FlibustaApp.versionName) {
      _clearPrefs(prefs);
      prefs.setString('VersionCode', FlibustaApp.versionName);
    }
  }

  Future<bool> _clearPrefs(SharedPreferences prefs) async {
    return prefs.clear();
  }
}
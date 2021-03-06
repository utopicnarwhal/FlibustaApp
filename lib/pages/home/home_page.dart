import 'dart:async';

import 'package:flibusta/blocs/grid/grid_data/grid_data_bloc.dart';
import 'package:flibusta/blocs/grid/selected_view_type/selected_view_type_bloc.dart';
import 'package:flibusta/blocs/proxy_list/proxy_list_bloc.dart';
import 'package:flibusta/blocs/user_contact_data/user_contact_data_bloc.dart';
import 'package:flibusta/model/enums/gridViewType.dart';
import 'package:flibusta/pages/home/views/books_view/books_view.dart';
import 'package:flibusta/pages/home/views/general_view/general_view.dart';
import 'package:flibusta/pages/home/views/profile_view/profile_view.dart';
import 'package:flibusta/pages/home/views/proxy_settings/proxy_settings_page.dart';
import 'package:flibusta/services/http_client/http_client.dart';
import 'package:flibusta/services/local_storage.dart';
import 'package:flibusta/services/server_status_checker.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/Home';

  @override
  createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  SelectedViewTypeBloc _selectedViewTypeBloc = SelectedViewTypeBloc();
  StreamSubscription _selectedViewTypeSubscription;
  BehaviorSubject<int> _selectedNavItemController = BehaviorSubject<int>();
  StreamSubscription _selectedNavItemSubscription;
  BehaviorSubject<List<String>> _favoriteGenreCodesController;

  ProxyListBloc _proxyListBloc;
  ServerStatusChecker _serverStatusChecker;

  List<GridDataBloc> _gridDataBlocsList = [];
  TextEditingController _searchTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initNavItemController();
    _initGridData();
    ProxyHttpClient().isAuthorized().then((value) {
      if (value) {
        UserContactDataBloc().fetchUserContactData();
      }
    });
    _favoriteGenreCodesController = BehaviorSubject<List<String>>();
    _proxyListBloc = ProxyListBloc();
    _serverStatusChecker = ServerStatusChecker();
  }

  void _initNavItemController() async {
    var latestHomeViewNum = await LocalStorage().getLatestHomeViewNum();
    _selectedNavItemController.add(latestHomeViewNum);
    _selectedNavItemSubscription = _selectedNavItemController.listen((int newHomeViewNum) {
      LocalStorage().putLatestHomeViewNum(newHomeViewNum);
    });
  }

  void _initGridData() async {
    _gridDataBlocsList = [];
    for (var gridViewType in [
      GridViewType.newBooks,
      GridViewType.genres,
      GridViewType.authors,
      GridViewType.sequences,
      GridViewType.downloaded,
    ]) {
      _gridDataBlocsList.add(GridDataBloc(gridViewType));
    }

    _selectedViewTypeSubscription = _selectedViewTypeBloc.stream.listen(_onSelectedViewTypeChange);

    _selectedViewTypeBloc.changeViewType(GridViewType.newBooks);

    var favoriteGenreCodes = await LocalStorage().getFavoriteGenreCodes();
    if (!mounted) return;
    _favoriteGenreCodesController.add(favoriteGenreCodes);
  }

  void _onSelectedViewTypeChange(GridViewType selectedViewType) async {
    if ((_gridDataBlocsList[selectedViewType.index]?.state?.searchString ?? '') != _searchTextController.text) {
      _gridDataBlocsList[selectedViewType.index]?.searchByString(_searchTextController.text);
    }
    if (_gridDataBlocsList[selectedViewType.index]?.state?.stateCode == GridDataStateCode.Empty) {
      _gridDataBlocsList[selectedViewType.index]?.fetchGridData();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      initialData: 0,
      stream: _selectedNavItemController,
      builder: (context, selectedNavigationItemSnapshot) {
        if (!selectedNavigationItemSnapshot.hasData) {
          return Container();
        }

        switch (selectedNavigationItemSnapshot.data) {
          case 0:
            return GeneralView(
              scaffoldKey: _scaffoldKey,
              selectedNavItemController: _selectedNavItemController,
            );
          case 1:
            return BooksView(
              scaffoldKey: _scaffoldKey,
              selectedNavItemController: _selectedNavItemController,
              searchTextController: _searchTextController,
              selectedViewTypeBloc: _selectedViewTypeBloc,
              gridDataBlocsList: _gridDataBlocsList,
              favoriteGenreCodesController: _favoriteGenreCodesController,
            );
          case 2:
            return ProxySettingsPage(
              scaffoldKey: _scaffoldKey,
              proxyListBloc: _proxyListBloc,
              selectedNavItemController: _selectedNavItemController,
              serverStatusChecker: _serverStatusChecker,
            );
          case 3:
            return ProfileView(
              scaffoldKey: _scaffoldKey,
              selectedNavItemController: _selectedNavItemController,
            );
          default:
        }
        return Container();
      },
    );
  }

  @override
  void dispose() {
    _gridDataBlocsList?.forEach((gridDataBloc) {
      gridDataBloc?.close();
    });
    _searchTextController?.dispose();
    _selectedNavItemSubscription?.cancel();
    _selectedNavItemController?.close();
    _selectedViewTypeSubscription?.cancel();
    _selectedViewTypeBloc?.close();
    _favoriteGenreCodesController?.close();
    _proxyListBloc?.dispose();
    _serverStatusChecker?.dispose();
    super.dispose();
  }
}

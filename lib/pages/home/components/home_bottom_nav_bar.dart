import 'dart:async';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeBottomNavBar extends StatelessWidget {
  final StreamController<int> selectedNavItemController;
  final int index;

  const HomeBottomNavBar({
    Key key,
    @required this.selectedNavItemController,
    @required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        key: Key('HomeBottomNavBar'),
        elevation: 0,
        currentIndex: index,
        unselectedFontSize: 10,
        selectedFontSize: 12,
        backgroundColor: Theme.of(context).cardColor,
        items: [
          BottomNavigationBarItem(
            icon: Icon(EvaIcons.homeOutline),
            title: Text('Главная'),
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.book),
            title: Text('Книги'),
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Icon(
                FontAwesomeIcons.projectDiagram,
                size: 18,
              ),
            ),
            title: Text('Прокси'),
          ),
          BottomNavigationBarItem(
            icon: Icon(EvaIcons.personOutline),
            title: Text('Профиль'),
          ),
        ],
        onTap: selectedNavItemController.add,
      ),
    );
  }
}

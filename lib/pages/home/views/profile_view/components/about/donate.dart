import 'package:flare_flutter/flare_actor.dart';
import 'package:flibusta/constants.dart';
import 'package:flibusta/ds_controls/ui/app_bar.dart';
import 'package:utopic_toast/utopic_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info/package_info.dart';

class DonatePage extends StatelessWidget {
  static const String routeName = '/Donate';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DsAppBar(title: Text('Поддержать разработчика')),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, packageInfo) {
          return ListView(
            physics: kBouncingAlwaysScrollableScrollPhysics,
            addSemanticIndexes: false,
            padding: EdgeInsets.symmetric(vertical: 20),
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 150,
                child: FlareActor(
                  'assets/animations/cloud.flr',
                  animation: 'Animations',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Text(
                  'Не стоит отправлять мне деньги, если они нужны вам самим.',
                ),
              ),
              Divider(),
              Material(
                type: MaterialType.card,
                borderRadius: BorderRadius.zero,
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: Text('Сбербанк'),
                      subtitle: Text('4276 3801 2889 9718'),
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: '4276380128899718'),
                        );
                        ToastManager().showToast(
                          'Номер карты скопирован в буфер обмена',
                        );
                      },
                      trailing: Icon(
                        FontAwesomeIcons.clipboard,
                        size: 30.0,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(),
            ],
          );
        },
      ),
    );
  }
}

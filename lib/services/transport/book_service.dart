import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flibusta/model/bookCard.dart';
import 'package:flibusta/model/bookInfo.dart';
import 'package:flibusta/pages/home/components/show_download_format_mbs.dart';
import 'package:flibusta/services/http_client/http_client.dart';
import 'package:flibusta/services/local_notification_service.dart';
import 'package:flibusta/services/local_storage.dart';
import 'package:flibusta/utils/file_utils.dart';
import 'package:flibusta/utils/html_parsers.dart';
import 'package:flibusta/utils/native_methods.dart';
import 'package:flibusta/utils/permissions_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:utopic_toast/utopic_toast.dart';
import 'package:flutter/material.dart';
import 'package:flibusta/model/extension_methods/dio_error_extension.dart';

class BookService {
  static Future<BookInfo> getBookInfo(int bookId) async {
    Uri url = Uri.https(
      ProxyHttpClient().getHostAddress(),
      "/b/" + bookId.toString(),
    );
    var response = await ProxyHttpClient().getDio().getUri<String>(url);

    return parseHtmlFromBookInfo(response.data, bookId);
  }

  static Future<List<int>> getBookCoverImage(String coverImgSrc) async {
    var url = Uri.https(
      ProxyHttpClient().getHostAddress(),
      coverImgSrc,
    );

    var response = await ProxyHttpClient().getDio().getUri<List<int>>(
          url,
          options: Options(
            responseType: ResponseType.bytes,
          ),
        );

    return response.data;
  }

  static Future<void> downloadBook(
    BuildContext context,
    BookCard bookCard,
    void Function(double) downloadProgressCallback,
  ) async {
    await PermissionsUtils.requestAccess(
      context,
      Permission.storage,
    );

    Map<String, String> downloadFormat;
    var preferredBookExt = await LocalStorage().getPreferredBookExt();
    if (preferredBookExt != null) {
      downloadFormat = bookCard.downloadFormats.list.firstWhere(
        (bookFormat) => preferredBookExt == bookFormat.keys.first,
        orElse: () => null,
      );
    }
    if (downloadFormat == null) {
      downloadFormat = await showDownloadFormatMBS(context, bookCard);
      if (downloadFormat == null) {
        return;
      }
    }

    Directory saveDocDir = await LocalStorage().getBooksDirectory();
    saveDocDir = Directory(saveDocDir.path);
    if (!saveDocDir.existsSync()) {
      saveDocDir.createSync(recursive: true);
      await NativeMethods.rescanFolder(saveDocDir.path);
    }

    Uri url = Uri.https(
      ProxyHttpClient().getHostAddress(),
      '/b/${bookCard.id}/${downloadFormat.values.first}',
    );
    String fileUri = '';
    CancelToken cancelToken = CancelToken();

    NotificationService().showNotificationWithProgress(
      notificationId: bookCard.id,
      notificationTitle: bookCard.title,
      notificationBody: '',
      progress: 0.0,
    );
    downloadProgressCallback(0.0);
    var prepareToDownloadToastFuture = _alertsCallback(
      'Подготовка к загрузке',
      Duration(seconds: 8),
      action: ToastAction(
        label: 'Отменить',
        onPressed: (hideToast) {
          hideToast();
          if (cancelToken.isCancelled) {
            return;
          }
          cancelToken.cancel('Загрузка отменена');
        },
      ),
    );

    var response = await ProxyHttpClient()
        .getDio()
        .downloadUri(
          url,
          (Headers responseHeaders) {
            ToastManager().hideToast(prepareToDownloadToastFuture);

            var contentDisposition = responseHeaders['content-disposition'];
            if (contentDisposition == null) {
              NotificationService().cancelNotification(bookCard.id);
              downloadProgressCallback(null);
              cancelToken.cancel(
                'Доступ к книге ограничен по требованию правоторговца. Воспользуйтесь Tor Onion Proxy, чтобы скачать эту книгу.',
              );
              return fileUri;
            }

            try {
              var fileName = contentDisposition[0]
                  .split('filename=')[1]
                  .replaceAll('\"', '');

              fileUri = saveDocDir.path + '/' + fileName;
            } catch (e) {
              NotificationService().cancelNotification(bookCard.id);
              downloadProgressCallback(null);
              cancelToken.cancel('Не удалось получить имя файла');
              return fileUri;
            }

            var myFile = File(fileUri);
            if (myFile.existsSync()) {
              NotificationService().cancelNotification(bookCard.id);
              downloadProgressCallback(null);
              cancelToken.cancel('Файл с таким именем уже есть');
              return fileUri;
            }

            bookCard.localPath = fileUri;
            return fileUri;
          },
          cancelToken: cancelToken,
          options: Options(
            sendTimeout: 10000,
            receiveTimeout: Duration(minutes: 5).inMilliseconds,
            receiveDataWhenStatusError: false,
          ),
          onReceiveProgress: (int count, int total) {
            if (cancelToken.isCancelled) {
              NotificationService().cancelNotification(bookCard.id);
              downloadProgressCallback(null);
            } else {
              NotificationService().showNotificationWithProgress(
                notificationId: bookCard.id,
                notificationTitle: bookCard.title,
                notificationBody: 'Скачивание',
                progress: (count / total) * 100,
              );
              downloadProgressCallback(count / total);
            }
          },
        )
        .catchError((error) {
      if (cancelToken.isCancelled) {
        ToastManager().showToast(cancelToken.cancelError.message);
        return null;
      }
      ToastManager().hideToast(prepareToDownloadToastFuture);
      if (error is DsError) {
        _alertsCallback(
          error.toString(),
          Duration(seconds: 5),
        );
      }
    });

    if (response == null ||
        (response.statusCode != 200 && response.statusCode != 302)) {
      ToastManager().hideToast(prepareToDownloadToastFuture);
      NotificationService().cancelNotification(bookCard.id);
      downloadProgressCallback(null);
      return;
    }

    await NativeMethods.rescanFolder(fileUri);
    await LocalStorage().addDownloadedBook(bookCard);

    _alertsCallback(
      'Файл скачан',
      Duration(seconds: 5),
      action: ToastAction(
        label: 'Открыть',
        onPressed: (hideToast) {
          FileUtils.openFile(fileUri);
          hideToast();
        },
      ),
    );

    NotificationService().cancelNotification(bookCard.id);
    downloadProgressCallback(null);
  }

  static ToastFuture _alertsCallback(String alertText, Duration alertDuration,
      {ToastAction action}) {
    if (alertText.isEmpty) {
      return null;
    }

    return ToastManager().showToast(
      alertText,
      duration: alertDuration,
      action: action,
    );
  }
}

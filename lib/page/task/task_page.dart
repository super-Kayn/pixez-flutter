import 'dart:collection';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:pixez/generated/l10n.dart';
import 'package:pixez/main.dart';
import 'package:pixez/models/illust.dart';
import 'package:pixez/page/picture/illust_page.dart';

class TaskEntity {
  final Illusts illusts;

  String taskId;
  DownloadTaskStatus status;
  int progress;
  String url;
  String filename;
  String savedDir;
  int timeCreated;
  TaskEntity(
    DownloadTask downloadTask,
    this.illusts,
  ) {
    this.taskId = downloadTask.taskId;
    this.status = downloadTask.status;
    this.progress = downloadTask.progress;
    this.url = downloadTask.url;
    this.filename = downloadTask.filename;
    this.savedDir = downloadTask.savedDir;
    this..timeCreated = downloadTask.timeCreated;
  }
}

class TaskPage extends StatefulWidget {
  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_pro');
    _port.listen((dynamic data) {
      try {
        String id = data[0];
        DownloadTaskStatus status = data[1];
        int progress = data[2];
        if (_list != null && _list.isNotEmpty) {
          final task = _list?.firstWhere((task) => task.taskId == id);
          if (task != null) {
            setState(() {
              task.status = status;
              task.progress = progress;
            });
          }
        }
      } catch (e) {
        debugPrint(e);
      }
    });
    initMethod();
  }

  List<TaskEntity> _list;
  initMethod() async {
    _list = [];
    final tasks = await FlutterDownloader.loadTasks();
    tasks.forEach((element) {
      final data = saveStore.maps[element.taskId];
      if (data != null) {
        _list.add(TaskEntity(element, data.illusts));
      }
    });
    setState(() {});
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_pro');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.of(context).Task_progress),
      ),
      body: Container(
        child: _list != null
            ? ListView.builder(
                itemCount: _list.length,
                itemBuilder: (context, index) {
                  final data = _list[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => IllustPage(id: data.illusts.id))),
                    onLongPress: () => _buildOptions(context, data),
                    child: ListTile(
                      title: Text(data.illusts.title ?? ''),
                      subtitle: Text(data.progress.toString() ?? ''),
                      trailing: data.progress == 100
                          ? Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                          : CircularProgressIndicator(
                              value: data.progress / 100,
                            ),
                    ),
                  );
                })
            : Container(),
      ),
    );
  }

  Future _buildOptions(BuildContext context, TaskEntity data) {
    return showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return SafeArea(
              child: Column(
            children: <Widget>[
              ListTile(
                title: Text('Retry'),
                onTap: () {
                  FlutterDownloader.retry(taskId: data.taskId);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text('Remove'),
                onTap: () {
                  FlutterDownloader.remove(taskId: data.taskId);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ));
        });
  }
}

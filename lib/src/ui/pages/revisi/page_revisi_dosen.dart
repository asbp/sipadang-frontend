import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:input_nilai/src/models/model_akademik.dart';
import 'package:input_nilai/src/ui/pages/revisi/page_revisi_detail.dart';
import 'package:input_nilai/src/ui/pages/revisi/page_revisi_form.dart';
import 'package:input_nilai/src/ui/widgets/revisi/widget_revisi_dosen_item.dart';
import 'package:input_nilai/src/ui/widgets/widget_basic.dart';
import 'package:input_nilai/src/utils/util_akademik.dart';
import 'package:line_icons/line_icons.dart';
import 'package:theme_provider/theme_provider.dart';

class PageRevisiDosen extends StatefulWidget {
  DosenSidang dosenSidang;
  RESTAkademik rest;

  PageRevisiDosen({@required this.dosenSidang, @required this.rest});

  @override
  State<StatefulWidget> createState() => _PageRevisiDosenState();
}

class _PageRevisiDosenState extends State<PageRevisiDosen> {
  DosenSidang dosenSidang;
  RESTAkademik _rest;
  Future<List<Revisi>> _revisi;

  bool _shouldUpdated = false;

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop(_shouldUpdated);
    return false;
  }

  @override
  initState() {
    super.initState();
    dosenSidang = widget.dosenSidang;
    _rest = widget.rest;

    _revisi = _rest.getNilai(dosenSidang.idStatus).then((val) => val.revisi);
  }

  _refresh() {
    setState(() {
      _revisi = _rest.getNilai(dosenSidang.idStatus).then((val) => val.revisi);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
          appBar: AppBar(
            title: Text('Halaman Revisi'),
            elevation: 0.0,
            leading: IconButton(
              icon: Icon(LineIcons.arrow_left),
              onPressed: () => Navigator.of(context).pop(_shouldUpdated),
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(LineIcons.refresh),
                onPressed: () {
                  _refresh();
                },
              ),
              IconButton(
                icon: Icon(LineIcons.plus),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ThemeConsumer(
                                  child: PageRevisiForm(
                                dosen: dosenSidang,
                                rest: _rest,
                              )))).then((val) {
                    if (val) _refresh();
                  });
                },
              )
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () {
              _refresh();
              return Future.value(true);
            },
            child: FutureBuilder<List<Revisi>>(
              future: _revisi,
              builder: (BuildContext futureContext,
                  AsyncSnapshot<List<Revisi>> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return loading();
                  default:
                    if (snapshot.hasError) {
                      return center_text("Gagal memuat data revisi.");
                    } else if (snapshot.data.isEmpty) {
                      return center_text("Tidak ada data.");
                    } else {
                      return ListView(
                        children: snapshot.data.map((item) {
                          return Material(
                            color: ThemeProvider.themeOf(context)
                                .data
                                .scaffoldBackgroundColor,
                            child: InkWell(
                                child: RevisiDosenItem(item),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ThemeConsumer(
                                                  child: RevisiDetailPage(
                                                rest: _rest,
                                                revisi: item,
                                              )))).then((val) {
                                    if (val) _refresh();
                                  });
                                }),
                          );
                        }).toList(),
                      );
                    }
                }
              },
            ),
          )),
    );
  }
}
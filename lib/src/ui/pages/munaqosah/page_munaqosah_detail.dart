import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:line_icons/line_icons.dart';

import '../../../models/model_akademik.dart';
import '../../../utils/util_akademik.dart';
import '../../../utils/util_penilaian.dart';
import '../../../utils/util_penilaian_dosen.dart';
import '../../widgets/cards/widget_card_sidang.dart';
import '../../widgets/detail_sidang/widget_penilaian.dart';
import '../../widgets/detail_sidang/widget_revisi_button.dart';
import '../../widgets/widget_boolean_builder.dart';
import '../../widgets/widget_buttons.dart';

class PageMunaqosahDetails extends StatefulWidget {
  ModelMhsSidang mhs;
  String table = "t_sidang_munaqosah";

  PageMunaqosahDetails(this.mhs);

  @override
  State<StatefulWidget> createState() {
    return _PageMunaqosahDetailsState(mhs);
  }
}

class _PageMunaqosahDetailsState extends State<PageMunaqosahDetails> {
  ModelMhsSidang mhs;
  TextEditingController _nilaiController;
  RESTAkademik _rest;
  Future _nilai;
  final _myNilaiKey = GlobalKey<FormState>();

  bool _shouldUpdated = false;

  _PageMunaqosahDetailsState(this.mhs);

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop(_shouldUpdated);
    return false;
  }

  @override
  void initState() {
    super.initState();

    _nilaiController = TextEditingController();
    _rest = RESTAkademik();
    _nilai = _rest.getNilai(widget.table, mhs.nim);
  }

  _refresh() {
    setState(() {
      _nilai = _rest.getNilai(widget.table, mhs.nim);
    });
  }

  _setShouldUpdated() {
    setState(() {
      _shouldUpdated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
          appBar: AppBar(
            title: Text("Detail Mahasiswa"),
            elevation: 0.0,
            leading: IconButton(
              icon: Icon(LineIcons.arrow_left),
              onPressed: () => Navigator.of(context).pop(_shouldUpdated),
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(LineIcons.refresh),
                onPressed: () => _refresh(),
              )
            ],
          ),
          body: Builder(
            builder: (myCtx) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ...widgetDosenSidangDetails(context, mhs),
                    Divider(
                      color: Colors.grey,
                    ),
                    FutureBuilder<DosenSidang>(
                      future: _nilai,
                      builder: (BuildContext context,
                          AsyncSnapshot<DosenSidang> snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                            return Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Row(
                                children: <Widget>[
                                  SizedBox(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                    ),
                                    height: 16.0,
                                    width: 16.0,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text("Memuat nilai...",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText1),
                                  )
                                ],
                              ),
                            );
                          default:
                            if (snapshot.hasError) {
                               debugPrint(
                        "PAGE PENILAIAN MUNAQOSAH ERROR!\n==========\n${snapshot.error.toString()}\n=========");
                              return Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text("Gagal memuat nilai.",
                                    style:
                                        Theme.of(context).textTheme.bodyText1),
                              );
                           } else {
                              return Column(
                                children: <Widget>[
                                  WidgetPenilaianDosen(
                                    snapshot: snapshot.data,
                                  ),
                                  SizedBox(height: 20),
                                  SingleChildBooleanWidget(
                                      boolean: snapshot.data.sudahAdaNilai,
                                      ifTrue: MyButton.flatPrimary(
                                          caption: "Ubah penilaian",
                                          buttonWidth: double.infinity,
                                          onTap: () {
                                            tap(
                                                context: context,
                                                message:
                                                    "Anda akan memberi penilaian ${mhs.namaMhs} (NIM: ${mhs.nim})",
                                                onAction: (nilai) =>
                                                    editNilaiDosen(
                                                        table: widget.table,
                                                        scaffoldContext: myCtx,
                                                        restAkademik: _rest,
                                                        mahasiswaSidang: mhs,
                                                        nilai: nilai,
                                                        onRefresh: () async {
                                                          await _refresh();
                                                        },
                                                        onSuccess: () =>
                                                            _setShouldUpdated()));
                                          }),
                                      ifFalse: MyButton.primary(
                                        caption: "Beri penilaian",
                                        buttonWidth: double.infinity,
                                        onTap: () {
                                          tap(
                                              context: context,
                                              message:
                                                  "Anda akan mengubah penilaian ${mhs.namaMhs} (NIM: ${mhs.nim})",
                                              onAction: (nilai) =>
                                                  setNilaiDosen(
                                                      table: widget.table,
                                                      scaffoldContext: myCtx,
                                                      restAkademik: _rest,
                                                      mahasiswaSidang: mhs,
                                                      nilai: nilai,
                                                      onRefresh: () async {
                                                        await _refresh();
                                                      },
                                                      onSuccess: () {
                                                        setState() {
                                                          _shouldUpdated = true;
                                                        }
                                                      }));
                                        },
                                      )),
                                  ButtonRevisi(
                                    table: widget.table,
                                    rest: _rest,
                                    dosen: snapshot.data,
                                    mahasiswa: mhs,
                                    onPageValue: (v) {},
                                  )
                                ],
                              );
                            }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          )),
    );
  }
}

/*
  setNilai(BuildContext ctx, int nilai) {
    _rest.setNilai(mhs.idStatus, nilai).then((String value) async {
      await _refresh();

      Scaffold.of(ctx).showSnackBar(SnackBar(
        content: Text('Sukses menambahkan nilai.'),
        backgroundColor: Colors.green,
      ));

      setState(() {
        _shouldUpdated = true;
      });
    }).catchError((e) async {
      await _refresh();

      Scaffold.of(ctx).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
      ));
    });
  }

  putNilai(BuildContext ctx, int nilai) {
    _rest.putNilai(mhs.idStatus, nilai).then((String value) async {
      await _refresh();

      Scaffold.of(ctx).showSnackBar(SnackBar(
        content: Text('Sukses menyunting nilai.'),
        backgroundColor: Colors.green,
      ));

      setState(() {
        _shouldUpdated = true;
      });
    }).catchError((e) async {
      await _refresh();

      Scaffold.of(ctx).showSnackBar(SnackBar(
        content: Text('Gagal menyunting nilai. Silakan coba kembali.'),
        backgroundColor: Colors.red,
      ));
    });
  }
}
*/

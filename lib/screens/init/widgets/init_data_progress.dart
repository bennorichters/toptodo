import 'package:flutter/material.dart';

import 'package:toptodo/blocs/init/bloc.dart';
import 'package:toptodo/constants/colors.dart' as ttd_colors;
import 'package:toptodo/widgets/td_shape.dart';

class InitDataProgress extends StatelessWidget {
  const InitDataProgress(this.state);
  final InitData state;

  static const _progressDiameter = 25.0;
  static const _padding = 10.0;
  static const _firstColumnWidth = _progressDiameter + 2 * _padding;

  @override
  Widget build(BuildContext context) {
    return TdShapeBackground(
      color: ttd_colors.duckEgg,
      longSide: LongSide.top,
      child: Center(
        child: Table(
          columnWidths: {
            0: const FixedColumnWidth(_firstColumnWidth),
            1: const IntrinsicColumnWidth(),
          },
          children: [
            TableRow(
              children: _rowChildren(
                'credentials',
                state.credentials,
              ),
            ),
            TableRow(
              children: [
                Container(),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: _padding + 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (state.hasCompleteCredentials())
                        ? [
                            Text(state.credentials.url),
                            Text(state.credentials.loginName),
                          ]
                        : [
                            Text('TOPdesk address'),
                            Text('login name'),
                          ],
                  ),
                ),
              ],
            ),
            TableRow(
              children: _rowChildren(
                'settings',
                state.settings,
              ),
            ),
            TableRow(
              children: _rowChildren(
                'your operator profile',
                state.currentOperator,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _rowChildren(String text, Object objectToLoad) {
    return [
      Padding(
        padding: const EdgeInsets.all(_padding),
        child: SizedBox(
          height: _progressDiameter,
          child: objectToLoad == null
              ? const CircularProgressIndicator()
              : const Icon(
                  Icons.done,
                  color: ttd_colors.moss,
                ),
        ),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: _padding),
          child: Text(
            text,
            style: const TextStyle(fontSize: 22),
          ),
        ),
      ),
    ];
  }
}

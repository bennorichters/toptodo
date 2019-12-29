import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toptodo/blocs/init/bloc.dart';
import 'package:toptodo/blocs/login/bloc.dart';
import 'package:toptodo/screens/incident/incident_screen.dart';
import 'package:toptodo/screens/login/login_screen.dart';
import 'package:toptodo/screens/settings/settings_screen.dart';
import 'package:toptodo/utils/colors.dart';
import 'package:toptodo/widgets/error_dialog.dart';

class InitScreen extends StatefulWidget {
  const InitScreen({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<InitBloc>(context)..add(const RequestInitData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to TOPtodo'),
      ),
      body: BlocListener<InitBloc, InitState>(
        listener: (BuildContext context, InitState state) {
          if (state is LoadingDataFailed) {
            showDialog(
              context: context,
              builder: (BuildContext context) => ErrorDialog(
                state.cause,
                onClose: _openLoginScreen,
              ),
            );
          } else if (state is IncompleteCredentials) {
            _openLoginScreen(context);
          } else if ((state is InitData) && state.isComplete()) {
            if (state.settings.isComplete()) {
              _openIncidentScreen(context);
            } else {
              _openSettingsScreen(context);
            }
          }
        },
        child: BlocBuilder<InitBloc, InitState>(
          builder: (BuildContext context, InitState state) {
            if (state is InitData) {
              return _InitDataProgress(state);
            } else {
              return Container();
            }
          },
        ),
      ),
    );
  }
}

class _InitDataProgress extends StatelessWidget {
  const _InitDataProgress(this.state);
  final InitData state;

  static const _progressDiameter = 25.0;
  static const _padding = 10.0;
  static const _firstColumnWidth = _progressDiameter + 2 * _padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Table(
        columnWidths: {
          0: FixedColumnWidth(_firstColumnWidth),
          1: IntrinsicColumnWidth(),
        },
        children: [
          TableRow(
            children: _rowChildren(
              'credentials',
              state.credentials,
            ),
          ),
          TableRow(
            children: _rowChildren(
              'settings',
              state.settings,
            ),
          ),
          TableRow(
            children:
                _rowChildren('your operator profile', state.currentOperator),
          ),
        ],
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
              ? CircularProgressIndicator()
              : Icon(
                  Icons.done,
                  color: moss,
                ),
        ),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: _padding),
          child: Text(
            text,
            style: TextStyle(fontSize: 22),
          ),
        ),
      ),
    ];
  }
}

void _openLoginScreen(BuildContext context) {
  BlocProvider.of<LoginBloc>(context)..add(const CredentialsInit());

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
}

void _openIncidentScreen(BuildContext context) {
  Navigator.of(context).pushReplacement<dynamic, IncidentScreen>(
    MaterialPageRoute<IncidentScreen>(
      builder: (_) => const IncidentScreen(),
    ),
  );
}

void _openSettingsScreen(BuildContext context) {
  Navigator.of(context).pushReplacement<dynamic, SettingsScreen>(
    MaterialPageRoute<SettingsScreen>(
      builder: (_) => const SettingsScreen(),
    ),
  );
}

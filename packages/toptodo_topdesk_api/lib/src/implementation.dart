import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:toptodo_data/toptodo_data.dart';
import 'package:toptodo_topdesk_api/src/version.dart';

typedef _HttpMethod = Future<http.Response> Function(String endPoint);

const _minTdApiVersion = Version(3, 1, 1);

/// A [TopdeskProvider] that makes API calls to a TOPdesk server.
///
/// This object should first be initialized by calling the [init] method. All
/// other methods, except [dispose], will throw a `StateError` otherwise. When
/// this object is no longer needed its [dispose] method should be called to
/// free resources. Once the [init] method has been called it can only be called
/// again after [dispose] has been called.
///
/// See [timeOut] for details on how this object deals with requests to the
/// TOPdesk server that take too long.
///
/// Calls to [currentTdOperator] are cached for a period of time. Via the
/// optional constructor parameter `currentOperatorCacheDuration` the duration
/// of this period can be set.
///
/// When the TOPdesk sever code responds with a success code the methods of this
/// object return the following:
/// * Success code 200: All elements are returned
/// * Success code 201: Only occurs when calling [createTdIncident]. Creating
/// the incident was successful and the new incident number is returned.
/// * Success code 204: An empty list is returned.
/// * Success code 206: A limited number of elements are returned. The rest of
/// the elements can only be requested by calling methods of this object with
/// refined search criterea.
///
/// When the TOPdesk server responds with an error code the following exceptions
/// will be thrown by this object:
/// * Error code 400: [TdBadRequestException]
/// * Error code 401: [TdNotAuthorizedException]
/// * Error code 403: [TdNotAuthorizedException]
/// * Error code 404: [TdModelNotFoundException]
/// * Error code 500: [TdServerException]
///
/// For all other error codes an [ArgumentError] will be thrown by methods of
/// this object.
class ApiTopdeskProvider extends TopdeskProvider {
  /// Creates a new [ApiTopdeskProvider].
  ///
  /// The [timeOut] can be set with an optional parameter. The default value is
  /// a `Duration` of 30 seconds.
  ///
  /// The [currentOperatorCacheDuration] can be set with an optional parameter.
  /// The default value is a `Duration` of 1 hour.
  ApiTopdeskProvider({
    this.timeOut = const Duration(seconds: 30),
    currentOperatorCacheDuration = const Duration(hours: 1),
  }) : _currentOperatorCache = AsyncCache<TdOperator>(
          currentOperatorCacheDuration,
        );

  /// Time out when making calls to the TOPdesk server.
  ///
  /// When the time out is exceeded a [TdTimeOutException] will be thrown by the
  /// methods of this object.
  final Duration timeOut;

  final AsyncCache<TdOperator> _currentOperatorCache;

  static final _acceptHeaders = {
    HttpHeaders.acceptHeader: 'application/json',
  };

  static final _contentHeaders = {
    HttpHeaders.contentTypeHeader: 'application/json',
  };

  String _url;
  Map<String, String> _getHeaders;
  Map<String, String> _postHeaders;
  http.Client _client;

  static const String _subPathOperator = 'operator';
  static const String _subPathCaller = 'person';

  @override
  Future<void> init(Credentials credentials, {http.Client client}) async {
    if (_url != null) {
      throw StateError('init has already been called');
    }

    _url = credentials.url;
    _client = client ?? http.Client();
    await _testUrl();

    _getHeaders = {}
      ..addAll(_createAuthHeaders(credentials))
      ..addAll(_acceptHeaders);

    _postHeaders = {}..addAll(_getHeaders)..addAll(_contentHeaders);

    await _testVersion();
  }

  void _testUrl() async {
    try {
      await _apiCall(_url, _client.head);
    } catch (error) {
      throw TdCannotConnect('cannot connect to $_url, error: $error');
    }
  }

  Future<void> _testVersion() async {
    var versionText;
    try {
      versionText = await apiVersion();
    } on TdNotFoundException catch (error) {
      throw TdVersionNotSupported(
        'unsupported version of TOPdesk API '
        'required: "$_minTdApiVersion" or higher. '
        'error: $error',
      );
    }

    try {
      final version = Version.fromString(versionText);
      if (version < _minTdApiVersion) {
        throw TdVersionNotSupported(
          'version of this TOPdesk is not supported. '
          'API version is: "$versionText", '
          'required: "$_minTdApiVersion" or higher',
        );
      }
    } catch (error) {
      throw TdVersionNotSupported(
        'unexpected version of TOPdesk API '
        'version is: $versionText, '
        'error: $error',
      );
    }
  }

  @override
  void dispose() {
    _client?.close();

    _url = null;
    _getHeaders = null;
    _client = null;
    _currentOperatorCache.invalidate();
  }

  @override
  Future<String> apiVersion() async {
    final dynamic response = await _apiGet('version');
    return response['version'];
  }

  @override
  Future<TdBranch> tdBranch({String id}) async {
    final dynamic response = await _apiGet('branches/id/$id');
    return TdBranch.fromJson(response);
  }

  @override
  Future<Iterable<TdBranch>> tdBranches({@required String startsWith}) async {
    final sanitized = _sanatizeUserInput(startsWith);
    final List<dynamic> response =
        await _apiGet('branches?nameFragment=$sanitized&\$fields=id,name');

    return response.map((dynamic e) => TdBranch.fromJson(e));
  }

  @override
  Future<TdCaller> tdCaller({String id}) async {
    final dynamic response =
        await _apiGet('persons/id/$id?\$fields=id,dynamicName,branch');

    return _fixCaller(response);
  }

  @override
  Future<Iterable<TdCaller>> tdCallers({
    @required String startsWith,
    @required TdBranch tdBranch,
  }) async {
    final sanitized = _sanatizeUserInput(startsWith);

    final List<dynamic> response = await _apiGet(
      'persons?'
      'query='
      'archived==false;'
      'branch.id==${tdBranch.id};'
      'dynamicName=sw=$sanitized&'
      '\$fields=id,dynamicName,branch',
    );

    final fixed = await Future.wait<TdCaller>(
      response.map(
        (dynamic json) async => await _fixCaller(json),
      ),
    );

    return fixed;
  }

  Future<TdCaller> _fixCaller(Map<String, dynamic> json) async {
    final dynamic fixed = await _fixPerson(_subPathCaller, json);
    final branch = TdBranch(
      id: json['branch']['id'],
      name: json['branch']['name'],
    );

    return TdCaller(
      id: fixed['id'],
      name: fixed['name'],
      avatar: fixed['avatar'],
      branch: branch,
    );
  }

  @override
  Future<TdCategory> tdCategory({String id}) async =>
      (await tdCategories()).firstWhere(
        (TdCategory c) => c.id == id,
        orElse: () => throw TdNotFoundException('no category for id: $id'),
      );

  @override
  Future<Iterable<TdCategory>> tdCategories() async {
    final List<dynamic> response = await _apiGet('incidents/categories');
    return response.map((dynamic e) => TdCategory.fromJson(e));
  }

  @override
  Future<TdSubcategory> tdSubcategory({String id}) async {
    final List<dynamic> response = await _apiGet('incidents/subcategories');
    final dynamic theOne = response.firstWhere(
      (dynamic json) => json['id'] == id,
      orElse: () => throw TdNotFoundException(
        'no sub category for id: $id',
      ),
    );

    return TdSubcategory.fromJson(theOne);
  }

  @override
  Future<Iterable<TdSubcategory>> tdSubcategories({
    TdCategory tdCategory,
  }) async {
    final List<dynamic> response = await _apiGet('incidents/subcategories');

    return response
        .where((dynamic json) => json['category']['id'] == tdCategory.id)
        .map((dynamic json) => TdSubcategory.fromJson(json));
  }

  @override
  Future<TdDuration> tdDuration({String id}) async {
    return (await tdDurations()).firstWhere(
      (TdDuration e) => e.id == id,
      orElse: () => throw TdNotFoundException(
        'no incident duration for id: $id',
      ),
    );
  }

  @override
  Future<Iterable<TdDuration>> tdDurations() async {
    final List<dynamic> response = await _apiGet('incidents/durations');
    return response.map((dynamic e) => TdDuration.fromJson(e));
  }

  @override
  Future<TdOperator> tdOperator({String id}) async {
    final dynamic response = await _apiGet('operators/id/$id');
    final dynamic fixed = await _fixPerson(_subPathOperator, response);

    return TdOperator.fromJson(fixed);
  }

  @override
  Future<TdOperator> currentTdOperator() async {
    return _currentOperatorCache.fetch(() async {
      final dynamic response = await _apiGet('operators/current');
      final dynamic fixed = await _fixPerson(_subPathOperator, response);

      return TdOperator.fromJson(fixed);
    });
  }

  @override
  Future<Iterable<TdOperator>> tdOperators({
    @required String startsWith,
  }) async {
    final sanitized = _sanatizeUserInput(startsWith);
    final List<dynamic> response = await _apiGet(
      'operators?lastname=$sanitized',
    );

    final filtered = response.where(
      (dynamic json) => json['firstLineCallOperator'],
    );

    final fixed = await Future.wait<dynamic>(
      filtered.map(
        (dynamic json) => _fixPerson(_subPathOperator, json),
      ),
    );

    return fixed.map((dynamic json) => TdOperator.fromJson(json));
  }

  /// Creates a new incident in TOPdesk and returns the new incident number.
  ///
  /// New lines `\n` are replaced by `<br>` tags to preserve new lines.
  @override
  Future<String> createTdIncident({
    @required String briefDescription,
    @required Settings settings,
    String request,
  }) async {
    final body = {
      'status': 'firstLine',
      'callerBranch': {'id': settings.tdBranchId},
      'caller': {'id': settings.tdCallerId},
      'category': {'id': settings.tdCategoryId},
      'subcategory': {'id': settings.tdSubcategoryId},
      'duration': {'id': settings.tdDurationId},
      'operator': {'id': settings.tdOperatorId},
      'briefDescription': briefDescription,
    };

    if (request != null && request.isNotEmpty) {
      body['request'] = _replaceNewLineWithBr(request);
    }

    final responseJson = json.encode(body);

    final response = await _apiPost('incidents', responseJson);
    return response['number'];
  }

  dynamic _apiGet(String endPoint) async => _apiCall(
        endPoint,
        (String endPoint) => _client.get(
          '$_url/tas/api/$endPoint',
          headers: _getHeaders,
        ),
      );

  dynamic _apiPost(String endPoint, String body) async => _apiCall(
        endPoint,
        (String endPoint) => _client.post(
          '$_url/tas/api/$endPoint',
          headers: _postHeaders,
          body: body,
        ),
      );

  dynamic _apiCall(String endPoint, _HttpMethod method) async {
    if (_url == null) {
      throw StateError('call init first');
    }

    http.Response res;
    try {
      res = await method(endPoint).timeout(
        timeOut,
        onTimeout: () => throw TdTimeOutException(
          'time out for: $method',
        ),
      );
    } on TdTimeOutException {
      rethrow;
    } on SocketException catch (error) {
      throw TdCannotConnect('error get $method error: $error');
    } catch (error) {
      throw TdServerException('error get $method error: $error');
    }

    return _processServerResponse(endPoint, res);
  }

  dynamic _processServerResponse(String endPoint, http.Response res) {
    if (res.statusCode == 200 ||
        res.statusCode == 201 ||
        res.statusCode == 206) {
      return json.decode(res.body.isEmpty ? '[]' : res.body);
    }

    if (res.statusCode == 204) {
      return json.decode('[]');
    }

    if (res.statusCode == 400) {
      throw TdBadRequestException('400 for $endPoint body: ${res.body}');
    }

    if (res.statusCode == 401) {
      throw TdNotAuthorizedException('401 for $endPoint body: ${res.body}');
    }

    if (res.statusCode == 403) {
      throw TdNotAuthorizedException('403 for $endPoint body: ${res.body}');
    }

    if (res.statusCode == 404) {
      throw TdNotFoundException('404 for $endPoint body: ${res.body}');
    }

    if (res.statusCode == 500) {
      throw TdServerException('500 for $endPoint body: ${res.body}');
    }

    throw ArgumentError('endpoint: $endPoint '
        'response status code: ${res.statusCode} '
        'response body: ${res.body}');
  }

  Future<dynamic> _fixPerson(String subPath, dynamic json) async {
    json['name'] = json['dynamicName'];
    json['avatar'] = await _avatarForPerson(subPath, json['id']);
    return json;
  }

  Future<String> _avatarForPerson(String subPath, String id) async {
    final dynamic response = await _apiGet('avatars/$subPath/$id');
    return response['image'];
  }

  String _sanatizeUserInput(String input) => Uri.encodeComponent(input);

  String _replaceNewLineWithBr(String input) => input.replaceAll('\n', '<br>');

  Map<String, String> _createAuthHeaders(Credentials credentials) {
    final encoded = utf8
        .fuse(base64)
        .encode('${credentials.loginName}:${credentials.password}');

    return {
      HttpHeaders.authorizationHeader: 'Basic ' + encoded,
    };
  }
}

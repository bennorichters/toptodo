import 'package:equatable/equatable.dart';

/// A 'pojo' for the settings of a user.
/// 
/// A container for several elements that are used to create an incident. Each
/// element contains a foreign key that refers to a [TdModel]. 
/// 
/// Instances of this class are considered equal if and only if all matching 
/// fields of both instances are equal. All fields can be null. Instances of 
/// this class are immutable. 
class Settings extends Equatable {
  /// Creates an instance of `Settings`
  const Settings({
    this.branchId,
    this.callerId,
    this.categoryId,
    this.subCategoryId,
    this.incidentDurationId,
    this.incidentOperatorId,
  });

  /// Converts a json object into an instance of `Settings`
  Settings.fromJson(Map<String, dynamic> json)
      : branchId = json['branchId'],
        callerId = json['callerId'],
        categoryId = json['categoryId'],
        subCategoryId = json['subCategoryId'],
        incidentDurationId = json['incidentDurationId'],
        incidentOperatorId = json['incidentOperatorId'];

  /// foreign key to a [Branch]
  final String branchId;
  /// foreign key to a [Caller]
  final String callerId;
  final String categoryId;
  final String subCategoryId;
  final String incidentDurationId;
  final String incidentOperatorId;

  bool isComplete() => !props.contains(null);

  Map<String, dynamic> toJson() => {
        'branchId': branchId,
        'callerId': callerId,
        'categoryId': categoryId,
        'subCategoryId': subCategoryId,
        'incidentDurationId': incidentDurationId,
        'incidentOperatorId': incidentOperatorId,
      };

  @override
  List<Object> get props => [
        branchId,
        callerId,
        categoryId,
        subCategoryId,
        incidentDurationId,
        incidentOperatorId,
      ];

  @override
  String toString() => 'Settings [${toJson().toString()}]';
}

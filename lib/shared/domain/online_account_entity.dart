import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

const int _unsetId = -1;

/*
  0    Id                 INT             0                    1
  1    Name               nvarchar(80)    1                    0
  2    Institution        nvarchar(80)    0                    0
  3    OFX                nvarchar(255)   0                    0
  4    OfxVersion         nchar(10)       0                    0
  5    FID                nvarchar(50)    0                    0
  6    UserId             nchar(20)       0                    0
  7    Password           nvarchar(50)    0                    0
  8    UserCred1          nvarchar(200)   0                    0
  9    UserCred2          nvarchar(200)   0                    0
  10   AuthToken          nvarchar(200)   0                    0
  11   BankId             nvarchar(50)    0                    0
  12   BranchId           nvarchar(50)    0                    0
  13   BrokerId           nvarchar(50)    0                    0
  14   LogoUrl            nvarchar(1000)  0                    0
  15   AppId              nchar(10)       0                    0
  16   AppVersion         nchar(10)       0                    0
  17   ClientUid          nchar(36)       0                    0
  18   AccessKey          nchar(36)       0                    0
  19   UserKey            nvarchar(64)    0                    0
  20   UserKeyExpireDate  datetime        0                    0
 */

/// Represents online account.
class OnlineAccount extends DataObject {
  OnlineAccount({
    required String name,
    required this.institution,
    required this.ofx,
    required this.ofxVersion,
    required this.fdic,
    required this.userId,
    required this.password,
    required this.userCred1,
    required this.userCred2,
    required this.authToken,
    required this.bankId,
    required this.branchId,
  }) {
    this.fieldName.value = name;
  }

  /// Constructor from a SQLite row
  factory OnlineAccount.fromJson(final MyJson row) {
    return OnlineAccount(
      // 1
      name: row.getString(SharedDomainStrings.domainString088),
      // 2
      institution: row.getString(SharedDomainStrings.domainString058),
      // 3
      ofx: row.getString(SharedDomainStrings.domainString094),
      // 4
      ofxVersion: row.getString(SharedDomainStrings.domainString096),
      // 5
      fdic: row.getString(SharedDomainStrings.domainString052),
      // 6
      userId: row.getString(SharedDomainStrings.domainString151),
      // 7
      password: row.getString(SharedDomainStrings.domainString103),
      // 8
      userCred1: row.getString('UserCred1'),
      // 9
      userCred2: row.getString('UserCred2'),
      // 10
      authToken: row.getString(SharedDomainStrings.domainString018),
      // 11
      bankId: row.getString(SharedDomainStrings.domainString020),
      // 12
      branchId: row.getString(SharedDomainStrings.domainString023),
    )..fieldId.value = row.getInt(SharedDomainStrings.domainString057, _unsetId);
  }

  // 10
  final String authToken;

  // 11
  final String bankId;

  // 12
  final String branchId;

  // 5
  final String fdic;

  // 0
  FieldId fieldId = FieldId(
    getValueForSerialization: (final DataInterface instance) => (instance as OnlineAccount).uniqueId,
  );

  // 1
  FieldString fieldName = FieldString(
    serializeName: SharedDomainStrings.domainString088,
    getValueForSerialization: (final DataInterface instance) => (instance as OnlineAccount).fieldName.value,
  );

  // 2
  final String institution;

  // 3
  final String ofx;

  // 4
  final String ofxVersion;

  // 7
  final String password;

  // 8
  final String userCred1;

  // 9
  final String userCred2;

  // 6
  final String userId;

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  static final Fields<OnlineAccount> _fields = Fields<OnlineAccount>();

  /// Returns the field definitions for OnlineAccount entities.
  static Fields<OnlineAccount> get fields {
    if (_fields.isEmpty) {
      final OnlineAccount tmp = OnlineAccount.fromJson(<String, dynamic>{});
      _fields.setDefinitions(<Field<dynamic>>[tmp.fieldId, tmp.fieldName]);
    }

    return _fields;
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;
}

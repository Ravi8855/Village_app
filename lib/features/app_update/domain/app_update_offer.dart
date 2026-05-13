import 'package:equatable/equatable.dart';

import 'app_update_type.dart';

/// Domain model describing an available Play Store update.
class AppUpdateOffer extends Equatable {
  const AppUpdateOffer({
    required this.currentVersionName,
    required this.currentVersionCode,
    required this.availableVersionCode,
    required this.releaseNotes,
    required this.flexibleAllowed,
    required this.immediateAllowed,
    required this.recommendedType,
    this.updatePriority = 0,
    this.clientVersionStalenessDays,
  });

  final String currentVersionName;
  final int currentVersionCode;
  final int availableVersionCode;
  final String releaseNotes;
  final bool flexibleAllowed;
  final bool immediateAllowed;
  final AppUpdateType recommendedType;
  final int updatePriority;
  final int? clientVersionStalenessDays;

  bool get hasNewerVersion => availableVersionCode > currentVersionCode;

  @override
  List<Object?> get props => [
        currentVersionName,
        currentVersionCode,
        availableVersionCode,
        releaseNotes,
        flexibleAllowed,
        immediateAllowed,
        recommendedType,
        updatePriority,
        clientVersionStalenessDays,
      ];
}

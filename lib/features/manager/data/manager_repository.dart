import 'package:beacon_app/features/manager/domain/managed_facility.dart';

/// Where the facility-manager screens get their data.
///
/// The manager feature needs tables and server-side rules that don't exist
/// yet (who manages what; feedback released only past the threshold). Until
/// they do, the app is given [NoManagerBackend], and the feature stays out of
/// sight: nobody has a facility, so nobody is shown the way in.
abstract class ManagerRepository {
  /// The signed-in person's facilities, in every status. Empty for a guest
  /// and for anyone who has never asked to manage one.
  Future<List<ManagedFacility>> myFacilities();

  /// Asks to manage [facilityId]. Always starts as pending; the Beacon team
  /// verifies by hand.
  Future<void> requestAccess(String facilityId);
}

/// The repository used while there is no backend for the feature.
class NoManagerBackend implements ManagerRepository {
  const NoManagerBackend();

  @override
  Future<List<ManagedFacility>> myFacilities() async => const [];

  @override
  Future<void> requestAccess(String facilityId) =>
      Future.error(UnsupportedError('Facility management is not available'));
}

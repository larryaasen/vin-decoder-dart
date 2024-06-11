/// A vehicle object with data from the NHTSA.
class NHTSAVehicle {
  /// Creates a vehicle object with data from the NHTSA.
  const NHTSAVehicle(
      {this.make, this.model, this.year, this.VIN, this.vehicleType});

  final String? make;
  final String? model;
  final String? year;
  final String? VIN;
  final String? vehicleType;

  static NHTSAVehicle? fromMap(Map<String, dynamic>? map) {
    final make = map?['Make'] as String?;
    final model = map?['Model'] as String?;

    NHTSAVehicle? vehicle;
    if (make != null || model != null) {
      vehicle = NHTSAVehicle(
        make: make,
        model: model,
        year: map?['ModelYear'] as String?,
        VIN: map?['VIN'] as String?,
        vehicleType: map?['VehicleType'] as String?,
      );
    }
    return vehicle;
  }
}

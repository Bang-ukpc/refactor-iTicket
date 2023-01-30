class VehicleRegistration {
  String? Colour;
  String? Model;
  String? Vrm;
  String? Make;

  VehicleRegistration({
    this.Colour,
    this.Make,
    this.Model,
    this.Vrm,
  });

  VehicleRegistration.fromJson(Map<String, dynamic> json) {
    Colour = json['Colour'];
    Make = json['Make'];
    Model = json['Model'];
    Vrm = json['Vrm'];
  }
}

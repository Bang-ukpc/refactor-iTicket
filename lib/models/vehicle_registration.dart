class VehicleRegistration {
  String? dateOfLastUpdate;
  String? colour;
  String? vehicleClass;
  bool? certificateOfDestructionIssued;
  String? engineNumber;
  String? engineCapacity;
  String? transmissionCode;
  bool? exported;
  String? yearOfManufacture;
  String? wheelPlan;
  Null? dateExported;
  bool? scrapped;
  String? transmission;
  String? dateFirstRegisteredUk;
  String? model;
  int? gearCount;
  bool? importNonEu;
  Null? previousVrmGb;
  int? grossWeight;
  String? doorPlanLiteral;
  String? mvrisModelCode;
  String? vin;
  String? vrm;
  String? dateFirstRegistered;
  Null? dateScrapped;
  String? doorPlan;
  String? yearMonthFirstRegistered;
  String? vinLast5;
  bool? vehicleUsedBeforeFirstRegistration;
  int? maxPermissibleMass;
  String? make;
  String? makeModel;
  String? transmissionType;
  int? seatingCapacity;
  String? fuelType;
  int? co2Emissions;
  bool? imported;
  String? mvrisMakeCode;
  Null? previousVrmNi;
  Null? vinConfirmationFlag;

  VehicleRegistration({
    this.dateOfLastUpdate,
    this.colour,
    this.vehicleClass,
    this.certificateOfDestructionIssued,
    this.engineNumber,
    this.engineCapacity,
    this.transmissionCode,
    this.exported,
    this.yearOfManufacture,
    this.wheelPlan,
    this.dateExported,
    this.scrapped,
    this.transmission,
    this.dateFirstRegisteredUk,
    this.model,
    this.gearCount,
    this.importNonEu,
    this.previousVrmGb,
    this.grossWeight,
    this.doorPlanLiteral,
    this.mvrisModelCode,
    this.vin,
    this.vrm,
    this.dateFirstRegistered,
    this.dateScrapped,
    this.doorPlan,
    this.yearMonthFirstRegistered,
    this.vinLast5,
    this.vehicleUsedBeforeFirstRegistration,
    this.maxPermissibleMass,
    this.make,
    this.makeModel,
    this.transmissionType,
    this.seatingCapacity,
    this.fuelType,
    this.co2Emissions,
    this.imported,
    this.mvrisMakeCode,
    this.previousVrmNi,
    this.vinConfirmationFlag,
  });

  VehicleRegistration.fromJson(Map<String, dynamic> json) {
    dateOfLastUpdate = json['DateOfLastUpdate'];
    colour = json['Colour'];
    vehicleClass = json['VehicleClass'];
    certificateOfDestructionIssued = json['CertificateOfDestructionIssued'];
    engineNumber = json['EngineNumber'];
    engineCapacity = json['EngineCapacity'];
    transmissionCode = json['TransmissionCode'];
    exported = json['Exported'];
    yearOfManufacture = json['YearOfManufacture'];
    wheelPlan = json['WheelPlan'];
    dateExported = json['DateExported'];
    scrapped = json['Scrapped'];
    transmission = json['Transmission'];
    dateFirstRegisteredUk = json['DateFirstRegisteredUk'];
    model = json['Model'];
    gearCount = json['GearCount'];
    importNonEu = json['ImportNonEu'];
    previousVrmGb = json['PreviousVrmGb'];
    grossWeight = json['GrossWeight'];
    doorPlanLiteral = json['DoorPlanLiteral'];
    mvrisModelCode = json['MvrisModelCode'];
    vin = json['Vin'];
    vrm = json['Vrm'];
    dateFirstRegistered = json['DateFirstRegistered'];
    dateScrapped = json['DateScrapped'];
    doorPlan = json['DoorPlan'];
    yearMonthFirstRegistered = json['YearMonthFirstRegistered'];
    vinLast5 = json['VinLast5'];
    vehicleUsedBeforeFirstRegistration =
        json['VehicleUsedBeforeFirstRegistration'];
    maxPermissibleMass = json['MaxPermissibleMass'];
    make = json['Make'];
    makeModel = json['MakeModel'];
    transmissionType = json['TransmissionType'];
    seatingCapacity = json['SeatingCapacity'];
    fuelType = json['FuelType'];
    co2Emissions = json['Co2Emissions'];
    imported = json['Imported'];
    mvrisMakeCode = json['MvrisMakeCode'];
    previousVrmNi = json['PreviousVrmNi'];
    vinConfirmationFlag = json['VinConfirmationFlag'];
  }
}

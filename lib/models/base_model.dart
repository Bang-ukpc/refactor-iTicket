
class Identifiable{
  int? Id;
}

class BaseModel extends Identifiable{
  int? Id;
  DateTime? Created;
  DateTime? Deleted;
  int? CreatedBy;

  BaseModel({
    this.Id,
    this.Created,
    this.Deleted,
    this.CreatedBy,
  });

  factory BaseModel.fromJson(Map<String, dynamic> json) => BaseModel();
}

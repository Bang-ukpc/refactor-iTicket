class BaseModel {
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
}

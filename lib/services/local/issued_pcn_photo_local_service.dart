import 'package:iWarden/models/ContraventionService.dart';
import 'package:iWarden/services/local/local_service.dart';
import '../../controllers/contravention_controller.dart';

class IssuedPcnPhotoLocalService
    extends BaseLocalService<ContraventionCreatePhoto> {
  final String LOCAL_KEY = 'contraventionPhotoDataLocal';

  IssuedPcnPhotoLocalService() : super('contraventionPhotoDataLocal');

  @override
  syncAll() async {
    List<ContraventionCreatePhoto> allPcnPhotos = await getAll();

    for (var pcnPhoto in allPcnPhotos) {
      await sync(pcnPhoto);
    }
  }

  @override
  sync(ContraventionCreatePhoto pcnPhoto) async {
    await contraventionController.uploadContraventionImage(pcnPhoto);
    await delete(pcnPhoto.Id!);
  }
}

final issuedPcnPhotoLocalService = IssuedPcnPhotoLocalService();

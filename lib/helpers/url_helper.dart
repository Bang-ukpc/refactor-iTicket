import '../configs/configs.dart';

class UrlHelper {
  isHttpUrl(String url) {
    return url.contains('http');
  }

  isLocalUrl(String url) {
    return url.contains('com.example.iWarden');
  }

  String toImageUrl(String blobName) {
    return "${ConfigEnvironmentVariable.azureContainerImageUrl}/$blobName";
  }
}

final urlHelper = UrlHelper();

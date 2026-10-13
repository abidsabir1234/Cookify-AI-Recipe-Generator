class ImageLabeler {
  final dynamic options;
  ImageLabeler({required this.options});
  Future<List<ImageLabel>> processImage(dynamic image) async => [];
  void close() {}
}

class ImageLabel {
  final String label;
  final double confidence;
  ImageLabel({required this.label, required this.confidence});
}

class ImageLabelerOptions {
  final double confidenceThreshold;
  ImageLabelerOptions({required this.confidenceThreshold});
}

class InputImage {
  static InputImage fromFilePath(String path) => InputImage._();
  InputImage._();
}

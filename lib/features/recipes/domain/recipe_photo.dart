/// The catalog owns photo locations and dimensions, not the app binary.
class RecipePhoto {
  const RecipePhoto(this.path, this.width, this.height);
  final String path;
  final int width;
  final int height;
  double get aspectRatio => width / height;
  bool get isRemote => Uri.tryParse(path)?.scheme == 'https';
  Map<String, Object> toJson() => {
    'path': path,
    'width': width,
    'height': height,
  };
}

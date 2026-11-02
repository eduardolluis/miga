/// The catalog owns photo locations and dimensions, not the app binary.
class RecipePhoto {
  const RecipePhoto(
    this.path,
    this.width,
    this.height, {
    this.thumbnailPath,
    this.thumbnailWidth,
    this.thumbnailHeight,
  });
  final String path;
  final int width;
  final int height;
  final String? thumbnailPath;
  final int? thumbnailWidth;
  final int? thumbnailHeight;
  String get cardPath => thumbnailPath ?? path;
  int get cardWidth => thumbnailWidth ?? width;
  int get cardHeight => thumbnailHeight ?? height;
  double get aspectRatio => width / height;
  bool get isRemote => Uri.tryParse(path)?.scheme == 'https';
  Map<String, Object> toJson() => {
    'path': path,
    'width': width,
    'height': height,
    'thumbnail_path': ?thumbnailPath,
    'thumbnail_width': ?thumbnailWidth,
    'thumbnail_height': ?thumbnailHeight,
  };
}

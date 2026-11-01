// Individual recipe photos and their verified native dimensions.
class RecipePhoto {
  const RecipePhoto(this.asset, this.width, this.height);
  final String asset;
  final int width, height;
  double get aspectRatio => width / height;
}

abstract final class RecipePhotoCatalog {
  static const images = <int, RecipePhoto>{
    0: RecipePhoto('assets/images/recipes/v2/banana-oats.jpg', 1448, 1086),
    1: RecipePhoto('assets/images/recipes/v2/avocado-toast.jpg', 1448, 1086),
    2: RecipePhoto('assets/images/recipes/v2/yogurt-fruit.jpg', 1448, 1086),
    3: RecipePhoto('assets/images/recipes/v2/lemon-salmon.jpg', 1448, 1086),
    4: RecipePhoto('assets/images/recipes/v2/chicken-rice.jpg', 1448, 1086),
    5: RecipePhoto('assets/images/recipes/v2/chickpea-salad.jpg', 1448, 1086),
    6: RecipePhoto('assets/images/recipes/v2/tomato-pasta.jpg', 1448, 1086),
    7: RecipePhoto('assets/images/recipes/v2/sweet-potato-egg.jpg', 1448, 1086),
    8: RecipePhoto('assets/images/recipes/v2/lentil-soup.jpg', 1448, 1086),
    9: RecipePhoto(
      'assets/images/recipes/v2/apple-cinnamon-oats.jpg',
      1448,
      1086,
    ),
    10: RecipePhoto(
      'assets/images/recipes/v2/peanut-banana-toast.jpg',
      1448,
      1086,
    ),
    11: RecipePhoto(
      'assets/images/recipes/v2/spinach-cheese-omelet.jpg',
      1448,
      1086,
    ),
    12: RecipePhoto(
      'assets/images/recipes/v2/mango-oat-smoothie.jpg',
      1448,
      1086,
    ),
    13: RecipePhoto(
      'assets/images/recipes/v2/apple-yogurt-bowl.jpg',
      1448,
      1086,
    ),
    14: RecipePhoto(
      'assets/images/recipes/v2/breakfast-potato-hash.jpg',
      1448,
      1086,
    ),
    15: RecipePhoto('assets/images/recipes/v2/egg-tomato-wrap.jpg', 1448, 1086),
    16: RecipePhoto(
      'assets/images/recipes/v2/strawberry-oat-pancakes.jpg',
      1448,
      1086,
    ),
    17: RecipePhoto(
      'assets/images/recipes/v2/savory-chickpea-toast.jpg',
      1448,
      1086,
    ),
    18: RecipePhoto(
      'assets/images/recipes/v2/zucchini-egg-scramble.jpg',
      1448,
      1086,
    ),
    19: RecipePhoto(
      'assets/images/recipes/v2/pineapple-granola-yogurt.jpg',
      1448,
      1086,
    ),
    20: RecipePhoto(
      'assets/images/recipes/v2/sweet-potato-yogurt-bowl.jpg',
      1448,
      1086,
    ),
    21: RecipePhoto(
      'assets/images/recipes/v2/black-bean-breakfast-tacos.jpg',
      1448,
      1086,
    ),
    22: RecipePhoto(
      'assets/images/recipes/v2/avocado-spinach-sandwich.jpg',
      1448,
      1086,
    ),
    23: RecipePhoto(
      'assets/images/recipes/v2/mushroom-egg-toast.jpg',
      1448,
      1086,
    ),
    24: RecipePhoto(
      'assets/images/recipes/v2/beef-pepper-rice.jpg',
      1448,
      1086,
    ),
    25: RecipePhoto(
      'assets/images/recipes/v2/tuna-chickpea-salad.jpg',
      1448,
      1086,
    ),
    26: RecipePhoto(
      'assets/images/recipes/v2/chicken-avocado-wrap.jpg',
      1448,
      1086,
    ),
    27: RecipePhoto(
      'assets/images/recipes/v2/quinoa-veggie-bowl.jpg',
      1448,
      1086,
    ),
    28: RecipePhoto(
      'assets/images/recipes/v2/black-beans-rice.jpg',
      1448,
      1086,
    ),
    29: RecipePhoto(
      'assets/images/recipes/v2/lentil-bolognese.jpg',
      1448,
      1086,
    ),
    30: RecipePhoto(
      'assets/images/recipes/v2/salmon-rice-bowl.jpg',
      1448,
      1086,
    ),
    31: RecipePhoto(
      'assets/images/recipes/v2/tofu-broccoli-stirfry.jpg',
      1448,
      1086,
    ),
    32: RecipePhoto(
      'assets/images/recipes/v2/beef-potato-skillet.jpg',
      1448,
      1086,
    ),
    33: RecipePhoto(
      'assets/images/recipes/v2/chicken-pasta-salad.jpg',
      1448,
      1086,
    ),
    34: RecipePhoto(
      'assets/images/recipes/v2/mediterranean-chickpeas.jpg',
      1448,
      1086,
    ),
    35: RecipePhoto(
      'assets/images/recipes/v2/tuna-potato-salad.jpg',
      1448,
      1086,
    ),
    36: RecipePhoto(
      'assets/images/recipes/v2/stuffed-peppers-beans.jpg',
      1448,
      1086,
    ),
    37: RecipePhoto(
      'assets/images/recipes/v2/zucchini-chicken-skillet.jpg',
      1448,
      1086,
    ),
    38: RecipePhoto(
      'assets/images/recipes/v2/lentil-quinoa-salad.jpg',
      1448,
      1086,
    ),
    39: RecipePhoto(
      'assets/images/recipes/v2/mushroom-spinach-pasta.jpg',
      1448,
      1086,
    ),
    40: RecipePhoto(
      'assets/images/recipes/v2/chicken-vegetable-soup.jpg',
      1448,
      1086,
    ),
    41: RecipePhoto(
      'assets/images/recipes/v2/vegetable-quesadillas.jpg',
      1448,
      1086,
    ),
    42: RecipePhoto(
      'assets/images/recipes/v2/black-bean-tacos.jpg',
      1448,
      1086,
    ),
    43: RecipePhoto(
      'assets/images/recipes/v2/salmon-sweet-potato.jpg',
      1448,
      1086,
    ),
    44: RecipePhoto(
      'assets/images/recipes/v2/tomato-egg-skillet.jpg',
      1448,
      1086,
    ),
    45: RecipePhoto(
      'assets/images/recipes/v2/creamy-sweet-potato-soup.jpg',
      1448,
      1086,
    ),
    46: RecipePhoto(
      'assets/images/recipes/v2/tofu-broccoli-rice.jpg',
      1448,
      1086,
    ),
    47: RecipePhoto(
      'assets/images/recipes/v2/quinoa-stuffed-zucchini.jpg',
      1448,
      1086,
    ),
    48: RecipePhoto(
      'assets/images/recipes/v2/beef-tomato-pasta.jpg',
      1448,
      1086,
    ),
    49: RecipePhoto(
      'assets/images/recipes/v2/lentil-tomato-stew.jpg',
      1448,
      1086,
    ),
    50: RecipePhoto(
      'assets/images/recipes/v2/chicken-potato-tray.jpg',
      1448,
      1086,
    ),
    51: RecipePhoto(
      'assets/images/recipes/v2/chickpea-spinach-stew.jpg',
      1448,
      1086,
    ),
    52: RecipePhoto(
      'assets/images/recipes/v2/tuna-tomato-pasta.jpg',
      1448,
      1086,
    ),
    53: RecipePhoto(
      'assets/images/recipes/v2/roasted-vegetable-quinoa.jpg',
      1448,
      1086,
    ),
  };
}

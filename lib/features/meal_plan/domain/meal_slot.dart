enum MealSlot {
  breakfast,
  lunch,
  dinner;

  static MealSlot forTime(DateTime time) => switch (time.hour) {
    >= 5 && < 11 => breakfast,
    >= 11 && < 17 => lunch,
    _ => dinner,
  };

  // This name and date format are part of the saved-plan schema.
  String keyFor(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month-$day:$name';
  }
}

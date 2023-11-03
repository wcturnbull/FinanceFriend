import 'dart:ui';

Color getColorFromHex(String hex) {
  return Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF0000000);
}

final greenColorList = <Color>[
  getColorFromHex("#124309"),
  getColorFromHex("#15510a"),
  getColorFromHex("#1c6c0e"),
  getColorFromHex("#248712"),
  getColorFromHex("#4f9f41"),
  getColorFromHex("#7bb770"),
  getColorFromHex("#a7cfa0"),
  getColorFromHex("#d3e7cf"),
];

final customColorList = <Color>[
  getColorFromHex("#FFFFFF"),
  getColorFromHex("#FFFFFF"),
  getColorFromHex("#FFFFFF"),
  getColorFromHex("#FFFFFF"),
  getColorFromHex("#FFFFFF"),
  getColorFromHex("#FFFFFF"),
  getColorFromHex("#FFFFFF"),
  getColorFromHex("#FFFFFF"),
];

final blueColorList = <Color>[
  getColorFromHex("#0099FF"),
  getColorFromHex("#33A1FF"),
  getColorFromHex("#66A9FF"),
  getColorFromHex("#99B1FF"),
  getColorFromHex("#CCB9FF"),
  getColorFromHex("#FFC1FF"),
  getColorFromHex("#FFCDE3"),
  getColorFromHex("#FFD9EB"),
];

final orangeColorList = <Color>[
  Color(int.parse("#FF9900".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#FFA633".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#FFB366".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#FFC099".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#FFD1CC".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#FFE2FF".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#FFEDFF".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#FFF9FF".substring(1, 7), radix: 16) + 0xFF000000),
];

final purpleColorList = <Color>[
  Color(int.parse("#800080".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#993399".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#B266B2".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#CC99CC".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#E6C2E6".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#F5E5F5".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#FFEDFF".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#FFF9FF".substring(1, 7), radix: 16) + 0xFF000000),
];

final blackColorList = <Color>[
  Color(int.parse("#000000".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#111111".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#222222".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#333333".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#444444".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#555555".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#666666".substring(1, 7), radix: 16) + 0xFF000000),
  Color(int.parse("#777777".substring(1, 7), radix: 16) + 0xFF000000),
];

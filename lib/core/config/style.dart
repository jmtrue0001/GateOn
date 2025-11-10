import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'generated/style.g.dart';

const enFontFamily = "CabinetGrotesk";
const krFontFamily = "SUIT";
const lightBackground = white;
const darkBackground = Color(0xff374247);
const darkForeground = Color(0xff262626);
const borderColor = Color(0xffFEFEFE);
const dropShadowColor_1 = Color.fromRGBO(92, 77, 77, 0.25);
const dropShadowColor_2 = Color.fromRGBO(0, 0, 0, 0.05);
const dropShadowColor_3 = Color.fromRGBO(0, 0, 0, 0.2);
const dropShadowColor_4 = Color.fromRGBO(0, 0, 0, 0.4);
const lightSurfaceColor = Color.fromRGBO(255, 255, 255, 0.9);
const darkSurfaceColor = Color.fromRGBO(60, 60, 60, 0.7);
const black = Colors.black;
const black1 = Color(0xff2D2D35);
const black2 = Color(0xff1E1E1E);
const gray0 = Color(0xffADADAD);
const gray1 = Color(0xffEFF1F6);
const gray2 = Color(0xff888888);
const gray3 = Color(0xffBDBDBD);
const gray4 = Color(0xffCECECE);
const gray5 = Color(0xffDDDDDD);
const gray6 = Color(0xffE8E8E8);
const gray7 = Color(0xffF0F0F0);
const gray8 = Color(0xffF6F6F6);
const gray9 = Color(0xffFBFBFB);
const white = Colors.white;
const blue1 = Color(0xff2F80ED);
const secondColor = Color(0xff7BFF5A);

const lightTextColor = Color(0xff4E575A);

KRTextTheme textTheme(BuildContext context) => Theme.of(context).extension<KRTextTheme>() ?? const KRTextTheme();

ColorTheme colorTheme(BuildContext context) => Theme.of(context).extension<ColorTheme>() ?? const ColorTheme();

@immutable
@CopyWith()
class ColorTheme extends ThemeExtension<ColorTheme> {
  const ColorTheme({
    this.primary = black,
    this.background = black,
    this.foreground = black,
    this.foregroundText = white,
    this.active = black,
    this.border = black,
    this.bottomNavigationBarSurface = black,
    this.activeButton = black,
    this.disableButton = black,
    this.activeTextColor = black,
    this.disableTextColor = black,
    this.primarySecond = white,
    this.titleText = black,
    this.logoColor = white,
    this.profileButtonColor = const Color(0xff2C2C2C),
    this.overBackgroundColor = const Color(0xffFAFAFB),
    this.overDisableBackgroundColor = const Color(0xffEB5757),
    this.cameraColor = blue1,
    this.activeRadioColor = white,
    this.splashColor = blue1,
  });

  final Color primary;
  final Color background;
  final Color foreground;
  final Color foregroundText;
  final Color active;
  final Color border;
  final Color bottomNavigationBarSurface;
  final Color activeButton;
  final Color disableButton;
  final Color activeTextColor;
  final Color disableTextColor;
  final Color activeRadioColor;
  final Color primarySecond;
  final Color titleText;
  final Color? logoColor;
  final Color profileButtonColor;
  final Color overBackgroundColor;
  final Color overDisableBackgroundColor;
  final Color cameraColor;
  final Color splashColor;

  @override
  ThemeExtension<ColorTheme> copyWith() => $ColorThemeCopyWith(this).copyWith();

  @override
  ThemeExtension<ColorTheme> lerp(ThemeExtension<ColorTheme>? other, double t) {
    if (other is! ColorTheme) {
      return this;
    }
    return ColorTheme(background: Color.lerp(background, other.background, t) ?? background);
  }

  static const light = ColorTheme(
      primary: darkBackground,
      background: lightBackground,
      foreground: blue1,
      foregroundText: white,
      border: gray7,
      bottomNavigationBarSurface: lightSurfaceColor,
      active: blue1,
      activeButton: blue1,
      disableButton: Color(0xffDCE3E6),
      activeTextColor: white,
      activeRadioColor: lightTextColor,
      disableTextColor: Color(0xff7B878D),
      primarySecond: secondColor,
      titleText: black,
      logoColor: null,
      profileButtonColor: black,
      overBackgroundColor: Color(0xffFAFAFB),
      overDisableBackgroundColor: Color(0xffE13E3E),
      cameraColor: blue1,
      splashColor: blue1);

  static const dark = ColorTheme(
      primary: white,
      background: darkBackground,
      foreground: darkForeground,
      titleText: white,
      border: black2,
      activeRadioColor: white,
      bottomNavigationBarSurface: darkSurfaceColor,
      active: white,
      activeButton: black2,
      disableButton: lightTextColor,
      logoColor: white,
      profileButtonColor: black,
      activeTextColor: white,
      overDisableBackgroundColor: Color(0xffEB5757),
      disableTextColor: Color(0xff7B878D),
      overBackgroundColor: Color(0xff21282B),
      cameraColor: darkBackground,
      splashColor: black);
}

@immutable
@CopyWith()
class KRTextTheme extends ThemeExtension<KRTextTheme> {
  const KRTextTheme({
    this.krTitle1 = const TextStyle(),
    this.krTitle2 = const TextStyle(),
    this.krTitle2R = const TextStyle(),
    this.krSubtitle1 = const TextStyle(),
    this.krSubtitle1R = const TextStyle(),
    this.krBody1 = const TextStyle(),
    this.krBody2 = const TextStyle(),
    this.krSubtext1 = const TextStyle(),
    this.krSubtext1B = const TextStyle(),
    this.krSubtext2 = const TextStyle(),
    this.bodyMedium = const TextStyle(),
    this.bodySmall = const TextStyle(),
  });

  final TextStyle krTitle1;
  final TextStyle krTitle2;
  final TextStyle krTitle2R;
  final TextStyle krSubtitle1;
  final TextStyle krSubtitle1R;
  final TextStyle krBody1;
  final TextStyle krBody2;
  final TextStyle krSubtext1;
  final TextStyle krSubtext1B;
  final TextStyle krSubtext2;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;

  @override
  ThemeExtension<KRTextTheme> lerp(ThemeExtension<KRTextTheme>? other, double t) {
    if (other is! KRTextTheme) {
      return this;
    }
    return const KRTextTheme();
  }

  static const light = KRTextTheme(
    krTitle1: TextStyle(fontFamily: krFontFamily, fontSize: 22, fontWeight: FontWeight.w700, color: lightTextColor),
    krTitle2: TextStyle(fontFamily: krFontFamily, fontSize: 20, fontWeight: FontWeight.w700, color: lightTextColor),
    krTitle2R: TextStyle(fontFamily: krFontFamily, fontSize: 20, fontWeight: FontWeight.w500, color: lightTextColor),
    krSubtitle1: TextStyle(fontFamily: krFontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: lightTextColor),
    krSubtitle1R: TextStyle(fontFamily: krFontFamily, fontSize: 18, fontWeight: FontWeight.w500, color: lightTextColor),
    krBody1: TextStyle(fontFamily: krFontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: lightTextColor),
    krBody2: TextStyle(fontFamily: krFontFamily, fontSize: 16, fontWeight: FontWeight.w700, color: lightTextColor),
    krSubtext1: TextStyle(fontFamily: krFontFamily, fontSize: 15, fontWeight: FontWeight.w500, color: lightTextColor),
    krSubtext1B: TextStyle(fontFamily: krFontFamily, fontSize: 15, fontWeight: FontWeight.w700, color: lightTextColor),
    krSubtext2: TextStyle(fontFamily: krFontFamily, fontSize: 12, fontWeight: FontWeight.w500, color: lightTextColor),
    bodyMedium: TextStyle(fontFamily: krFontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: gray1),
    bodySmall: TextStyle(fontFamily: krFontFamily, fontSize: 12, fontWeight: FontWeight.w500, color: gray1),
  );

  static const dark = KRTextTheme(
    krTitle1: TextStyle(fontFamily: krFontFamily, fontSize: 22, fontWeight: FontWeight.w700, color: white),
    krTitle2: TextStyle(fontFamily: krFontFamily, fontSize: 20, fontWeight: FontWeight.w700, color: white),
    krTitle2R: TextStyle(fontFamily: krFontFamily, fontSize: 20, fontWeight: FontWeight.w500, color: white),
    krSubtitle1: TextStyle(fontFamily: krFontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: white),
    krSubtitle1R: TextStyle(fontFamily: krFontFamily, fontSize: 18, fontWeight: FontWeight.w500, color: white),
    krBody1: TextStyle(fontFamily: krFontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: white),
    krBody2: TextStyle(fontFamily: krFontFamily, fontSize: 16, fontWeight: FontWeight.w700, color: white),
    krSubtext1: TextStyle(fontFamily: krFontFamily, fontSize: 15, fontWeight: FontWeight.w500, color: white),
    krSubtext1B: TextStyle(fontFamily: krFontFamily, fontSize: 15, fontWeight: FontWeight.w700, color: white),
    krSubtext2: TextStyle(fontFamily: krFontFamily, fontSize: 12, fontWeight: FontWeight.w500, color: white),
    bodyMedium: TextStyle(fontFamily: krFontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: white),
    bodySmall: TextStyle(fontFamily: krFontFamily, fontSize: 12, fontWeight: FontWeight.w500, color: white),
  );

  @override
  ThemeExtension<KRTextTheme> copyWith() => $KRTextThemeCopyWith(this).copyWith();
}

@immutable
class MyColors extends ThemeExtension<MyColors> {
  const MyColors({
    required this.background,
    required this.loginTextColor,
  });

  final Color? background;
  final Color? loginTextColor;

  @override
  ThemeExtension<MyColors> copyWith({Color? background, Color? loginTextColor}) {
    return MyColors(
      background: background ?? this.background,
      loginTextColor: loginTextColor ?? this.loginTextColor,
    );
  }

  @override
  ThemeExtension<MyColors> lerp(ThemeExtension<MyColors>? other, double t) {
    if (other is! MyColors) {
      return this;
    }
    return MyColors(background: Color.lerp(background, other.background, t), loginTextColor: Color.lerp(loginTextColor, other.loginTextColor, t));
  }

  static const light = MyColors(
    background: lightBackground,
    loginTextColor: gray1,
  );

  static const dark = MyColors(
    background: black2,
    loginTextColor: white,
  );
}

var lightTheme = ThemeData(
  extensions: const <ThemeExtension<dynamic>>[
    ColorTheme.light,
    KRTextTheme.light,
  ],
  brightness: Brightness.light,
  dividerColor: gray6,
  textTheme: const TextTheme(
    titleSmall: TextStyle(fontFamily: krFontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: black),
    bodyLarge: TextStyle(fontFamily: krFontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: black),
    bodyMedium: TextStyle(fontFamily: krFontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: gray1),
    bodySmall: TextStyle(fontFamily: krFontFamily, fontSize: 12, fontWeight: FontWeight.w500, color: gray1),
  ).apply(bodyColor: black),
  scaffoldBackgroundColor: lightBackground,
  bottomSheetTheme: const BottomSheetThemeData(backgroundColor: white),
  appBarTheme: const AppBarTheme(backgroundColor: lightBackground, foregroundColor: black, systemOverlayStyle: SystemUiOverlayStyle.dark, iconTheme: IconThemeData(color: gray1)),
  tabBarTheme: const TabBarThemeData(
    indicator: UnderlineTabIndicator(insets: EdgeInsets.only(left: 24.0, right: 24.0, top: 16), borderSide: BorderSide(width: 2, color: black)),
    labelColor: black,
    unselectedLabelColor: black,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xffEFF1F6),
    floatingLabelBehavior: FloatingLabelBehavior.never,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: Color(0xffD2D7DD), width: 1.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: Color(0xffD2D7DD), width: 1.0),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: Color(0xffD2D7DD), width: 1.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: Color(0xffD2D7DD), width: 1.0),
    ),
    contentPadding: const EdgeInsets.all(24),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: white.withOpacity(0),
    elevation: 0,
    selectedItemColor: black,
    unselectedItemColor: gray3,
  ),
  dialogBackgroundColor: white,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(black),
      foregroundColor: MaterialStateProperty.all<Color>(white),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    ),
  ),
  primaryColor: black,
  primaryColorLight: blue1,
  primaryColorDark: white,
);

var darkTheme = ThemeData(
  extensions: const <ThemeExtension<dynamic>>[
    ColorTheme.dark,
    KRTextTheme.dark,
  ],
  brightness: Brightness.dark,
  scaffoldBackgroundColor: darkBackground,
  bottomSheetTheme: const BottomSheetThemeData(backgroundColor: black),
  dividerColor: black,
  textTheme: const TextTheme(
    titleSmall: TextStyle(fontFamily: krFontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: white),
    bodyLarge: TextStyle(fontFamily: krFontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: white),
    bodyMedium: TextStyle(fontFamily: krFontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: white),
    bodySmall: TextStyle(fontFamily: krFontFamily, fontSize: 12, fontWeight: FontWeight.w500, color: white),
  ).apply(bodyColor: white),
  appBarTheme: const AppBarTheme(iconTheme: IconThemeData(color: white), backgroundColor: darkBackground, foregroundColor: white, systemOverlayStyle: SystemUiOverlayStyle.light),
  tabBarTheme: const TabBarThemeData(
    indicator: UnderlineTabIndicator(insets: EdgeInsets.only(left: 24.0, right: 24.0, top: 16), borderSide: BorderSide(width: 2, color: white)),
    labelColor: white,
    unselectedLabelColor: white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    floatingLabelBehavior: FloatingLabelBehavior.never,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: gray7, width: 1.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: gray7, width: 2.0),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: gray7, width: 1.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: gray7, width: 1.0),
    ),
    contentPadding: const EdgeInsets.all(24),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: black.withOpacity(0),
    elevation: 0,
    selectedItemColor: white,
    unselectedItemColor: gray1,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(black),
      foregroundColor: MaterialStateProperty.all<Color>(white),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    ),
  ),
  dialogBackgroundColor: black,
  primaryColor: white,
  primaryColorLight: black,
  primaryColorDark: gray0,
);

class HexColor extends Color {
  static int _getColorFromHex(String? hexColor) {
    if (hexColor != null) {
      hexColor = hexColor.toUpperCase().replaceAll("#", "");
      if (hexColor.length == 6) {
        hexColor = "FF$hexColor";
      }
      return int.parse(hexColor, radix: 16);
    } else {
      return int.parse("FF000000", radix: 16);
    }
  }

  HexColor(final String? hexColor) : super(_getColorFromHex(hexColor));
}

class ColorHex extends StringBuffer {
  static String _getHexFromColor(Color? color) {
    if (color != null) {
      var colorText = color.toString().replaceAll('Color(', '').replaceAll(')', '').replaceAll('0xff', '').toUpperCase();
      return colorText;
    } else {
      return "000000";
    }
  }

  ColorHex(final Color? hexColor) : super(_getHexFromColor(hexColor));
}

class TextColor extends Color {
  static int _getTextColor(String bgColor) => HexColor(bgColor).computeLuminance() > 0.5 ? black.value : white.value;

  TextColor(final String? bgColor) : super(_getTextColor(bgColor ?? ""));
}

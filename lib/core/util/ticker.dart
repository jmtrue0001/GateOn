class Ticker {
  const Ticker();

  static Ticker get to => const Ticker();

  Stream<int> timer({required int time}) {
    final result = Stream.periodic(const Duration(seconds: 1), (x) => time - x - 1).take(time);
    return result;
  }

  Stream<int> stopwatch({required int duration}) {
    final result = Stream.periodic(Duration(seconds: duration), (x) => x + duration);
    return result;
  }
}

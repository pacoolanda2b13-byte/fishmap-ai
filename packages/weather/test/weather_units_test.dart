import 'package:test/test.dart';
import 'package:weather/weather.dart';

void main() {
  group('WeatherUnits', () {
    test('m/s → km/h', () {
      expect(WeatherUnits.msToKmh(10), closeTo(36, 0.0001));
    });
    test('km/h → m/s est réciproque', () {
      expect(WeatherUnits.kmhToMs(WeatherUnits.msToKmh(7)), closeTo(7, 1e-9));
    });
    test('nœuds → km/h', () {
      expect(WeatherUnits.knotsToKmh(10), closeTo(18.52, 0.0001));
    });
    test('Kelvin → Celsius', () {
      expect(WeatherUnits.kelvinToCelsius(300), closeTo(26.85, 0.0001));
    });
    test('Fahrenheit → Celsius', () {
      expect(WeatherUnits.fahrenheitToCelsius(50), closeTo(10, 0.0001));
    });
    test('Pa → hPa', () {
      expect(WeatherUnits.paToHpa(101325), closeTo(1013.25, 0.0001));
    });
  });
}

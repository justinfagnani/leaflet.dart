
import 'dart:html' show document, Element;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';

import 'package:leaflet/map/map.dart' show LeafletMap;
import 'package:leaflet/control/control.dart' show Attribution;


main() {
  useHtmlEnhancedConfiguration();

  group('Control.Attribution', () {
    LeafletMap map;
    Attribution control;
    Element container;

    setUp(() {
      map = new LeafletMap(document.createElement('div'));
      control = new Attribution({
        'prefix': 'prefix'
      })..addTo(map);
      container = control.getContainer();
    });

    test('contains just prefix if no attributions added', () {
      expect(container.innerHTML, equals('prefix'));
    });

    group('#addAttribution', () {
      test('adds one attribution correctly', () {
        control.addAttribution('foo');
        expect(container.innerHTML, equals('prefix | foo'));
      });

      test('adds no duplicate attributions', () {
        control.addAttribution('foo');
        control.addAttribution('foo');
        expect(container.innerHTML, equals('prefix | foo'));
      });

      test('adds several attributions listed with comma', () {
        control.addAttribution('foo');
        control.addAttribution('bar');
        expect(container.innerHTML, equals('prefix | foo, bar'));
      });
    });

    group('#removeAttribution', () {
      test('removes attribution correctly', () {
        control.addAttribution('foo');
        control.addAttribution('bar');
        control.removeAttribution('foo');
        expect(container.innerHTML, equals('prefix | bar'));
      });
      test('does nothing if removing attribution that was not present', () {
        control.addAttribution('foo');
        control.addAttribution('baz');
        control.removeAttribution('bar');
        control.removeAttribution('baz');
        control.removeAttribution('baz');
        control.removeAttribution('');
        expect(container.innerHTML, equals('prefix | foo'));
      });
    });

    group('#setPrefix', () {
      test('changes prefix', () {
        control.setPrefix('bla');
        expect(container.innerHTML, equals('bla'));
      });
    });

    group('control.attribution factory', () {
      test('creates control.Attribution instance', () {
        var options = {'prefix': 'prefix'};
        expect(new attribution(options), equals(new Attribution(options)));
      });
    });
  });
}

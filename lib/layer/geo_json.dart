library leaflet.layer;

// GeoJSON turns any GeoJSON data into a Leaflet layer.
class GeoJSON extends FeatureGroup {
  GeoJSON(geojson, options) {
    L.setOptions(this, options);

    this._layers = {};

    if (geojson) {
      this.addData(geojson);
    }
  }

  addData(geojson) {
    var features = L.Util.isArray(geojson) ? geojson : geojson.features,
        i, len, feature;

    if (features) {
      len = features.length;
      for (i = 0; i < len; i++) {
        // Only add this if geometry or geometries are set and not null
        feature = features[i];
        if (feature.geometries || feature.geometry || feature.features || feature.coordinates) {
          this.addData(features[i]);
        }
      }
      return this;
    }

    var options = this.options;

    if (options.filter && !options.filter(geojson)) { return; }

    var layer = L.GeoJSON.geometryToLayer(geojson, options.pointToLayer, options.coordsToLatLng, options);
    layer.feature = L.GeoJSON.asFeature(geojson);

    layer.defaultOptions = layer.options;
    this.resetStyle(layer);

    if (options.onEachFeature) {
      options.onEachFeature(geojson, layer);
    }

    return this.addLayer(layer);
  }

  resetStyle(layer) {
    var style = this.options.style;
    if (style) {
      // reset any custom styles
      L.Util.extend(layer.options, layer.defaultOptions);

      this._setLayerStyle(layer, style);
    }
  }

  setStyle(style) {
    this.eachLayer((layer) {
      this._setLayerStyle(layer, style);
    }, this);
  }

  _setLayerStyle(layer, style) {
    if (style is Function) {
      style = style(layer.feature);
    }
    if (layer.setStyle) {
      layer.setStyle(style);
    }
  }
}

class GeoJSON2 extends GeoJSON {
  geometryToLayer(geojson, pointToLayer, coordsToLatLng, vectorOptions) {
    var geometry = geojson.type == 'Feature' ? geojson.geometry : geojson,
        coords = geometry.coordinates,
        layers = [],
        latlng, latlngs, i, len;

    coordsToLatLng = coordsToLatLng || this.coordsToLatLng;

    switch (geometry.type) {
    case 'Point':
      latlng = coordsToLatLng(coords);
      return pointToLayer ? pointToLayer(geojson, latlng) : new L.Marker(latlng);

    case 'MultiPoint':
      len = coords.length;
      for (i = 0; i < len; i++) {
        latlng = coordsToLatLng(coords[i]);
        layers.push(pointToLayer ? pointToLayer(geojson, latlng) : new L.Marker(latlng));
      }
      return new L.FeatureGroup(layers);

    case 'LineString':
      latlngs = this.coordsToLatLngs(coords, 0, coordsToLatLng);
      return new L.Polyline(latlngs, vectorOptions);

    case 'Polygon':
      if (coords.length == 2 && !coords[1].length) {
        throw new Error('Invalid GeoJSON object.');
      }
      latlngs = this.coordsToLatLngs(coords, 1, coordsToLatLng);
      return new L.Polygon(latlngs, vectorOptions);

    case 'MultiLineString':
      latlngs = this.coordsToLatLngs(coords, 1, coordsToLatLng);
      return new L.MultiPolyline(latlngs, vectorOptions);

    case 'MultiPolygon':
      latlngs = this.coordsToLatLngs(coords, 2, coordsToLatLng);
      return new L.MultiPolygon(latlngs, vectorOptions);

    case 'GeometryCollection':
      len = geometry.geometries.length;
      for (i = 0; i < len; i++) {

        layers.push(this.geometryToLayer({
          geometry: geometry.geometries[i],
          type: 'Feature',
          properties: geojson.properties
        }, pointToLayer, coordsToLatLng, vectorOptions));
      }
      return new L.FeatureGroup(layers);

    default:
      throw new Error('Invalid GeoJSON object.');
    }
  }

  coordsToLatLng(coords) { // (Array[, Boolean]) -> LatLng
    return new L.LatLng(coords[1], coords[0], coords[2]);
  }

  coordsToLatLngs(coords, levelsDeep, coordsToLatLng) { // (Array[, Number, Function]) -> Array
    var latlng, i, len,
        latlngs = [];

    len = coords.length;
    for (i = 0; i < len; i++) {
      latlng = levelsDeep ?
              this.coordsToLatLngs(coords[i], levelsDeep - 1, coordsToLatLng) :
              (coordsToLatLng || this.coordsToLatLng)(coords[i]);

      latlngs.push(latlng);
    }

    return latlngs;
  }

  latLngToCoords(latlng) {
    var coords = [latlng.lng, latlng.lat];

    if (latlng.alt != null) {
      coords.push(latlng.alt);
    }
    return coords;
  }

  latLngsToCoords(latLngs) {
    var coords = [];

    for (var i = 0, len = latLngs.length; i < len; i++) {
      coords.push(L.GeoJSON.latLngToCoords(latLngs[i]));
    }

    return coords;
  }

  getFeature(layer, newGeometry) {
    return layer.feature ? L.extend({}, layer.feature, {'geometry': newGeometry}) : L.GeoJSON.asFeature(newGeometry);
  }

  asFeature(geoJSON) {
    if (geoJSON.type == 'Feature') {
      return geoJSON;
    }

    return {
      'type': 'Feature',
      'properties': {},
      'geometry': geoJSON
    };
  }
}

var PointToGeoJSON = {
  'toGeoJSON': () {
    return L.GeoJSON.getFeature(this, {
      'type': 'Point',
      'coordinates': L.GeoJSON.latLngToCoords(this.getLatLng())
    });
  }
};

L.Marker.include(PointToGeoJSON);
L.Circle.include(PointToGeoJSON);
L.CircleMarker.include(PointToGeoJSON);

L.Polyline.include({
  'toGeoJSON': function () {
    return L.GeoJSON.getFeature(this, {
      'type': 'LineString',
      'coordinates': L.GeoJSON.latLngsToCoords(this.getLatLngs())
    });
  }
});

L.Polygon.include({
  'toGeoJSON': () {
    var coords = [L.GeoJSON.latLngsToCoords(this.getLatLngs())],
        i, len, hole;

    coords[0].push(coords[0][0]);

    if (this._holes) {
      len = this._holes.length;
      for (i = 0; i < len; i++) {
        hole = L.GeoJSON.latLngsToCoords(this._holes[i]);
        hole.push(hole[0]);
        coords.push(hole);
      }
    }

    return L.GeoJSON.getFeature(this, {
      'type': 'Polygon',
      'coordinates': coords
    });
  }
});
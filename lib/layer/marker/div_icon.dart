part of leaflet.layer.marker;

// DivIcon is a lightweight HTML-based icon class (as opposed to the image-based Icon)
// to use with Marker.
class DivIcon extends Icon {
  final Map<String, Object> options = {
    'iconSize': [12, 12], // also can be set through CSS
    /*
    iconAnchor: (Point)
    popupAnchor: (Point)
    html: (String)
    bgPos: (Point)
    */
    'className': 'leaflet-div-icon',
    'html': false
  };

  DivIcon() : super({});

  createIcon(oldIcon) {
    final div = (oldIcon != null && oldIcon.tagName == 'DIV') ? oldIcon : document.createElement('div'),
        options = this.options;

    if (options['html'] != false) {
      div.innerHTML = options['html'];
    } else {
      div.innerHTML = '';
    }

    if (options.containsKey('bgPos')) {
      div.style.backgroundPosition =
              (-options.bgPos.x) + 'px ' + (-options.bgPos.y) + 'px';
    }

    this._setIconStyles(div, 'icon');
    return div;
  }

  createShadow() {
    return null;
  }
}
part of leaflet.dom;

/**
 * PosAnimation is used by Leaflet internally for pan animations.
 */
class PosAnimation extends Object with Events {

  Element _el;
  bool _inProgress;
  Point2D _newPos;
  Timer _stepTimer;

  bool get inProgress => _inProgress;

  /**
   * Run an animation of a given element to a new position, optionally setting duration in seconds (0.25 by default) and easing linearity factor (3rd argument of the cubic bezier curve, 0.5 by default)
   */
  run(Element el, Point2D newPos, [num duration, num easeLinearity]) { // (HTMLElement, Point[, Number, Number])
    this.stop();

    this._el = el;
    this._inProgress = true;
    this._newPos = newPos;

    this.fire(EventType.START);

    el.style.transition = 'all ${firstNonNull(duration, 0.25)}s'
            'cubic-bezier(0,0,${firstNonNull(easeLinearity, 0.5)},1)';

    el.onTransitionEnd.first.then(_onTransitionEnd);
    setPosition(el, newPos);

    // toggle reflow, Chrome flickers for some reason if you don't do this
//    Util.falseFn(el.offsetWidth);

    // there's no native way to track value updates of transitioned properties, so we imitate this
    this._stepTimer = new Timer(new Duration(milliseconds: 50), _onStep);
  }

  stop() {
    if (this._inProgress != true) { return; }

    // if we just removed the transition property, the element would jump to its final position,
    // so we need to make it stay at the current position

    setPosition(this._el, this._getPos());
    _onTransitionEnd();
//    falseFn(this._el.offsetWidth); // force reflow in case we are about to start a new animation
  }

  _onStep() {
    var stepPos = this._getPos();
    if (stepPos == null) {
      this._onTransitionEnd();
      return;
    }
    // jshint camelcase: false
    // make L.DomUtil.getPosition return intermediate position value during animation
    _leafletPos[_el] = stepPos;

    this.fire(EventType.STEP);
  }

  // you can't easily get intermediate values of properties animated with CSS3 Transitions,
  // we need to parse computed style (in case of transform it returns matrix string)

  var _transformRe = r'([-+]?(?:\d*\.)?\d+)\D*, ([-+]?(?:\d*\.)?\d+)\D*\)';
//  var _transformRe = r'([-+]?(?:\d*\.)?\d+)\D*[,\)]';

  _getPos() {
    var style = _el.getComputedStyle();

    var t = style.transform;
    // TODO(justin): why isn't the regex working?
    if (t.startsWith('matrix(')) {
        var u = t.substring('matrix('.length, t.length - 1)
            .split(',')
            .map((e) => double.parse(e.trim())).toList();
        var left = u[1];
        var top  = u[2];
        return new Point2D(left, top, true);
    }

//    List<Match> matches = _transformRe.allMatches(style.transform).toList();
//
//    if (matches.isEmpty) { return null; }
//    var left = double.parse(matches[1].toString());
//    var top  = double.parse(matches[2].toString());
//
//    return new Point2D(left, top, true);
  }

  _onTransitionEnd([Event e]) {
    // because we use .first when subscribing
//    DomEvent.off(this._el, DomUtil.TRANSITION_END, this._onTransitionEnd, this);

    if (!this._inProgress) { return; }
    this._inProgress = false;

    this._el.style.transition = '';

    // jshint camelcase: false
    // make sure L.DomUtil.getPosition returns the final position value after animation
    _leafletPos[_el] = _newPos;

    _stepTimer.cancel();
    _stepTimer = null;

    fire(EventType.STEP);
    fire(EventType.END);
  }
}
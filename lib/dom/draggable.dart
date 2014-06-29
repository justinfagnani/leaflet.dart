part of leaflet.dom;

/**
 * Draggable allows you to add dragging capabilities to any element. Supports mobile devices too.
 */
class Draggable extends Object with Events {

  static bool disabled = false;// TODO implement global drag disable

  static var START = browser.touch ? ['touchstart', 'mousedown'] : ['mousedown'];
  static var END = {
      'mousedown': 'mouseup',
      'touchstart': 'touchend',
      'pointerdown': 'touchend',
      'MSPointerDown': 'touchend'
    };
  static var MOVE = {
      'mousedown': 'mousemove',
      'touchstart': 'touchmove',
      'pointerdown': 'touchmove',
      'MSPointerDown': 'touchmove'
    };

  Element _element, _dragStartTarget;
  bool _enabled, _moved, _moving;
  Point2D _startPoint;
  var _startPos, _newPos, _animRequest;

  bool get moved =>_moved;
  Point2D get newPos => _newPos;

  /**
   * Creates a Draggable object for moving the given element when you start dragging the dragHandle element (equals the element itself by default).
   */
  Draggable(this._element, dragStartTarget) {
    _dragStartTarget = firstNonNull(dragStartTarget, _element);
  }

  /**
   * Enables the dragging ability.
   */
  enable() {
    if (this._enabled) { return; }

    for (var i = Draggable.START.length - 1; i >= 0; i--) {
      this._dragStartTarget.addEventListener(Draggable.START[i],_onDown);
    }

    this._enabled = true;
  }

  /**
   * Disables the dragging ability.
   */
  disable() {
    if (!this._enabled) { return; }

    for (var i = Draggable.START.length - 1; i >= 0; i--) {
      this._dragStartTarget.removeEventListener(Draggable.START[i],_onDown);
    }

    this._enabled = false;
    this._moved = false;
  }

  _onDown(e) {
    this._moved = false;

    if (e.shiftKey || ((e.which != 1) && (e.button != 1) && !e.touches)) { return; }

    stopPropagation(e);

    if (Draggable.disabled) { return; }

    disableImageDrag();
    disableTextSelection();

    if (this._moving) { return; }

    var first = e.touches ? e.touches[0] : e;

    this._startPoint = new Point2D(first.clientX, first.clientY);
    this._startPos = this._newPos = getPosition(this._element);

    document
        ..addEventListener(Draggable.MOVE[e.type], _onMove)
        ..addEventListener(Draggable.END[e.type], _onUp);
  }

  _onMove(Event e) {
    Element target = e.target;

    if (e is TouchEvent && e.touches.length > 1) {
      this._moved = true;
      return;
    }

    var first = (e is TouchEvent && e.touches.length == 1 ? e.touches.first : e),
        newPoint = new Point2D(first.clientX, first.clientY),
        offset = newPoint..subtract(this._startPoint);

    if (!offset.x && !offset.y) { return; }

    preventDefault(e);

    if (!this._moved) {
      this.fire(EventType.DRAGSTART);

      this._moved = true;
      this._startPos = getPosition(this._element)..subtract(offset);

      document.body.classes.add('leaflet-dragging');
      target.classes.add('leaflet-drag-target');
    }

    this._newPos = this._startPos.add(offset);
    this._moving = true;

    window.cancelAnimationFrame(this._animRequest);
    this._animRequest = window.requestAnimationFrame(_updatePosition);
//    this._animRequest = Util.requestAnimFrame(this._updatePosition, this, true, this._dragStartTarget);
  }

  _updatePosition(_) {
    this.fire(EventType.PREDRAG);
    setPosition(this._element, this._newPos);
    this.fire(EventType.DRAG);
  }

  _onUp(e) {
    document.body.classes.remove('leaflet-dragging');
    e.target.classes.remove('leaflet-drag-target');

    for (var i in Draggable.MOVE) {
      document
        ..removeEventListener(Draggable.MOVE[i], _onMove)
        ..removeEventListener(Draggable.END[i], _onUp);
    }

    enableImageDrag();
    enableTextSelection();

    if (this._moved && this._moving) {
      // ensure drag is not fired after dragend
      window.cancelAnimationFrame(this._animRequest);

      this.fireEvent(new DragEndEvent(_newPos.distanceTo(this._startPos)));
    }

    this._moving = false;
  }
}
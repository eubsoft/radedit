var DEFAULT_ANIMATION_FRAME_COUNT = 40;
var DEFAULT_ANIMATION_FRAME_DELAY = 20;

var animate = function(element, styleTransitions, onFinish, frameCount, frameDelay, frameIndex) {
    if (element = getElement(element)) {
        // Only allow one animation on an element at a time.
        stopAnimation(element);
        frameIndex = frameIndex || 0;
        frameCount = frameCount || DEFAULT_ANIMATION_FRAME_COUNT;
        frameDelay = frameDelay || DEFAULT_ANIMATION_FRAME_DELAY;
        var scale = Math.atan(1.5) * 2;
        var fraction = Math.atan(frameIndex / frameCount * 3 - 1.5) / scale + 0.5;
        var styles = {};
        forIn(styleTransitions, function(transition, key) {
            var start = transition[0];
            var end = transition[1];
            var value;
            if (isNaN(start)) {
                value = frameIndex ? end : start;
            }
            else {
                value = (1 - fraction) * start + fraction * end;
            }
            styles[key] = value;
        });
        extendStyle(element, styles);
        if (frameIndex < frameCount) {
            element.animation = setTimeout(function() {
                animate(element, styleTransitions, onFinish, frameCount, frameDelay, frameIndex + 1);
            });
        }
        else if (onFinish) {
            onFinish(element);
        }
    }
};

var stopAnimation = function(element) {
    if (element = getElement(element)) {
        clearTimeout(element.animation);
    }
};
export const hasWindowModel = function() {
  return window.__LUNA_INITIAL_MODEL__ != null;
};

export const getWindowModelJson = function() {
  return window.__LUNA_INITIAL_MODEL__;
};
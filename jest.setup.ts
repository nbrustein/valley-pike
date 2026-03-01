declare global {
  var flunk: () => void;
}

global.flunk = () => {
  throw new Error("Flunked");
};

export {};

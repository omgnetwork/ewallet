export function mergeHash(destination, source) {
  for (var property in source) {
    destination[property] = source[property];
  }
  return destination;
};

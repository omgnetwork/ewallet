export default (destination, source) => {
  for (const property in source) { // eslint-disable-line no-restricted-syntax, guard-for-in
    destination[property] = source[property]; // eslint-disable-line no-param-reassign
  }
  return destination;
};

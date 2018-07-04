export function fuzzySearch (search = '', match = '') {
  return new RegExp(_.escapeRegExp(search.toLowerCase())).test(match.toLocaleLowerCase())
}

export function fuzzySearch (search = '', match = '') {
  console.log(search)
  return new RegExp(_.escapeRegExp(search.toLowerCase())).test(match.toLocaleLowerCase())
}

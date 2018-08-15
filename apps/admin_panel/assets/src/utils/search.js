export function fuzzySearch (search, match) {
  const searchText = search || ''
  const matchText = match || ''
  return new RegExp(_.escapeRegExp(searchText.toLowerCase())).test(matchText.toLowerCase())
}

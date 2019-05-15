export function flatten (data) {
  let result = {}
  function recurse (cur, prop) {
    if (Object(cur) !== cur) {
      result[prop] = cur
    } else if (Array.isArray(cur)) {
      for (let i = 0; i < cur.length; i++) {
        recurse(cur[i], prop ? prop + '.' + i : '' + i)
      }
      if (cur.length === 0) {
        result[prop] = []
      }
    } else {
      let isEmpty = true
      for (let p in cur) {
        isEmpty = false
        recurse(cur[p], prop ? prop + '.' + p : p)
      }
      if (isEmpty) {
        result[prop] = {}
      }
    }
  }
  recurse(data, '')
  return result
}

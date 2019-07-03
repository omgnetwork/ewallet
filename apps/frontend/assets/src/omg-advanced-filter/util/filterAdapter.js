import { FILTER_MAP } from '../FilterMap'

const filterAdapter = (values) => {
  let _matchAll = []
  let _matchAny = []

  _.forOwn(values, (value, key) => {
    const { matchAll, matchAny } = _.find(FILTER_MAP, ['key', key])

    if (matchAll) {
      matchAll.forEach(filter => {
        if (filter.hasOwnProperty('value')) {
          try {
            const cleaned = JSON.parse(JSON.stringify(value))
            const compiledValue = _.template(filter.value)(cleaned)
            _matchAll.push({ ...filter, value: compiledValue })
          } catch (e) {
            //
          }
        } else {
          Array.isArray(value)
            ? value.forEach(i => _matchAll.push({ ...filter, value: i }))
            : _matchAll.push({ ...filter, value })
        }
      })
    }

    if (matchAny) {
      if (Array.isArray(value)) {
        value.forEach(i => {
          matchAny.forEach(filter => {
            i.hasOwnProperty('value')
              ? _matchAny.push({ ...filter, value: i.value })
              : _matchAny.push({ ...filter, value: i })
          })
        })
      } else {
        matchAny.forEach(filter => _matchAny.push({ ...filter, value }))
      }
    }
  })

  return { matchAll: _matchAll, matchAny: _matchAny }
}

export default filterAdapter

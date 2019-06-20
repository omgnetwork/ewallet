const breadcrumbFactory = (value) => {
  if (Array.isArray(value)) {
    let values = value
    if (typeof value[0] === 'object') {
      values = value.map(i => i.label)
    }
    return `${values}`.replace(/,/g, ', ')
  }

  if (typeof value === 'object') {
    let startDate
    let endDate

    const start = _.get(value, 'startDate')
    const end = _.get(value, 'endDate')
    if (start) {
      startDate = start.format('DD/MM/YYYY H:mm')
    }
    if (end) {
      endDate = end.format('DD/MM/YYYY H:mm')
    }

    return `${startDate ? `start - ${startDate}` : ''}
      ${startDate && endDate ? ',' : ''}
      ${endDate ? `end - ${endDate}` : ''}`
  }
  return value
}

export default breadcrumbFactory

import React, { useState, useEffect } from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
import { TransitionMotion, spring } from 'react-motion'
import { withRouter } from 'react-router-dom'
import queryString from 'query-string'

import Modal from '../omg-modal'
import { Icon, Button } from '../omg-uikit'

import FilterPicker from './FilterPicker'
import { FILTER_MAP } from './FilterMap'

_.templateSettings.interpolate = /{{([\s\S]+?)}}/g

const AdvancedFilterContainer = styled.div`
  width: 100vw;
  height: 100vh;
  position: relative;
  > i {
    position: absolute;
    right: 30px;
    top: 30px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
    font-size: 30px;
  }
  display: flex;
  flex-direction: column;
  align-items: center;
`
const Content = styled.div`
  width: 400px;
  height: 100%;
`
const Title = styled.h3`
  margin-top: 100px;
  margin-left: 20px;
`
const FilterList = styled.div`
  display: flex;
  flex-direction: column;
`
const StyledButton = styled(Button)`
  margin: 20px;
`
const FilterPickerWrapper = styled.div`
  margin-left: 20px;
`
const Tags = styled.div`
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  .tag {
    border-radius: 4px;
    display: flex;
    flex-direction: row;
    align-items: center;
    padding: 3px 7px;
    margin-right: 10px;
    margin-bottom: 10px;
    background-color: ${props => props.theme.colors.S200};
    color: ${props => props.theme.colors.S500};
    i {
      cursor: pointer;
      padding-left: 10px;
      color: ${props => props.theme.colors.S500};
    }
  }
`

const AdvancedFilter = ({
  open,
  onRequestClose,
  title,
  page,
  onFilter,
  location,
  history,
  showTags = true
}) => {
  const [ filters, setFilters ] = useState([])
  const [ values, setValues ] = useState({})
  const [ initialValues, setInitialValues ] = useState({})

  useEffect(() => {
    const defaultFilters = FILTER_MAP.filter(i => {
      return i.page === page && i.default
    })
    setFilters(defaultFilters)
    setInitialValues({})
  }, [])

  const onSelectFilter = (newFilter) => {
    setFilters([newFilter, ...filters])
  }

  const onUpdate = (updated) => {
    setValues({
      ...values,
      ...updated
    })
  }

  const clearKey = (key) => {
    setValues(_.omit(values, [key]))
  }

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
              _matchAll.push({
                ...filter,
                value: compiledValue
              })
            } catch (e) {
              //
            }
          } else {
            if (Array.isArray(value)) {
              value.forEach(i => {
                _matchAll.push({
                  ...filter,
                  value: i
                })
              })
            } else {
              _matchAll.push({
                ...filter,
                value
              })
            }
          }
        })
      }

      if (matchAny) {
        if (Array.isArray(value)) {
          value.forEach(i => {
            matchAny.forEach(filter => {
              if (i.hasOwnProperty('value')) {
                _matchAny.push({ ...filter, value: i.value })
              } else {
                _matchAny.push({ ...filter, value: i })
              }
            })
          })
        } else {
          matchAny.forEach(filter => {
            _matchAny.push({ ...filter, value })
          })
        }
      }
    })

    return { matchAll: _matchAll, matchAny: _matchAny }
  }

  const resetPage = () => {
    const search = queryString.parse(location.search)
    delete search['page']
    history.push({ search: queryString.stringify(search) })
  }

  const onRemoveFilter = (filterToRemove) => {
    const newFilters = _.filter(filters, i => i.key !== filterToRemove.key)
    const newValues = _.omit(values, [filterToRemove.key])
    setFilters(newFilters)
    setValues(newValues)

    onFilter(filterAdapter(newValues))
    setInitialValues(newValues)
  }

  const applyFilter = () => {
    resetPage()
    onFilter(filterAdapter(values))
    setInitialValues(values)
    onRequestClose()
  }

  const removeAndApply = (tag) => {
    const newFilters = _.filter(filters, i => i.key !== tag)
    const newValues = _.omit(values, [tag])
    setFilters(newFilters)
    setValues(newValues)
    resetPage()

    onFilter(filterAdapter(newValues))
    setInitialValues(newValues)
    onRequestClose()
  }

  const onClose = () => {
    if (!_.isEqual(initialValues, values)) {
      setValues(initialValues)
    }
    onRequestClose()
  }

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
  }

  const springConfig = { stiffness: 200, damping: 20 }
  return (
    <>
      {showTags && (
        <Tags>
          {Object.keys(values).map(i => {
            const value = breadcrumbFactory(values[i])
            const configFilter = _.find(FILTER_MAP, ['key', i])
            return (
              <div className='tag' key={i}>
                {`${configFilter.title}: ${value}`}
                <Icon
                  name='Close'
                  onClick={() => removeAndApply(i)}
                />
              </div>
            )
          })}
        </Tags>
      )}

      <Modal
        isOpen={open}
        onRequestClose={onClose}
        contentLabel='advanced-filter-modal'
        shouldCloseOnOverlayClick={false}
        overlayClassName='dummy'
      >
        <AdvancedFilterContainer>
          <Icon name='Close' onClick={onClose} />
          <Content>
            <Title>{title}</Title>
            <TransitionMotion
              willEnter={() => ({ height: 0 })}
              willLeave={() => ({ height: spring(0, springConfig) })}
              styles={
                filters.map(filter => {
                  return {
                    key: filter.key,
                    data: filter,
                    style: { height: spring(filter.height + 10, springConfig) }
                  }
                })
              }
            >
              {interpolated => (
                <FilterList>
                  <FilterPickerWrapper
                    style={{ zIndex: interpolated.length + 1 }}
                  >
                    <FilterPicker
                      page={page}
                      onSelect={onSelectFilter}
                      selectedFilters={filters}
                    />
                  </FilterPickerWrapper>

                  {interpolated.map((item, index) => {
                    return (
                      <div
                        key={item.key}
                        style={{
                          zIndex: interpolated.length - index,
                          overflow: `${item.style.height < item.data.height ? 'hidden' : 'initial'}`,
                          height: `${item.style.height}px`
                        }}
                      >
                        {React.createElement(
                          item.data.component,
                          {
                            onUpdate,
                            clearKey,
                            onRemove: () => onRemoveFilter(item.data),
                            values,
                            config: item.data
                          },
                          null
                        )}
                      </div>
                    )
                  })}
                </FilterList>
              )}
            </TransitionMotion>

            <StyledButton
              onClick={applyFilter}
              disabled={_.isEqual(initialValues, values)}
            >
              <span>Apply Filter</span>
            </StyledButton>
          </Content>
        </AdvancedFilterContainer>
      </Modal>
    </>
  )
}

AdvancedFilter.propTypes = {
  open: PropTypes.bool.isRequired,
  onRequestClose: PropTypes.func.isRequired,
  onFilter: PropTypes.func.isRequired,
  page: PropTypes.string,
  title: PropTypes.string.isRequired,
  location: PropTypes.object,
  history: PropTypes.object,
  showTags: PropTypes.bool
}

export default withRouter(AdvancedFilter)

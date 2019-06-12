import React, { useState, useEffect } from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { TransitionMotion, spring } from 'react-motion'
import { withRouter } from 'react-router-dom'
import { compose } from 'recompose'

import Modal from '../omg-modal'
import { Icon, Button } from '../omg-uikit'

import FilterPicker from './FilterPicker'
import { FILTER_MAP } from './FilterMap'

const AdvancedFilterModalContainer = styled.div`
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

const AdvancedFilterModal = ({
  open,
  onRequestClose,
  title,
  page,
  onFilter,
  location
}) => {
  const [ filters, setFilters ] = useState([])
  const [ values, setValues ] = useState({})
  const [ initialValues, setInitialValues ] = useState({})

  useEffect(() => {
    const defaultFilters = FILTER_MAP.filter(i => {
      return i.page === page && i.default
    })
    setFilters(defaultFilters)

    // TODO: setInitialValues if passed in...
    setInitialValues({})
  }, [])

  const onSelectFilter = (newFilter) => {
    setFilters([newFilter, ...filters])
  }

  const onRemoveFilter = (filterToRemove) => {
    const newFilters = _.filter(filters, i => i.key !== filterToRemove.key)
    setFilters(newFilters)
    setValues(_.omit(values, [filterToRemove.key]))
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
          _matchAll.push({
            ...filter,
            value
          })
        })
      }

      if (matchAny) {
        matchAny.forEach(filter => {
          _matchAny.push({
            ...filter,
            value
          })
        })
      }
    })

    return { matchAll: _matchAll, matchAny: _matchAny }
  }

  const applyFilter = () => {
    onFilter(filterAdapter(values))
    setInitialValues(values)
    onRequestClose()
  }

  const springConfig = { stiffness: 200, damping: 20 }
  return (
    <Modal
      isOpen={open}
      onRequestClose={onRequestClose}
      contentLabel='advanced-filter-modal'
      shouldCloseOnOverlayClick={false}
      overlayClassName='dummy'
    >
      <AdvancedFilterModalContainer>
        <Icon name='Close' onClick={onRequestClose} />
        <Content>
          <Title>{title}</Title>
          <TransitionMotion
            willEnter={() => ({ height: 0 })}
            willLeave={() => ({ height: spring(0, springConfig) })}
            styles={
              filters.map(filter => ({
                key: filter.key,
                data: filter,
                style: { height: spring(filter.height + 10, springConfig) }
              }))
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
      </AdvancedFilterModalContainer>
    </Modal>
  )
}

AdvancedFilterModal.propTypes = {
  open: PropTypes.bool.isRequired,
  onRequestClose: PropTypes.func.isRequired,
  onFilter: PropTypes.func.isRequired,
  page: PropTypes.oneOf(['transaction']),
  title: PropTypes.string.isRequired,
  location: PropTypes.object
}

const enhance = compose(
  withRouter,
  connect(
    null,
    {}
  )
)

export default enhance(AdvancedFilterModal)

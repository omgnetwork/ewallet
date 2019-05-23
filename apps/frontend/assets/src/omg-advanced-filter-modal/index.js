import React, { useState } from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { filter } from 'lodash'
import { TransitionMotion, spring } from 'react-motion'

import Modal from '../omg-modal'
import { Icon } from '../omg-uikit'

import FilterPicker from './FilterPicker'

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
`
const FilterList = styled.div`
  display: flex;
  flex-direction: column;
`

const AdvancedFilterModal = ({
  open,
  onRequestClose,
  title,
  page
}) => {
  const [ filters, setFilters ] = useState([])

  const onSelectFilter = (newFilter) => {
    setFilters([newFilter, ...filters])
  }

  const onRemoveFilter = (filterToRemove) => {
    const newFilters = filter(filters, i => i.code !== filterToRemove.code)
    setFilters(newFilters)
  }

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
          <FilterPicker
            page={page}
            onSelect={onSelectFilter}
            selectedFilters={filters}
          />

          <TransitionMotion
            willEnter={() => ({ height: 0 })}
            willLeave={() => ({ height: spring(0) })}
            styles={
              filters.map(filter => ({
                key: filter.code,
                data: filter,
                style: { height: spring(filter.height + 10) }
              }))
            }
          >
            {interpolated => (
              <FilterList>
                {interpolated.map(item => {
                  return (
                    <div
                      key={item.key}
                      style={{
                        overflow: 'hidden',
                        // marginBottom: `${item.style.height / item.data.height * 10}px`,
                        height: `${item.style.height}px`
                      }}
                    >
                      {item.data.component({
                        onRemove: () => onRemoveFilter(item.data)
                      })}
                    </div>
                  )
                })}
              </FilterList>
            )}
          </TransitionMotion>

          {/* {filters.map(filter => {
            return filter.component && filter.component({
              onRemove: () => onRemoveFilter(filter)
            })
          })} */}
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
  title: PropTypes.string.isRequired
}

const enhance = connect(
  null,
  {}
)

export default enhance(AdvancedFilterModal)

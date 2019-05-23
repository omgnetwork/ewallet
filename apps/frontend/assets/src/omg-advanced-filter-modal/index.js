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
                key: filter.code,
                data: filter,
                style: { height: spring(filter.height + 10, springConfig) }
              }))
            }
          >
            {interpolated => (
              <FilterList>
                <FilterPicker
                  style={{ zIndex: interpolated.length + 1 }}
                  page={page}
                  onSelect={onSelectFilter}
                  selectedFilters={filters}
                />
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
                      {item.data.component({
                        onRemove: () => onRemoveFilter(item.data)
                      })}
                    </div>
                  )
                })}
              </FilterList>
            )}
          </TransitionMotion>
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

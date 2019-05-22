import React from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'

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

const AdvancedFilterModal = ({
  open,
  onRequestClose,
  title,
  page
}) => {
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
          <FilterPicker page={page} />
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

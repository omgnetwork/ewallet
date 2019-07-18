import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import Modal from '../omg-modal'
import { Icon } from '../omg-uikit'

const FullpageModalContainer = styled.div`
  width: 100vw;
  height: 100vh;
  position: relative;
  padding: 30px;
  i[name='Close'] {
    position: absolute;
    right: 30px;
    top: 30px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
    font-size: 30px;
  }
`
function FullPageModal ({ isOpen, onRequestClose, children }) {
  return (
    <Modal
      isOpen={isOpen}
      onRequestClose={onRequestClose}
      contentLabel='full page modal'
      overlayClassName='full-page-class-name'
    >
      <FullpageModalContainer>
        <Icon name='Close' onClick={onRequestClose} />
        {children}
      </FullpageModalContainer>
    </Modal>
  )
}

FullPageModal.propTypes = {
  isOpen: PropTypes.bool,
  onRequestClose: PropTypes.func,
  children: PropTypes.node
}

export default FullPageModal

import React, { PureComponent } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import Modal from 'react-modal'
import { Button, PlainButton } from '../omg-uikit'
const customStyles = {
  content: {
    top: '50%',
    left: '50%',
    right: 'auto',
    bottom: 'auto',
    marginRight: '-50%',
    transform: 'translate(-50%, -50%)',
    border: 'none'
  },
  overlay: {
    backgroundColor: 'rgba(0,0,0,0.5)'
  }
}
const ContentContainer = styled.div`
  padding: 40px;
`
const ConfirmationModalContainer = styled.div`
  position: relative;
`
const ButtonsContainer = styled.div`
  text-align: right;
  button {
    :not(:last-child) {
      margin-right: 15px;
    }
  }
`
class ConfirmationModal extends PureComponent {
  static propTypes = {
    children: PropTypes.node,
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    onOk: PropTypes.func
  }

  render () {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onRequestClose}
        style={customStyles}
        contentLabel='confirmation modal'
        shouldCloseOnOverlayClick={false}
      >
        <ConfirmationModalContainer>
          <ContentContainer>{this.props.children}</ContentContainer>
          <ButtonsContainer>
            <PlainButton onClick={this.props.onRequestClose}>Cancel</PlainButton>
            <Button styleType='primary' size='small' onClick={this.props.onOk}>
              Confirm
            </Button>
          </ButtonsContainer>
        </ConfirmationModalContainer>
      </Modal>
    )
  }
}

export default ConfirmationModal

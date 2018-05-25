import React, { PureComponent } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import Modal from 'react-modal'
import {Button} from '../omg-uikit'
const customStyles = {
  content: {
    top: '50%',
    left: '50%',
    right: 'auto',
    bottom: 'auto',
    marginRight: '-50%',
    transform: 'translate(-50%, -50%)',
    border: 'none',
    padding: '40px 30px 30px 30px'
  },
  overlay: {
    backgroundColor: 'rgba(0,0,0,0.5)'
  }
}
const ConfirmationModalContainer = styled.div`
  position: relative;
`
const ButtonsContainer = styled.div`
  padding-top: 25px;
  margin-top: 20px;
  border-top: 1px solid ${props => props.theme.colors.S400};
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
          {this.props.children}
          <ButtonsContainer>
            <Button styleType='secondary' size='small' onClick={this.props.onRequestClose}>Cancel</Button>
            <Button styleType='primary' size='small' onClick={this.props.onOk}>Confirm</Button>
          </ButtonsContainer>
        </ConfirmationModalContainer>
      </Modal>
    )
  }
}

export default ConfirmationModal

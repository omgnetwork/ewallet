import React, { PureComponent } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import Modal from '../omg-modal'
import { Button, PlainButton } from '../omg-uikit'

const ContentContainer = styled.div`
`
const ConfirmationModalContainer = styled.div`
  position: relative;
  padding: 40px;
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
    onOk: PropTypes.func,
    cancel: PropTypes.bool,
    confirmText: PropTypes.string,
    loading: PropTypes.bool
  }
  static defaultProps = {
    cancel: true
  }

  render () {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onRequestClose}
        contentLabel='confirmation modal'
        shouldCloseOnOverlayClick={false}
        closeTimeoutMS={300}
        className='react-modal'
        overlayClassName='react-modal-overlay'
        {...this.props}
      >
        <ConfirmationModalContainer>
          <ContentContainer>{this.props.children}</ContentContainer>
          <ButtonsContainer>
            {this.props.cancel && <PlainButton onClick={this.props.onRequestClose}>Cancel</PlainButton>}
            <Button styleType='primary' size='small' onClick={this.props.onOk} loading={this.props.loading}>
              {this.props.confirmText || 'Confirm' }
            </Button>
          </ButtonsContainer>
        </ConfirmationModalContainer>
      </Modal>
    )
  }
}

export default ConfirmationModal

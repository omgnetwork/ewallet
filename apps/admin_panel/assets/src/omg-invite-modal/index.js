import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { RadioButton, Input, Button, Icon } from '../omg-uikit'
import Modal from 'react-modal'
const customStyles = {
  content: {
    top: '50%',
    left: '50%',
    right: 'auto',
    bottom: 'auto',
    marginRight: '-50%',
    transform: 'translate(-50%, -50%)',
    border: 'none',
    padding: 0
  },
  overlay: {
    backgroundColor: 'rgba(0,0,0,0.5)'
  }
}
const InviteModalContainer = styled.form`
  padding: 50px;
  width: 400px;
  text-align: center;
  position: relative;
  > i {
    position: absolute;
    right: 15px;
    top: 15px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
  }
  h4 {
    margin-bottom: 35px;
  }
  > button {
    margin-top: 35px;
  }
`
const RadioButtonsContainer = styled.div`
  flex: 0 1 auto;
  margin-left: auto;
  display: flex;
  > div:first-child {
    margin-right: 15px;
  }
`
const RoleRadioButtonContainer = styled.div`
  display: flex;
  margin-top: 35px;
  > h5 {
    flex: 1 1 auto;
    text-align: left;
  }
`
const InviteTitle = styled.span`
  font-size: 14px;
  color: ${props => props.theme.colors.B100};
`
const InviteButton = styled(Button)`
  padding-left: 40px;
  padding-right: 40px;
`
export default class InviteModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func
  }

  render () {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onRequestClose}
        style={customStyles}
        contentLabel='invite modal'
        shouldCloseOnOverlayClick={false}
      >
        <InviteModalContainer>
          <Icon name='Close' onClick={this.props.onRequestClose} />
          <h4>Invite Member</h4>
          <Input autoFocus placeholder='Email' />
          <RoleRadioButtonContainer>
            <InviteTitle>Select Role</InviteTitle>
            <RadioButtonsContainer>
              <RadioButton label='Admin' checked />
              <RadioButton label='Member' />
            </RadioButtonsContainer>
          </RoleRadioButtonContainer>
          <InviteButton styleType='primary' type='submit'>Invite</InviteButton>
        </InviteModalContainer>
      </Modal>
    )
  }
}

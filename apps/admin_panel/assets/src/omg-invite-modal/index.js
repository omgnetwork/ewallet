import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { RadioButton, Input, Button, Icon } from '../omg-uikit'
import Modal from '../omg-modal'
import { connect } from 'react-redux'
import { inviteMember, getListMembers } from '../omg-member/action'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'

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
const enhance = compose(
  withRouter,
  connect(
    null,
    { inviteMember, getListMembers }
  )
)
class InviteModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    inviteMember: PropTypes.func.isRequired,
    getListMembers: PropTypes.func.isRequired,
    match: PropTypes.object,
    location: PropTypes.object
  }
  state = {
    email: '',
    role: 'viewer',
    submitStatus: ''
  }
  validateEmail = email => {
    return /@/.test(email)
  }
  reset = () => {
    this.setState({
      email: '',
      role: 'viewer',
      submitStatus: ''
    })
  }
  onRequestClose = () => {
    this.props.onRequestClose()
    this.reset()
  }
  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitStatus: 'ATTEMPT_TO_SUBMIT' })
    if (this.validateEmail(this.state.email)) {
      this.setState({ submitStatus: 'SUBMITTED' })
      try {
        const accountId = this.props.match.params.accountId
        const result = await this.props.inviteMember({
          email: this.state.email,
          role: this.state.role,
          accountId,
          redirectUrl: window.location.href.replace(this.props.location.pathname, '/invite/')
        })
        if (result.data) {
          this.props.getListMembers(accountId)
          this.setState({ submitStatus: 'SUCCESS' })
          this.props.history.push(`/accounts/${this.props.match.params.accountId}/admins`)
          this.onRequestClose()
        } else {
          this.setState({ submitStatus: 'FAILED' })
        }
      } catch (error) {
        this.setState({ submitStatus: 'FAILED' })
      }
    }
  }

  onInputEmailChange = e => {
    this.setState({
      email: e.target.value
    })
  }
  onClickRadioButton = role => e => {
    this.setState({ role })
  }

  render () {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.onRequestClose}
        contentLabel='invite modal'
        shouldCloseOnOverlayClick={false}
      >
        <InviteModalContainer onSubmit={this.onSubmit}>
          <Icon name='Close' onClick={this.props.onRequestClose} />
          <h4>Invite Member</h4>
          <Input
            autoFocus
            placeholder='Email'
            onChange={this.onInputEmailChange}
            value={this.state.email}
            error={
              this.state.submitStatus === 'ATTEMPT_TO_SUBMIT' &&
              !this.validateEmail(this.state.email)
            }
            errorText='Email is not valid'
          />
          <RoleRadioButtonContainer>
            <InviteTitle>Select Role</InviteTitle>
            <RadioButtonsContainer>
              <RadioButton
                label='Admin'
                checked={this.state.role === 'admin'}
                onClick={this.onClickRadioButton('admin')}
              />
              <RadioButton
                label='Viewer'
                checked={this.state.role === 'viewer'}
                onClick={this.onClickRadioButton('viewer')}
              />
            </RadioButtonsContainer>
          </RoleRadioButtonContainer>
          <InviteButton
            styleType='primary'
            type='submit'
            loading={this.state.submitStatus === 'SUBMITTED'}
          >
            Invite
          </InviteButton>
        </InviteModalContainer>
      </Modal>
    )
  }
}
export default enhance(InviteModal)

import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { RadioButton, Input, Button, Icon } from '../omg-uikit'
import Modal from '../omg-modal'
import { connect } from 'react-redux'
import { inviteMember, getListMembers } from '../omg-member/action'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'

const CreateAdminKeyModalContainer = styled.form`
  padding: 50px;
  width: 100vw;
  height: 100vh;
  text-align: left;
  position: relative;
  box-sizing: border-box;
  > i {
    position: absolute;
    right: 30px;
    top: 30px;
    font-size: 30px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
  }
  h4 {
    margin-bottom: 35px;
    text-align: center;
  }
  > button {
    margin-top: 35px;
  }
`
const InviteButton = styled(Button)`
  padding-left: 40px;
  padding-right: 40px;
`
const CreateAdminKeyFormContainer = styled.form`
  position: absolute;
  top: 50%;
  transform:translateY(-50%);
  left: 0;
  right: 0;
  margin: 0 auto;
  width: 600px;
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
        overlayClassName='dummy'
      >
        <CreateAdminKeyModalContainer onSubmit={this.onSubmit}>
          <Icon name='Close' onClick={this.props.onRequestClose} />
          <CreateAdminKeyFormContainer>
            <h4>Invite Member</h4>
            <div>Label</div>
            <Input
              autoFocus
              normalPlaceholder='Email'
              onChange={this.onInputEmailChange}
              value={this.state.email}
              error={
              this.state.submitStatus === 'ATTEMPT_TO_SUBMIT' &&
              !this.validateEmail(this.state.email)
            }
              errorText='Email is not valid'
            />
            <div>Account</div>
            <Input
              autoFocus
              normalPlaceholder='Email'
              onChange={this.onInputEmailChange}
              value={this.state.email}
              error={
              this.state.submitStatus === 'ATTEMPT_TO_SUBMIT' &&
              !this.validateEmail(this.state.email)
            }
              errorText='Email is not valid'
            />
            <div>Assign Role</div>
            <Input
              autoFocus
              normalPlaceholder='Email'
              onChange={this.onInputEmailChange}
              value={this.state.email}
              error={
              this.state.submitStatus === 'ATTEMPT_TO_SUBMIT' &&
              !this.validateEmail(this.state.email)
            }
              errorText='Email is not valid'
            />
            <InviteButton
              styleType='primary'
              type='submit'
              loading={this.state.submitStatus === 'SUBMITTED'}
            >
            Invite
          </InviteButton>
          </CreateAdminKeyFormContainer>
        </CreateAdminKeyModalContainer>
      </Modal>
    )
  }
}
export default enhance(InviteModal)

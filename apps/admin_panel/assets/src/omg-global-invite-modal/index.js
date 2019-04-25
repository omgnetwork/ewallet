import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'

import { Input, Button, Icon, Select } from '../omg-uikit'
import Modal from '../omg-modal'
import { inviteAdmin, getAdmins } from '../omg-admins/action'

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
`
const StyledInput = styled(Input)`
  margin-bottom: 20px;
`
const InputLabel = styled.div`
  text-align: left;
  margin-bottom: 5px;
`
const StyledSelect = styled(Select)`
  margin-bottom: 40px;
  text-align: left;
`

const enhance = compose(
  withRouter,
  connect(
    null,
    { inviteAdmin, getAdmins }
  )
)
class GlobalInviteModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    inviteAdmin: PropTypes.func.isRequired,
    location: PropTypes.object,
    onInviteSuccess: PropTypes.func
  }
  state = {
    email: '',
    globalRole: 'none',
    submitStatus: ''
  }
  validateEmail = email => {
    return /@/.test(email)
  }
  reset = () => {
    this.setState({
      email: '',
      globalRole: 'none',
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
        const result = await this.props.inviteAdmin({
          email: this.state.email,
          globalRole: this.state.globalRole,
          redirectUrl: window.location.href.replace(this.props.location.pathname, '/invite/')
        })
        if (result.data) {
          this.setState({ submitStatus: 'SUCCESS' })
          if (this.props.onInviteSuccess) this.props.onInviteSuccess()
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
  onSelectRole = role => {
    this.setState({
      globalRole: role
    })
  }
  render () {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.onRequestClose}
        contentLabel='invite modal'
        shouldCloseOnOverlayClick
      >
        <InviteModalContainer onSubmit={this.onSubmit}>
          <Icon name='Close' onClick={this.props.onRequestClose} />
          <h4>Invite Admin</h4>
          <InputLabel>Email</InputLabel>
          <StyledInput
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
          <InputLabel>Global Role</InputLabel>
          <StyledSelect
            normalPlaceholder='Role ( optional )'
            value={_.startCase(this.state.globalRole)}
            onSelectItem={item => this.onSelectRole(item.key)}
            options={[
              { key: 'super_admin', value: 'Super Admin' },
              { key: 'admin', value: 'Admin' },
              { key: 'viewer', value: 'Viewer' },
              { key: 'none', value: 'None' }
            ]}
            optionRenderer={value => _.startCase(value)}
          />
          <Button
            styleType='primary'
            type='submit'
            loading={this.state.submitStatus === 'SUBMITTED'}
          >
            <span>Invite</span>
          </Button>
        </InviteModalContainer>
      </Modal>
    )
  }
}
export default enhance(GlobalInviteModal)

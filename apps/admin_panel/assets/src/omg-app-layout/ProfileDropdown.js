import React, { Component } from 'react'
import PropTypes from 'prop-types'
import withDropdownState from '../omg-uikit/dropdown/withDropdownState'
import { DropdownBox } from '../omg-uikit/dropdown'
import { Icon } from '../omg-uikit'
import styled from 'styled-components'
import { compose } from 'recompose'
import CurrentUserProvider from '../omg-user-current/currentUserProvider'
import { withRouter } from 'react-router-dom'
import { connect } from 'react-redux'
import { logout } from '../omg-session/action'
import PopperRenderer from '../omg-popper'
const AvatarDropdownContainer = styled.div`
  position: relative;
  cursor: pointer;
`
const DropdownItem = styled.div`
  padding: 10px;
  padding-right: 60px;
  i,
  span {
    vertical-align: middle;
    display: inline-block;
  }
  i {
    margin-right: 10px;
  }
`
const DropdownItemEmail = DropdownItem.extend`
  padding-top: 0;
  color: ${props => props.theme.colors.B100};
`
const DropdownItemName = DropdownItem.extend`
  color: ${props => props.theme.colors.B400};
  font-weight: 600;
  font-size: 20px;
  padding-bottom: 0;
`
const DropdownItemProfile = DropdownItem.extend`
  cursor: pointer;
  border-bottom: 1px solid ${props => props.theme.colors.S400};
  :hover {
    background-color: ${props => props.theme.colors.S200};
  }
`
const DropdownItemLogout = DropdownItem.extend`
  cursor: pointer;
  :hover {
    background-color: ${props => props.theme.colors.S200};
  }
`
const DropdownBoxStyled = DropdownBox.extend`
  width: auto;
  text-align: left;
`

const CurrentUserName = styled.div`
  font-weight: 600;
  font-size: 16px;
  i {
    color: ${props => props.theme.colors.B100};
    font-size: 14px;
  }
`

const enhance = compose(
  withDropdownState,
  withRouter,
  connect(
    null,
    { logout }
  )
)
class ProfileAvatarDropdown extends Component {
  static propTypes = {
    onClickButton: PropTypes.func,
    open: PropTypes.bool,
    closeDropdown: PropTypes.func,
    match: PropTypes.object,
    history: PropTypes.object,
    logout: PropTypes.func
  }
  onClickProfile = e => {
    const accountId = this.props.match.params.accountId
    this.props.closeDropdown()
    this.props.history.push('/user_setting')
  }
  onClickLogout = async e => {
    await this.props.logout()
    this.props.history.push('/login')
  }

  renderCurrentUserName = currentUser => () => {
    return (
      <CurrentUserName onClick={this.props.onClickButton}>
        {currentUser.name || currentUser.email}{' '}
        {this.props.open ? <Icon name='Chevron-Up' /> : <Icon name='Chevron-Down' />}
      </CurrentUserName>
    )
  }
  renderCurrentUserAvatar = ({ currentUser, loadingStatus }) => {
    return (
      <AvatarDropdownContainer>
        <PopperRenderer
          renderReference={this.renderCurrentUserName(currentUser)}
          open={this.props.open}
          renderPopper={() => {
            return (
              <DropdownBoxStyled>
                <DropdownItemName>{currentUser.name || currentUser.email}</DropdownItemName>
                <DropdownItemEmail>{currentUser.email}</DropdownItemEmail>
                <DropdownItemProfile onClick={this.onClickProfile}>
                  <Icon name='Profile' />
                  <span>Profile</span>
                </DropdownItemProfile>
                <DropdownItemLogout onClick={this.onClickLogout}>
                  <Icon name='Arrow-Left' />
                  <span>Logout</span>
                </DropdownItemLogout>
              </DropdownBoxStyled>
            )
          }}
        />
      </AvatarDropdownContainer>
    )
  }
  render () {
    return <CurrentUserProvider render={this.renderCurrentUserAvatar} {...this.props} />
  }
}

export default enhance(ProfileAvatarDropdown)

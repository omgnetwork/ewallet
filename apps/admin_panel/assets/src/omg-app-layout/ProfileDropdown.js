import React, { Component } from 'react'
import PropTypes from 'prop-types'
import withDropdownState from '../omg-uikit/dropdown/withDropdownState'
import { DropdownBox } from '../omg-uikit/dropdown'
import { Avatar, Icon } from '../omg-uikit'
import styled from 'styled-components'
import { compose } from 'recompose'
import CurrentUserProvider from '../omg-user-current/currentUserProvider'
import { Link, withRouter } from 'react-router-dom'
const AvatarDropdownContainer = styled.div`
  position: relative;
`
const StyledAvatar = styled(Avatar)`
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

const enhance = compose(withDropdownState, withRouter)
class ProfileAvatarDropdown extends Component {
  static propTypes = {
    onClickButton: PropTypes.func,
    open: PropTypes.bool,
    closeDropdown: PropTypes.func,
    match: PropTypes.object,
    history: PropTypes.object
  }
  onClickProfile = e => {
    const accountId = this.props.match.params.accountId
    this.props.closeDropdown()
    this.props.history.push(`/${accountId}/user_setting`)
  }
  onClickLogout = e => {
    this.props.history.push(`/login`)
  }

  renderAvatar = () => {
    return <StyledAvatar onClick={this.props.onClickButton} />
  }
  renderCurrentUserAvatar = ({ currentUser, loadingStatus }) => {
    return (
      <AvatarDropdownContainer>
        {this.renderAvatar()}
        {this.props.open && (
          <DropdownBoxStyled>
            <div>
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
            </div>
          </DropdownBoxStyled>
        )}
      </AvatarDropdownContainer>
    )
  }
  render () {
    return <CurrentUserProvider render={this.renderCurrentUserAvatar} {...this.props} />
  }
}

export default enhance(ProfileAvatarDropdown)

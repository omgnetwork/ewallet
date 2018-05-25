import React, { Component } from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
const AccountItemLogo = styled.div`
  border-radius: 50%;
  width: 33px;
  height: 33px;
  margin-right: 15px;
  margin-top: 15px;
  background-color: ${props => props.theme.colors.B300};
  background-image: url(${props => props.backgroundImage});
  background-size: cover;
  background-position: center;
  border: 3px solid ${props => props.active ? props.theme.colors.B100 : props.theme.colors.B300};
  transition: 0.25s;
`
const AccountItemContainer = styled.div`
  width: 100%;
  display: flex;
  color: white;
  cursor: pointer;
  :hover > ${AccountItemLogo} {
    border: 3px solid ${props => props.theme.colors.B100};
  }
`
const AccountItemContent = styled.div`
  padding: 15px 0;
  border-bottom: 1px solid ${props => props.theme.colors.B300};
  flex: 1 1 auto;
`
const AccountName = styled.div`
  margin-bottom: 8px;
`
const AccountDescription = styled.div`
  color: ${props => props.theme.colors.B100};
`

class AccountItem extends Component {
  static propTypes = {
    name: PropTypes.string,
    description: PropTypes.string,
    thumbnail: PropTypes.string,
    active: PropTypes.bool,
    onClick: PropTypes.func
  }
  render () {
    return (
      <AccountItemContainer onClick={this.props.onClick}>
        <AccountItemLogo active={this.props.active} backgroundImage={this.props.thumbnail} />
        <AccountItemContent>
          <AccountName>{this.props.name}</AccountName>
          <AccountDescription>{this.props.description}</AccountDescription>
        </AccountItemContent>
      </AccountItemContainer>
    )
  }
}

export default AccountItem

import React, { Component } from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
const AccountItemLogo = styled.div`
  width: 32px;
  height: 32px;
  margin-right: 15px;
  margin-top: 15px;
  background-color: ${props => props.theme.colors.B300};
  background-image: url(${props => props.backgroundImage});
  background-size: cover;
  background-position: center;
  border: 2px solid ${props => props.active ? props.theme.colors.BL400 : props.theme.colors.B300};
  border-radius: 4px;
  transition: 0.25s;
  text-align: center;
  line-height: 30px;
`
const AccountItemContainer = styled.div`
  width: 100%;
  display: flex;
  color: white;
  cursor: pointer;
  :hover > ${AccountItemLogo} {
    border: 2px solid ${props => props.theme.colors.BL400};
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
        <AccountItemLogo active={this.props.active} backgroundImage={this.props.thumbnail}>
          { !this.props.thumbnail && this.props.name.slice(0, 2)}
        </AccountItemLogo>
        <AccountItemContent>
          <AccountName>{this.props.name}</AccountName>
          <AccountDescription>{this.props.description}</AccountDescription>
        </AccountItemContent>
      </AccountItemContainer>
    )
  }
}

export default AccountItem

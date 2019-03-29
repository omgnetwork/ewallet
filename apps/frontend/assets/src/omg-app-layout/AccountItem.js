import React, { Component } from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
import {Avatar} from '../omg-uikit'
const AccountItemLogo = styled(Avatar)`
  width: 32px;
  height: 32px;
  margin-right: 15px;
  margin-top: 15px;
  background-color: ${props => props.theme.colors.B300};
  border: 1px solid ${props => props.active ? props.theme.colors.BL400 : props.theme.colors.B300};
  color: white;
  border-radius: 4px;
  transition: 0.25s;
  line-height: 31px;
`
const AccountItemContainer = styled.div`
  width: 100%;
  display: flex;
  color: white;
  cursor: pointer;
  :hover > ${AccountItemLogo} {
    border: 1px solid ${props => props.theme.colors.BL400};
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
        <AccountItemLogo name={!this.props.thumbnail && this.props.name.slice(0, 2)} active={this.props.active} image={this.props.thumbnail} />
        <AccountItemContent>
          <AccountName>{this.props.name}</AccountName>
          <AccountDescription>{this.props.description}</AccountDescription>
        </AccountItemContent>
      </AccountItemContainer>
    )
  }
}

export default AccountItem

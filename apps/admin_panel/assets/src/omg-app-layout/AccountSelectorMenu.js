import React, { Component } from 'react'
import styled from 'styled-components'
import AccountItem from './AccountItem'
import PropTypes from 'prop-types'
import { withRouter } from 'react-router-dom'
import { Input, Icon } from '../omg-uikit'
const Container = styled.div`
  background-color: ${props => props.theme.colors.B400};
  padding: 40px 35px;
  display: flex;
  flex-direction: column;
  position: absolute;
  left: 220px;
  height: 100%;
  width: 300px;
  top: 0;
  bottom: 0;
  z-index: 1;
`
const InputSearch = styled(Input)`
  color: ${props => props.theme.colors.B100};
  margin-left: 25px;
  flex: 1 1 auto;
  input {
    border-bottom: 1px solid ${props => props.theme.colors.B300};
    color: white;
  }
`
const SearchContainer = styled.div`
  display: flex;
  align-items: flex-end;
  margin-bottom: 30px;
  i {
    color: ${props => props.theme.colors.B100};
    font-size: 24px;
    flex: 1 1 auto;
  }
`
const AccountsContainer = styled.div`
  overflow: auto;
  height: 100%;
`
class AccountSelectorMenu extends Component {
  static propTypes = {
    accounts: PropTypes.array.isRequired,
    onClickAccountItem: PropTypes.func,
    location: PropTypes.object,
    onKeyDown: PropTypes.func
  }
  state = {
    searchValue: ''
  }
  onSearchChange = e => {
    this.setState({ searchValue: e.target.value })
  }

  render () {
    return (
      <Container {...this.props} onKeyDown={this.props.onKeyDown}>
        <SearchContainer>
          <Icon name='Search' />
          <InputSearch autoFocus onChange={this.onSearchChange} value={this.state.searchValue} />
        </SearchContainer>
        <AccountsContainer>
          {this.props.accounts
          .filter(account => {
            const seachText = this.state.searchValue
            const reg = new RegExp(seachText)
            return seachText ? (reg.test(account.name) || reg.test(account.description)) : true
          })
          .map(account => (
            <AccountItem
              key={account.name}
              name={account.name}
              description={account.description}
              thumbnail={account.avatar.small}
              onClick={this.props.onClickAccountItem(account)}
              active={this.props.location.pathname.split('/')[1] === account.id}
            />
          ))}
        </AccountsContainer>
      </Container>
    )
  }
}
export default withRouter(AccountSelectorMenu)

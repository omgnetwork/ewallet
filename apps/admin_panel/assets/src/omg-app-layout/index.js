import React, { Component } from 'react'
import styled from 'styled-components'
import SideNavigation from './SideNavigation'
import TopBar from './TopBar'
import PropTypes from 'prop-types'
import AccountSelectorMenu from './AccountSelectorMenu'
import withClickOutsideEnhancer from '../enhancer/clickOutside'
import { compose } from 'recompose'
import AccountsFetcher from '../omg-account/accountsFetcher'
import { connect } from 'react-redux'
import { withRouter } from 'react-router-dom'
import { switchAccount } from '../omg-account-current/action'
import Alert from '../omg-alert'
import LoadingBar from 'react-redux-loading-bar'
import TransactionRequestPanel from '../omg-transaction-request-tab'
import queryString from 'query-string'
const Container = styled.div`
  height: 100%;
  position: relative;
  display: flex;
`
const SideNav = styled(SideNavigation)`
  display: inline-block;
  vertical-align: top;
  flex: 0 0 auto;
  max-width : 240px;
`

const ContentContainer = styled.div`
  display: inline-block;
  width: calc(100% - 220px);
  height: 100vh;
  overflow: auto;
`
const Content = styled.div`
  padding: 0 7%;
`
const enhance = compose(
  connect(
    null,
    { switchAccount }
  ),
  withRouter,
  withClickOutsideEnhancer
)
const EnhancedAccountSelectorMenuClickOutside = enhance(
  class extends Component {
    static propTypes = {
      closeSwitchAccountTab: PropTypes.func,
      location: PropTypes.object,
      history: PropTypes.object,
      switchAccount: PropTypes.func
    }
    state = {
      searchValue: ''
    }
    handleClickOutside = () => {
      this.props.closeSwitchAccountTab()
    }
    onKeyDown = e => {
      if (e.keyCode === 27) this.props.closeSwitchAccountTab()
    }
    onClickAccountItem = account => e => {
      this.props.history.push(`/${account.id}/dashboard`)
      this.handleClickOutside()
      this.props.switchAccount(account)
    }

    onSearchChange = e => {
      this.setState({ searchValue: e.target.value })
    }

    render () {
      return (
        <AccountsFetcher
          query={{ search: this.state.searchValue, perPage: 20, page: 1 }}
          render={({ data: accounts }) => {
            return (
              <AccountSelectorMenu
                accounts={accounts}
                onClickAccountItem={this.onClickAccountItem}
                onKeyDown={this.onKeyDown}
                onSearchChange={this.onSearchChange}
                searchValue={this.state.searchValue}
              />
            )
          }}
        />
      )
    }
  }
)

class AppLayout extends Component {
  static propTypes = {
    children: PropTypes.node,
    location: PropTypes.object
  }
  state = {
    switchAccount: false
  }

  closeSwitchAccountTab = () => {
    this.setState({ switchAccount: false })
  }
  onClickSwitchAccount = () => {
    this.setState({ switchAccount: true })
  }
  scrollTopContentContainer = () => {
    this.contentContainer.scrollTo(0, 0)
  }
  render () {
    const searchObject = queryString.parse(this.props.location.search)
    return (
      <Container>
        <LoadingBar updateTime={300} style={{ backgroundColor: '#1A56F0', zIndex: 99999 }} />
        <SideNav
          switchAccount={this.state.switchAccount}
          onClickSwitchAccount={this.onClickSwitchAccount}
        />
        {this.state.switchAccount && (
          <EnhancedAccountSelectorMenuClickOutside
            closeSwitchAccountTab={this.closeSwitchAccountTab}
          />
        )}
        <ContentContainer innerRef={contentContainer => (this.contentContainer = contentContainer)}>
          <TopBar />
          <Content>
            {React.cloneElement(this.props.children, {
              scrollTopContentContainer: this.scrollTopContentContainer
            })}
          </Content>
        </ContentContainer>
        <Alert />
        {searchObject['show-request-tab'] && (
          <TransactionRequestPanel />
        )}
      </Container>
    )
  }
}

export default AppLayout

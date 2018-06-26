import React, { Component } from 'react'
import styled from 'styled-components'
import SideNavigation from './SideNavigation'
import TopBar from './TopBar'
import PropTypes from 'prop-types'
import AccountSelectorMenu from './AccountSelectorMenu'
import withClickOutsideEnhancer from '../enhancer/clickOutside'
import { compose } from 'recompose'
import AccountsProvider from '../omg-account/accountsProvider'
import { connect } from 'react-redux'
import { withRouter } from 'react-router-dom'
import { switchAccount } from '../omg-account-current/action'
import Alert from '../omg-alert'
import ReactDOM from 'react-dom'
import LoadingBar from 'react-redux-loading-bar'
const Container = styled.div`
  height: 100%;
  position: relative;
`
const SideNav = styled(SideNavigation)`
  display: inline-block;
  width: 220px;
  vertical-align: top;
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
    render () {
      return (
        <AccountsProvider
          render={({ accounts }) => {
            return (
              <AccountSelectorMenu
                accounts={accounts}
                onClickAccountItem={this.onClickAccountItem}
                onKeyDown={this.onKeyDown}
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
    children: PropTypes.node
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
    ReactDOM.findDOMNode(this.contentContainer).scrollTo(0, 0)
  }
  render () {
    return (
      <Container>
        <LoadingBar style={{ backgroundColor: '#1A56F0' }} />
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
      </Container>
    )
  }
}

export default AppLayout

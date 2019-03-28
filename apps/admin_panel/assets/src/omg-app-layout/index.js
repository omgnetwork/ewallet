import React, { Component } from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
import LoadingBar from 'react-redux-loading-bar'
import queryString from 'query-string'

import SlideInRight from '../omg-uikit/animation/SlideInRight'
import SideNavigation from './SideNavigation'
import Alert from '../omg-alert'
import TransactionRequestPanel from '../omg-transaction-request-tab'
import TransactionPanel from '../omg-transaction-panel'
import ActivityPanel from '../omg-page-activity-log/ActivityPanel'
import ConsumptionPanel from '../omg-consumption-panel'

const Container = styled.div`
  height: 100%;
  position: relative;
  display: flex;
`
const SideNav = styled(SideNavigation)`
  display: inline-block;
  vertical-align: top;
  flex: 0 0 auto;
  width: 220px;
`

const ContentContainer = styled.div`
  display: inline-block;
  width: calc(100% - 220px);
  height: 100vh;
  overflow: auto;
`
const Content = styled.div`
  padding: 0 7% 50px 7%;
  overflow: hidden;
`
class AppLayout extends Component {
  static propTypes = {
    children: PropTypes.node,
    location: PropTypes.object
  }

  scrollTopContentContainer = () => {
    this.contentContainer.scrollTo(0, 0)
  }
  render () {
    const searchObject = queryString.parse(this.props.location.search)
    return (
      <Container>
        <LoadingBar updateTime={1000} style={{ backgroundColor: '#1A56F0', zIndex: 99999 }} />
        <SideNav />
        <ContentContainer innerRef={contentContainer => (this.contentContainer = contentContainer)}>
          <Content>
            {React.cloneElement(this.props.children, {
              scrollTopContentContainer: this.scrollTopContentContainer
            })}
          </Content>
        </ContentContainer>
        <Alert />
        {searchObject['show-request-tab'] && <TransactionRequestPanel />}
        {searchObject['show-consumption-tab'] && <ConsumptionPanel />}

        <SlideInRight path='transaction-panel' width={560}>
          {searchObject['show-transaction-tab'] && <TransactionPanel />}
        </SlideInRight>

        {searchObject['show-activity-tab'] && <ActivityPanel />}
      </Container>
    )
  }
}

export default AppLayout

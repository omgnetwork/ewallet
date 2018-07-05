import React, { Component } from 'react'
import styled from 'styled-components'
import { Button, Icon } from '../omg-uikit'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import CurrentAccountProvider from '../omg-account-current/currentAccountProvider'
import moment from 'moment'
const SectionsContainer = styled.div`
  display: flex;
`
const SectionContainer = styled.div`
  flex: 1 1 auto;
  :first-child {
    width: 250px;
  }
  b {
    display: block;
  }
  >h5 {
    text-transform: uppercase;
    letter-spacing: 1px;
  }

`
const IntroContainer = styled.div`
  border-radius: 4px;
  background-color: rgba(219,233,255,0.8);
  box-shadow: 0 2px 10px 0 rgba(4,7,13,0.1);
  padding: 30px;
  h5 {
    text-transform: uppercase;
    letter-spacing: 1px;
    margin-bottom: 10px;
  }
  margin-bottom: 20px;
`
const NavigationItem = styled.div`
  margin-bottom: 15px;
  cursor: pointer;
  i {
    color: ${props => props.theme.colors.BL400};
    font-size: 16px;
    margin-right: 10px;
  }
`
const GetStartedContainer = styled.div`
  border: 1px solid #E4E7ED;
  padding: 30px;
  border-radius: 4px;
  background-color: #FFFFFF;
  box-shadow: 0 2px 5px 0 rgba(60,65,77,0.05);
  background-image: url(${require('../../statics/images/Main_dashboard-01.png')});
  background-size: 550px auto;
  background-repeat: no-repeat;
  background-position: top right;
  h4 {
    letter-spacing: 1px;
    margin-bottom: 30px;
  }
`
export default class Dashboard extends Component {
  renderExportButton = () => {
    return (
      <Button size='small' styleType='ghost' onClick={this.onClickExport} key={'export'}>
        <Icon name='Export' />
        <span>Export</span>
      </Button>
    )
  }
  renderCurrentAccountSection = ({ currentAccount }) => {
    return (
      <SectionContainer>
        <h5>Account Details</h5>
        <DetailGroup>
          <b>ID:</b> <span>{currentAccount.id || '...'}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Description:</b> <span>{currentAccount.description || '-'}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Category:</b> <span>{_.get(currentAccount, 'categories.data[0].name', '-')}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Account type:</b>{' '}
          <span>
            {currentAccount.master === true
                ? 'Master'
                : currentAccount.master === false
                  ? 'Child'
                  : '-'}
          </span>
        </DetailGroup>
        <DetailGroup>
          <b>Created Date:</b>{' '}
          <span>{moment(currentAccount.created_at).format('DD/MM/YYYY hh:mm:ss')}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Last Update:</b> <span>{moment(currentAccount.updated_at).format('DD/MM/YYYY hh:mm:ss')}</span>
        </DetailGroup>
      </SectionContainer>
    )
  }
  render () {
    return (
      <div>
        <TopNavigation
          title='Dashboard'
          types={false}
          secondaryAction={false}
        />
        <SectionsContainer>
          <CurrentAccountProvider render={this.renderCurrentAccountSection} />
          <SectionContainer>
            <IntroContainer>
              <h5>This is where you will see all stats and trend of transaction within current account.</h5>
              <p>Analytics will appear when we collect enough data.</p>
            </IntroContainer>
            <GetStartedContainer>
              <h4>Let's get started</h4>
              <NavigationItem><Icon name='Arrow-Right' /> Invite team member</NavigationItem>
              <NavigationItem><Icon name='Arrow-Right' /> Create Account</NavigationItem>
              <NavigationItem><Icon name='Arrow-Right' /> Create Token</NavigationItem>
              <NavigationItem><Icon name='Arrow-Right' /> Organize Wallets</NavigationItem>
              <NavigationItem><Icon name='Arrow-Right' /> Create Request</NavigationItem>
              <NavigationItem><Icon name='Arrow-Right' /> Generate API</NavigationItem>
            </GetStartedContainer>
          </SectionContainer>

        </SectionsContainer>
      </div>
    )
  }
}

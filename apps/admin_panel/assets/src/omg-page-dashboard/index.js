import React, { Component } from 'react'
import styled from 'styled-components'
import { Button, Icon } from '../omg-uikit'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import CurrentAccountProvider from '../omg-account-current/currentAccountProvider'
import moment from 'moment'
import { Link, withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'

const SectionsContainer = styled.div`
  display: flex;
`
const SectionContainer = styled.div`
  flex: 1 1 auto;
  :first-child {
    width: 250px;
    padding-right: 20px;
  }
  b {
    display: block;
  }
  > h5 {
    text-transform: uppercase;
    letter-spacing: 1px;
  }
`
const IntroContainer = styled.div`
  border-radius: 4px;
  background-color: rgba(219, 233, 255, 0.8);
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
  a {
    color: ${props => props.theme.colors.B400};
    :hover {
      color: ${props => props.theme.colors.BL400};
    }
  }

  i {
    color: ${props => props.theme.colors.BL400};
    font-size: 16px;
    margin-right: 10px;
  }
`
const GetStartedContainer = styled.div`
  border: 1px solid #e4e7ed;
  padding: 30px;
  border-radius: 4px;
  background-color: #ffffff;
  background-image: url(${require('../../statics/images/Dashboard_Main.png')});
  background-size: 41vw auto;
  background-repeat: no-repeat;
  background-position: bottom right;
  h4 {
    letter-spacing: 1px;
    margin-bottom: 30px;
  }
`
const GetStartedContent = styled.div`
  width: 200px;
  padding: 20px;
  background-color: white;
  border-radius: 4px;
`

export default withRouter(
  class Dashboard extends Component {
    static propTypes = {
      match: PropTypes.object
    }
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
            <span>{moment(currentAccount.created_at).format('DD/MM/YYYY HH:mm:ss')}</span>
          </DetailGroup>
          <DetailGroup>
            <b>Last Update:</b>{' '}
            <span>{moment(currentAccount.updated_at).format('DD/MM/YYYY HH:mm:ss')}</span>
          </DetailGroup>
        </SectionContainer>
      )
    }
    render () {
      const accountId = this.props.match.params.accountId
      return (
        <div>
          <TopNavigation title='Dashboard' types={false} secondaryAction={false} />
          <SectionsContainer>
            <CurrentAccountProvider render={this.renderCurrentAccountSection} />
            <SectionContainer>
              <IntroContainer>
                <h5>
                You can see all the statistics related to transactions within the current account here
                </h5>
                <p>Analytics will come soon, stay tuned!</p>
              </IntroContainer>
              <GetStartedContainer>
                <GetStartedContent>
                  <h4>{'Let\'s get started'}</h4>
                  <NavigationItem>
                    <Link to={`/${accountId}/setting/?invite=true`}>
                      <Icon name='Arrow-Right' /> Invite Team Member
                  </Link>
                  </NavigationItem>
                  <NavigationItem>
                    <Link to={`/${accountId}/accounts/?createAccount=true`}>
                      <Icon name='Arrow-Right' /> Create Account
                  </Link>
                  </NavigationItem>
                  <NavigationItem>
                    <Link to={`/${accountId}/tokens/?createToken=true`}>
                      <Icon name='Arrow-Right' /> Create Token
                  </Link>
                  </NavigationItem>
                  <NavigationItem>
                    <Link to={`/${accountId}/wallets`}>
                      <Icon name='Arrow-Right' /> Organize Wallets
                  </Link>
                  </NavigationItem>
                  <NavigationItem>
                    <Link to={`/${accountId}/requests?createRequest=true`}>
                      <Icon name='Arrow-Right' /> Create Request
                  </Link>
                  </NavigationItem>
                  <NavigationItem>
                    <Link to={`/${accountId}/api`}>
                      <Icon name='Arrow-Right' /> Generate API
                  </Link>
                  </NavigationItem>
                  <NavigationItem>
                    <a href='/api/admin/docs.ui#' target='_blank'>
                      <Icon name='Arrow-Right' /> API Documentation
                  </a>
                  </NavigationItem>
                </GetStartedContent>
              </GetStartedContainer>
            </SectionContainer>
          </SectionsContainer>
        </div>
      )
    }
  }
)

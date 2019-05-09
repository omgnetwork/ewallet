import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { Button } from '../omg-uikit'
import { compose } from 'recompose'
import AdminKeySection from './AdminKeySection'
import { withRouter, Link } from 'react-router-dom'
import ClientKeySection from './ClientKeySection'
import queryString from 'query-string'
const ApiKeyContainer = styled.div`
  padding-bottom: 50px;
`

const KeyTopBar = styled.div`
  margin-bottom: 20px;
  p {
    color: ${props => props.theme.colors.B100};
    max-width: 80%;
  }
  > div:first-child {
    display: flex;
    align-items: center;
  }
  button:last-child {
    margin-left: auto;
  }
`
const KeyButton = styled.button`
  padding: 5px 10px;
  border-radius: 4px;
  font-weight: ${({ active, theme }) => (active ? 'bold' : 'normal')};
  background-color: ${({ active, theme }) => (active ? theme.colors.S200 : 'white')};
  color: ${({ active, theme }) => (active ? theme.colors.B400 : theme.colors.B100)};
  margin-right: 10px;
  border: none;
  width: 100px;
  :hover {
    border: 1px solid ${props => props.theme.colors.S300};
  }
`
const KeyTopButtonsContainer = styled.div`
  margin: 25px 0;
`
const enhance = compose(withRouter)
class ApiKeyPage extends Component {
  static propTypes = {
    divider: PropTypes.bool,
    match: PropTypes.object,
    location: PropTypes.object
  }
  state = {
    createAdminKeyModalOpen: false,
    createClientKeyModalOpen: false
  }
  onRequestClose = () => {
    this.setState({
      createAdminKeyModalOpen: false,
      createClientKeyModalOpen: false
    })
  }

  onClickCreateClientKey = e => {
    this.setState({ createClientKeyModalOpen: true })
  }
  onClickCreateAdminKey = e => {
    this.setState({ createAdminKeyModalOpen: true })
  }

  onSubmitSuccess = fetch => data => {
    fetch()
    this.setState({
      secretKey: data.secret_key,
      accessKey: data.access_key,
      privateKeyModalOpen: true
    })
  }

  render () {
    const activeTab = this.props.match.params.keyType === 'client' ? 'client' : 'admin'
    const searchQuery = queryString.parse(this.props.location.search).search
    const stringQuery = queryString.stringify({ search: searchQuery })
    return (
      <ApiKeyContainer>
        <TopNavigation
          divider={this.props.divider}
          title={'Keys'}
          description={'These are the keys that can be used by developers to interact with the API.'}
          buttons={null}
          types={false}
        />
        <KeyTopBar>
          <KeyTopButtonsContainer>
            <Link to='/keys/admin' query={stringQuery}>
              <KeyButton active={activeTab === 'admin'}>Admin Keys</KeyButton>
            </Link>
            <Link to='/keys/client' query={stringQuery}>
              <KeyButton active={activeTab === 'client'}>Client Keys</KeyButton>
            </Link>
            {activeTab === 'admin' ? (
              <Button size='small' onClick={this.onClickCreateAdminKey} styleType={'secondary'}>
                <span>Generate Admin Key</span>
              </Button>
            ) : (
              <Button size='small' onClick={this.onClickCreateClientKey} styleType={'secondary'}>
                <span>Generate Client Key</span>
              </Button>
            )}
          </KeyTopButtonsContainer>
          {activeTab === 'admin' ? (
            <p>
              {`Admin Keys are used to access all admin related APIs, eg. wallets, list a user's
              transactions, create transaction requests, etc.`}
            </p>
          ) : (
            <p>
              {`Client Keys are used to authenticate clients and allow them to perform various
              user-related functions (once the user has been logged in), e.g. make transfers with
              the user's wallets, list a user's transactions, create transaction requests, etc.`}
            </p>
          )}
        </KeyTopBar>
        {activeTab === 'admin' ? (
          <AdminKeySection
            createAdminKeyModalOpen={this.state.createAdminKeyModalOpen}
            onRequestClose={this.onRequestClose}
            search={queryString.parse(this.props.location.search).search}
          />
        ) : (
          <ClientKeySection
            createClientKeyModalOpen={this.state.createClientKeyModalOpen}
            onRequestClose={this.onRequestClose}
            search={queryString.parse(this.props.location.search).search}
          />
        )}
      </ApiKeyContainer>
    )
  }
}

export default enhance(ApiKeyPage)

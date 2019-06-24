import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { compose } from 'recompose'
import { withRouter, Link } from 'react-router-dom'
import queryString from 'query-string'

import TopNavigation from '../omg-page-layout/TopNavigation'
import { Button, Tag } from '../omg-uikit'
import AdminKeySection from './AdminKeySection'
import ClientKeySection from './ClientKeySection'

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

const KeyTopButtonsContainer = styled.div`
  margin: 25px 0;
  a {
    margin-right: 10px;
  }
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
          searchBar={false}
        />
        <KeyTopBar>
          <KeyTopButtonsContainer>
            <Link to='/keys/admin' query={stringQuery}>
              <Tag
                title='Admin Keys'
                icon='Option-Horizontal'
                active={activeTab === 'admin'}
                hoverStyle
              />
            </Link>
            <Link to='/keys/client' query={stringQuery}>
              <Tag
                title='Client Keys'
                icon='Option-Horizontal'
                active={activeTab === 'client'}
                hoverStyle
              />
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
            subPage={false}
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

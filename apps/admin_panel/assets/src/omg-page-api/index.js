import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { Button, Switch, Icon } from '../omg-uikit'
import Table from '../omg-table'
import ApiKeysFetcher from '../omg-api-keys/apiKeysFetcher'
import AccessKeyFetcher from '../omg-access-key/accessKeysFetcher'
import moment from 'moment'
import ConfirmationModal from '../omg-confirmation-modal'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { createApiKey, updateApiKey } from '../omg-api-keys/action'
import { createAccessKey, updateAccessKey } from '../omg-access-key/action'
import queryString from 'query-string'
import { withRouter, Link } from 'react-router-dom'
import Copy from '../omg-copy'

const ApiKeyContainer = styled.div`
  padding-bottom: 50px;
`
const KeySection = styled.div`
  position: relative;
  p {
    color: ${props => props.theme.colors.B100};
  }
  h3,
  p {
    max-width: 800px;
  }
  td {
    color: ${props => props.theme.colors.B200};
  }
  h3 {
    margin-bottom: 20px;
  }
  tr:hover {
    td:nth-child(1) {
      i {
        visibility: visible;
      }
    }
  }
  td:nth-child(1) {
    width: 40%;
    border: none;
    position: relative;
    :before {
      content: '';
      position: absolute;
      right: 0;
      bottom: -1px;
      height: 1px;
      width: calc(100% - 50px);
      border-bottom: 1px solid ${props => props.theme.colors.S200};
    }
  }
  i[name='Copy'] {
    cursor: pointer;
    visibility: hidden;
    cursor: pointer;
    color: ${props => props.theme.colors.S500};
    :hover {
      color: ${props => props.theme.colors.B300};
    }
  }
`
const ConfirmCreateKeyContainer = styled.div`
  font-size: 16px;
  padding: 30px;
  h4 {
    padding-bottom: 10px;
  }
  p {
    font-size: 12px;
    max-width: 350px;
    margin-bottom: 10px;
  }
  input {
    border: 1px solid #1a56f0;
    border-radius: 2px;
    background-color: #ffffff;
    width: 370px;
    padding: 5px;
    margin-top: 5px;
    margin-right: 5px;
    color: ${props => props.theme.colors.B300};
  }
  i[name='Copy'] {
    margin-left: 5px;
    cursor: pointer;
    color: ${props => props.theme.colors.S500};
    :hover {
      color: ${props => props.theme.colors.B300};
    }
  }
`
const KeyContainer = styled.div`
  white-space: nowrap;
  span {
    vertical-align: middle;
  }

  i {
    margin-right: 5px;
  }
  i[name='Key'] {
    margin-right: 5px;
    color: ${props => props.theme.colors.B100};
    padding: 8px;
    border-radius: 6px;
    border: 1px solid ${props => props.theme.colors.S400};
  }
  i[name='People'] {
    color: inherit;
  }
`

const InputContainer = styled.div`
  :not(:last-child) {
    margin-bottom: 10px;
  }
`
const InputLabel = styled.div`
  font-size: 14px;
  color: ${props => props.theme.colors.B100};
`
const KeyTopBar = styled.div`
  > div:first-child {
    display: flex;
    align-items: center;
  }
  button:last-child {
    margin-left: auto;
  }
  margin-bottom: 20px;
`
const KeyButton = styled.button`
  padding: 5px 10px;
  border-radius: 4px;
  font-weight: ${({ active, theme }) => (active ? 'bold' : 'normal')};
  background-color: ${({ active, theme }) => (active ? theme.colors.S200 : 'white')};
  color: ${({ active, theme }) => (active ? theme.colors.B400 : theme.colors.B100)};
  border: none;
  margin-right: 10px;
  border: 1px solid ${props => props.theme.colors.S300};
  width: 100px;
`
const KeyTopButtonsContainer = styled.div`
  margin: 20px 0;
`
const columnsApiKey = [
  { key: 'key', title: 'API KEY' },
  { key: 'user', title: 'CREATE BY' },
  { key: 'created_at', title: 'CREATED DATE' },
  { key: 'status', title: 'STATUS' }
]
const columnsAccessKey = [
  { key: 'key', title: 'ACCESS KEY' },
  { key: 'user', title: 'CREATE BY' },
  { key: 'created_at', title: 'CREATED DATE' },
  { key: 'status', title: 'STATUS' }
]
const enhance = compose(
  withRouter,
  connect(
    null,
    { createApiKey, updateApiKey, createAccessKey, updateAccessKey }
  )
)
class ApiKeyPage extends Component {
  static propTypes = {
    createApiKey: PropTypes.func,
    createAccessKey: PropTypes.func,
    updateApiKey: PropTypes.func,
    location: PropTypes.object,
    updateAccessKey: PropTypes.func,
    match: PropTypes.object
  }
  state = {
    accessModalOpen: false,
    ewalletModalOpen: false
  }
  onRequestClose = () => {
    this.setState({
      accessModalOpen: false,
      ewalletModalOpen: false
    })
  }
  onRequestCloseShowPrivateKey = () => {
    this.setState({
      secretKey: '',
      accessKey: '',
      submitStatus: 'DEFAULT',
      privateKeyModalOpen: false
    })
  }
  onClickCreateAccessKey = e => {
    this.setState({ accessModalOpen: true })
  }
  onClickCreateEwalletKey = e => {
    this.setState({ ewalletModalOpen: true })
  }
  onClickOkCreateEwalletKey = fetch => async e => {
    this.setState({ submitStatus: 'SUBMITTING' })
    try {
      await this.props.createApiKey()
      fetch()
      this.onRequestClose()
      this.setState({ submitStatus: 'SUCCESS' })
    } catch (error) {
      this.setState({ submitStatus: 'FAILED' })
    }
  }
  onClickOkCreateAccessKey = fetch => async e => {
    this.setState({ submitStatus: 'SUBMITTING' })
    try {
      const { data } = await this.props.createAccessKey()
      fetch()
      this.setState({
        secretKey: data.secret_key,
        accessKey: data.access_key,
        submitStatus: 'SUCCESS',
        privateKeyModalOpen: true
      })
      this.onRequestClose()
    } catch (error) {
      this.setState({ submitStatus: 'FAILED' })
    }
  }
  onClickSwitch = ({ id, expired, fetch }) => async e => {
    await this.props.updateApiKey({ id, expired })
  }
  onClickAccessKeySwitch = ({ id, expired, fetch }) => async e => {
    await this.props.updateAccessKey({ id, expired })
  }

  rowApiKeyRenderer = fetch => (key, data, rows) => {
    switch (key) {
      case 'status':
        return (
          <Switch
            open={!data}
            onClick={this.onClickSwitch({ id: rows.id, expired: !rows.status, fetch })}
          />
        )
      case 'key':
        return (
          <KeyContainer>
            <Icon name='Key' /> <span>{data}</span> <Copy data={data} />
          </KeyContainer>
        )
      case 'user':
        return (
          <KeyContainer>
            <Icon name='Profile' /> <span>{data}</span>
          </KeyContainer>
        )
      case 'created_at':
        return moment(data).format()
      default:
        return data
    }
  }

  rowAccessKeyRenderer = fetch => (key, data, rows) => {
    switch (key) {
      case 'status':
        return (
          <Switch
            open={!data}
            onClick={this.onClickAccessKeySwitch({ id: rows.id, expired: !rows.status, fetch })}
          />
        )
      case 'key':
        return (
          <KeyContainer>
            <Icon name='Key' /> <span>{data}</span> <Copy data={data} />
          </KeyContainer>
        )
      case 'user':
        return (
          <KeyContainer>
            <Icon name='Profile' /> <span>{data}</span>
          </KeyContainer>
        )
      case 'created_at':
        return moment(data).format()
      default:
        return data
    }
  }
  renderClientKey () {
    return (
      <ApiKeysFetcher
        query={{
          page: queryString.parse(this.props.location.search)['api_key_page'],
          perPage: 5
        }}
        render={({ data, individualLoadingStatus, pagination, fetch }) => {
          const apiKeysRows = data
            .filter(key => !key.deleted_at)
            .map(key => {
              return {
                key: key.key,
                id: key.id,
                user: key.account_id,
                created_at: key.created_at,
                status: key.expired,
                updated_at: key.updated_at
              }
            })
          return (
            <KeySection>
              <Table
                loadingRowNumber={6}
                rows={apiKeysRows}
                rowRenderer={this.rowApiKeyRenderer(fetch)}
                columns={columnsApiKey}
                perPage={10}
                loadingColNumber={4}
                loadingStatus={individualLoadingStatus}
                navigation
                pageEntity='api_key_page'
                isFirstPage={pagination.is_first_page}
                isLastPage={pagination.is_last_page}
              />
              <ConfirmationModal
                open={this.state.ewalletModalOpen}
                onRequestClose={this.onRequestClose}
                onOk={this.onClickOkCreateEwalletKey(fetch)}
                loading={this.state.submitStatus === 'SUBMITTING'}
              >
                <ConfirmCreateKeyContainer>
                  <h4>Generate eWallet key</h4>
                  <p>Are you sure you want to generate eWallet key ?</p>
                </ConfirmCreateKeyContainer>
              </ConfirmationModal>
            </KeySection>
          )
        }}
      />
    )
  }
  renderAdminKey = () => {
    return (
      <AccessKeyFetcher
        query={{
          page: queryString.parse(this.props.location.search)['access_key_page'],
          perPage: 10
        }}
        render={({ data, individualLoadingStatus, pagination, fetch }) => {
          const apiKeysRows = data.map(key => {
            return {
              key: key.access_key,
              id: key.id,
              user: key.account_id,
              created_at: key.created_at,
              status: key.expired
            }
          })
          return (
            <KeySection>
              <Table
                loadingRowNumber={6}
                rows={apiKeysRows}
                rowRenderer={this.rowAccessKeyRenderer(fetch)}
                columns={columnsAccessKey}
                loadingStatus={individualLoadingStatus}
                navigation
                isFirstPage={pagination.is_first_page}
                isLastPage={pagination.is_last_page}
                pageEntity='access_key_page'
              />
              <ConfirmationModal
                open={this.state.accessModalOpen}
                onRequestClose={this.onRequestClose}
                onOk={this.onClickOkCreateAccessKey(fetch)}
                closeTimeoutMS={0}
                loading={this.state.submitStatus === 'SUBMITTING'}
              >
                <ConfirmCreateKeyContainer>
                  <h4>Generate Access key</h4>
                  <p>Are you sure you want to generate access key ?</p>
                </ConfirmCreateKeyContainer>
              </ConfirmationModal>
              <ConfirmationModal
                open={this.state.privateKeyModalOpen}
                onRequestClose={this.onRequestCloseShowPrivateKey}
                onOk={this.onRequestCloseShowPrivateKey}
                confirmText='Got it!'
                cancel={false}
              >
                <ConfirmCreateKeyContainer>
                  <h4>Your key pair</h4>
                  <p>
                    Please copy and keep this pair of acesss and secret key. Secret key will use to
                    open your encrypted information.
                  </p>
                  <InputContainer>
                    <InputLabel>Access Key</InputLabel>
                    <input value={this.state.accessKey} spellCheck='false' />
                    <Copy data={this.state.accessKey} />
                  </InputContainer>
                  <InputContainer>
                    <InputLabel>Secret key</InputLabel>
                    <input value={this.state.secretKey} spellCheck='false' />
                    <Copy data={this.state.secretKey} />
                  </InputContainer>
                </ConfirmCreateKeyContainer>
              </ConfirmationModal>
            </KeySection>
          )
        }}
      />
    )
  }

  render () {
    const activeTab = this.props.match.params.keyType === 'client' ? 'client' : 'admin'
    return (
      <ApiKeyContainer>
        <TopNavigation divider={this.props.divider}
          title={'Keys'}
          description={
            'These are all keys using in this application. Click each one to view their details.'
          }
          buttons={null}
          secondaryAction={false}
          types={false}
        />
        <KeyTopBar>
          <KeyTopButtonsContainer>
            <Link to='/keys/admin'>
              <KeyButton active={activeTab === 'admin'}>Admin Keys</KeyButton>
            </Link>
            <Link to='/keys/client'>
              <KeyButton active={activeTab === 'client'}>Client Keys</KeyButton>
            </Link>
            <Button size='small' onClick={this.onClickCreateAccessKey} styleType={'secondary'}>
              <span>Generate Access Key</span>
            </Button>
          </KeyTopButtonsContainer>
          <p>
            Access Keys are used to gain access to everything. user-related functions (once the user
            has been logged in), e.g. make transfers with the user's wallets, list a user's
            transactions, create transaction requests, etc.
          </p>
        </KeyTopBar>
        {activeTab === 'admin' ? this.renderAdminKey() : this.renderClientKey()}
      </ApiKeyContainer>
    )
  }
}

export default enhance(ApiKeyPage)

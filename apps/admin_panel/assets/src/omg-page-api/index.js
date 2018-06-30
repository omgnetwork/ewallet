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
import { generateApiKey, updateApiKey } from '../omg-api-keys/action'
import { generateAccessKey } from '../omg-access-key/action'
import queryString from 'query-string'
import { withRouter } from 'react-router-dom'
const ApiKeyContainer = styled.div`
  padding-bottom: 50px;
  button {
    margin-top: 20px;
    margin-bottom: 20px;
  }
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
  i[name="Key"] {
    color: ${props => props.theme.colors.BL400};
  }
  i[name="People"] {
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
const columnsApiKey = [
  { key: 'key', title: 'KEY' },
  { key: 'user', title: 'CREATE BY' },
  { key: 'created_at', title: 'CREATED DATE' },
  { key: 'status', title: 'STATUS' }
]
const columnsAccessKey = [
  { key: 'key', title: 'KEY' },
  { key: 'user', title: 'CREATE BY' },
  { key: 'created_at', title: 'CREATED DATE' },
  { key: 'status_access', title: 'STATUS' }
]
const enhance = compose(
  withRouter,
  connect(
    null,
    { generateApiKey, updateApiKey, generateAccessKey }
  )
)
class ApiKeyPage extends Component {
  static propTypes = {
    generateApiKey: PropTypes.func,
    generateAccessKey: PropTypes.func,
    updateApiKey: PropTypes.func,
    location: PropTypes.object
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
      privateKey: '',
      publicKey: '',
      submitStatus: 'DEFAULT'
    })
  }
  onClickCreateAccessKey = e => {
    this.setState({ accessModalOpen: true })
  }
  onClickCreateEwalletKey = e => {
    this.setState({ ewalletModalOpen: true })
  }
  onClickOkCreateEwalletKey = fetch => async e => {
    await this.props.generateApiKey()
    fetch()
    this.onRequestClose()
  }
  onClickOkCreateAccessKey = fetch => async e => {
    this.setState({ submitStatus: 'SUBMITTING' })
    const { data } = await this.props.generateAccessKey()
    fetch()
    this.setState({
      privateKey: data.secret_key,
      publicKey: data.access_key,
      submitStatus: 'SUCCESS'
    })
    this.onRequestClose()
  }
  onClickSwitch = ({ id, expired, fetch }) => async e => {
    await this.props.updateApiKey({ id, expired })
  }
  rowRenderer = fetch => (key, data, rows) => {
    if (key === 'status') {
      return (
        <Switch
          open={!data}
          onClick={this.onClickSwitch({ id: rows.id, expired: !rows.status, fetch })}
        />
      )
    }
    if (key === 'status_access') {
      return data ? 'enabled' : 'disabled'
    }
    if (key === 'key') {
      return (
        <KeyContainer>
          <Icon name='Key' /> <span>{data}</span>
        </KeyContainer>
      )
    }
    if (key === 'user') {
      return (
        <KeyContainer>
          <Icon name='Profile' /> <span>{data}</span>
        </KeyContainer>
      )
    }
    if (key === 'created_at') {
      return moment(data).format('ddd, DD/MM/YYYY hh:mm:ss')
    }
    return data
  }
  renderEwalletApiKey = () => {
    return (
      <ApiKeysFetcher
        query={{
          page: queryString.parse(this.props.location.search)['api_key_page'],
          perPage: 5
        }}
        render={({ data, individualLoadingStatus, pagination, fetch }) => {
          const apiKeysRows = data.filter(key => !key.deleted_at).map(key => {
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
            <KeySection style={{ marginTop: '20px' }}>
              <h3>E-Wallet API Key</h3>
              <p>
                eWallet API Keys are used to authenticate clients and allow them to perform various
                user-related functions (once the user has been logged in), e.g. make transfers with
                the user's wallets, list a user's transactions, create transaction requests, etc.
              </p>
              <Button size='small' onClick={this.onClickCreateEwalletKey} styleType={'secondary'}>
                <span>Generate Key</span>
              </Button>
              <Table
                loadingRowNumber={6}
                rows={apiKeysRows}
                rowRenderer={this.rowRenderer(fetch)}
                columns={columnsApiKey}
                perPage={99999}
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
              >
                <ConfirmCreateKeyContainer>
                  <h4>Generate e-wallet key</h4>
                  <p>Are you sure you want to generate e-wallet key ?</p>
                </ConfirmCreateKeyContainer>
              </ConfirmationModal>
            </KeySection>
          )
        }}
      />
    )
  }
  renderAccessKey = () => {
    return (
      <AccessKeyFetcher
        query={{
          page: queryString.parse(this.props.location.search)['access_key_page'],
          perPage: 5
        }}
        render={({ data, individualLoadingStatus, pagination, fetch }) => {
          const apiKeysRows = data.filter(key => !key.deleted_at).map(key => {
            return {
              key: key.access_key,
              id: key.access_key,
              user: key.account_id,
              created_at: key.created_at,
              status_access: key.deleted_at
            }
          })
          return (
            <KeySection style={{ marginTop: '50px' }}>
              <h3>Access Key</h3>
              <p>
                Access Keys are used to gain access to everything. user-related functions (once the
                user has been logged in), e.g. make transfers with the user's wallets, list a user's
                transactions, create transaction requests, etc.
              </p>
              <Button size='small' onClick={this.onClickCreateAccessKey} styleType={'secondary'}>
                <span>Generate Key</span>
              </Button>
              <Table
                loadingRowNumber={6}
                rows={apiKeysRows}
                rowRenderer={this.rowRenderer()}
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
                  <p>Are you sure you want to generate acesss key ?</p>
                </ConfirmCreateKeyContainer>
              </ConfirmationModal>
              <ConfirmationModal
                open={this.state.submitStatus === 'SUCCESS'}
                onRequestClose={this.onRequestCloseShowPrivateKey}
                onOk={this.onRequestCloseShowPrivateKey}
                confirmText='Got it!'
                cancel={false}
              >
                <ConfirmCreateKeyContainer>
                  <h4>Your key pair</h4>
                  <p>
                    Please copy and keep this pair of public and private key. Secret key will use to
                    open your encrypted information.
                  </p>
                  <InputContainer>
                    <InputLabel>Private key</InputLabel>
                    <input value={this.state.privateKey} spellCheck='false' />
                  </InputContainer>
                  <InputContainer>
                    <InputLabel>Public Key</InputLabel>
                    <input value={this.state.publicKey} spellCheck='false' />
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
    return (
      <ApiKeyContainer>
        <TopNavigation
          title={'Manage API Keys'}
          buttons={null}
          secondaryAction={false}
          types={false}
        />
        {this.renderEwalletApiKey()}
        {this.renderAccessKey()}
      </ApiKeyContainer>
    )
  }
}

export default enhance(ApiKeyPage)

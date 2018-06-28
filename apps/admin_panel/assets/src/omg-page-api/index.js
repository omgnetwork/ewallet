import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { Button, Table, Switch, Icon } from '../omg-uikit'
import ApiKeyProvider from '../omg-api-keys/apiKeyProvider'
import AccessKeyProvider from '../omg-access-key/accessKeyProvider'
import moment from 'moment'
import ConfirmationModal from '../omg-confirmation-modal'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { generateApiKey, updateApiKey } from '../omg-api-keys/action'
import { generateAccessKey } from '../omg-access-key/action'
const ApiKeyContainer = styled.div`
  padding-bottom: 50px;
  button {
    margin-top: 20px;
    margin-bottom: 20px;
  }
  table {
    width: 1000px;
    text-align: left;
    td:nth-child(4) {
      width: 10%;
    }
    thead {
      tr {
        background-color: ${props => props.theme.colors.S200};
        border: 1px solid ${props => props.theme.colors.S400};
        padding: 20px 0;
        th {
          color: ${props => props.theme.colors.B200};
          white-space: nowrap;
          padding: 5px 15px;
        }
      }
    }
    * {
      vertical-align: middle;
    }
    tbody tr:hover {
      background-color: ${props => props.theme.colors.S100};
    }
    td {
      padding: 8px 15px;
      vertical-align: top;
      border-bottom: 1px solid ${props => props.theme.colors.S300};
      white-space: nowrap;
    }
  }
`
const KeySection = styled.div`
  position: relative;
  :not(:first-child) {
    margin-top: 50px;
  }
  h3 {
    font-size: 18px;
    font-weight: 400;
    margin-bottom: 20px;
  }
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
  h4 {
    padding-bottom: 10px;
  }
  p {
    font-size: 12px;
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

const columnsApiKey = [
  { key: 'key', title: 'Key' },
  { key: 'user', title: 'Create by' },
  { key: 'created_at', title: 'Date' },
  { key: 'status', title: 'Status' }
]
const columnsAccessKey = [
  { key: 'key', title: 'Key' },
  { key: 'user', title: 'Create by' },
  { key: 'created_at', title: 'Date' },
  { key: 'status_access', title: 'Status' }
]
const enhance = compose(
  connect(
    null,
    { generateApiKey, updateApiKey, generateAccessKey }
  )
)
class ApiKeyPage extends Component {
  static propTypes = {
    generateApiKey: PropTypes.func,
    generateAccessKey: PropTypes.func,
    updateApiKey: PropTypes.func
  }
  state = {
    accessModalOpen: false,
    ewalletModalOpen: false
  }
  onRequestClose = () => {
    this.setState({ accessModalOpen: false, ewalletModalOpen: false })
  }
  onClickCreateAccessKey = e => {
    this.setState({ accessModalOpen: true })
  }
  onClickCreateEwalletKey = e => {
    this.setState({ ewalletModalOpen: true })
  }
  onClickOkCreateEwalletKey = e => {
    this.props.generateApiKey()
    this.onRequestClose()
  }
  onClickOkCreateAccessKey = e => {
    this.props.generateAccessKey()
    this.onRequestClose()
  }
  onClickSwitch = ({ id, expired }) => async e => {
    this.props.updateApiKey({ id, expired })
  }
  rowRenderer = (key, data, rows) => {
    if (key === 'status') {
      return (
        <Switch
          open={!data}
          onClick={this.onClickSwitch({ id: rows.key, expired: !rows.expired })}
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
      <ApiKeyProvider
        render={({ apiKeys, loadingStatus }) => {
          const apiKeysRows = apiKeys.filter(key => !key.deleted_at).map(key => {
            return {
              key: key.id,
              id: key.id,
              user: key.account_id,
              created_at: key.created_at,
              expired: key.expired,
              ownerApp: key.owner_app
            }
          })
          return (
            <KeySection>
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
                rows={apiKeysRows}
                rowRenderer={this.rowRenderer}
                columns={columnsApiKey}
                perPage={99999}
                loadingColNumber={4}
                loading={loadingStatus === 'DEFAULT'}
              />
              <ConfirmationModal
                open={this.state.ewalletModalOpen}
                onRequestClose={this.onRequestClose}
                onOk={this.onClickOkCreateEwalletKey}
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
      <AccessKeyProvider
        render={({ data, loadingStatus }) => {
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
            <KeySection>
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
                rows={apiKeysRows}
                rowRenderer={this.rowRenderer}
                columns={columnsAccessKey}
                loading={loadingStatus === 'DEFAULT'}
              />
              <ConfirmationModal
                open={this.state.accessModalOpen}
                onRequestClose={this.onRequestClose}
                onOk={this.onClickOkCreateAccessKey}
              >
                <ConfirmCreateKeyContainer>
                  <h4>Generate Access key</h4>
                  <p>Are you sure you want to generate acesss key ?</p>
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

import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { Button, Table } from '../omg-uikit'
import ApiKeyProvider from '../omg-api-keys/apiKeyProvider'
import moment from 'moment'
import ConfirmationModal from '../omg-confirmation-modal'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { generateApiKey } from '../omg-api-keys/action.js'
const ApiKeyContainer = styled.div`
  padding-bottom: 50px;
  button {
    margin-top: 20px;
    margin-bottom: 20px;
  }
  table {
    width: 100%;
    text-align: left;
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
  max-width: 700px;
  h3 {
    font-size: 18px;
    font-weight: 400;
    margin-bottom: 20px;
  }
  p {
    color: ${props => props.theme.colors.B100};
  }
`
const KeySectionEwallet = KeySection.extend`
  td {
    color: ${props => props.theme.colors.B200};
  }
`
const ConfirmCreateKeyContainer = styled.div`
  font-size: 16px;
  h4 {
    padding-bottom: 10px;
  }
`
const columns = [
  { key: 'created_at', title: 'Created' },
  { key: 'user', title: 'User' },
  { key: 'secret', title: 'Secret' },
  { key: 'status', title: 'Status' }
]
const enhance = compose(connect(null, { generateApiKey }))
class ApiKeyPage extends Component {
  static propTypes = {
    generateApiKey: PropTypes.func
  }
  state = {
    adminModalOpen: false,
    ewalletModalOpen: false
  }
  onRequestClose = () => {
    this.setState({ adminModalOpen: false, ewalletModalOpen: false })
  }
  onClickCreateAdminKey = e => {
    this.setState({ adminModalOpen: true })
  }
  onClickCreateEwalletKey = e => {
    this.setState({ ewalletModalOpen: true })
  }
  onClickOk = owner => e => {
    this.props.generateApiKey(owner)
    this.onRequestClose()
  }
  renderAdminApiKey = (apiKeysRows, loadingStatus) => {
    return (
      <KeySection>
        <h3>Admin API Key</h3>
        <p>
        The Admin API key is used to authenticate an API and allows that specific API to access various admin-related functions such as creating new minted tokens, mint more tokens, create and manage accounts, create new API keys, etc.
        </p>
        <Button size='small' onClick={this.onClickCreateAdminKey} styleType={'secondary'}>
          <span>Generate Key</span>
        </Button>
        <Table
          rows={apiKeysRows}
          columns={columns}
          perPage={99999}
          loading={loadingStatus === 'DEFAULT'}
        />
      </KeySection>
    )
  }
  renderEwalletApiKey = (apiKeysRows, loadingStatus) => {
    return (
      <KeySectionEwallet>
        <h3>E-Wallet API Key</h3>
        <p>
        The eWallet API key is used to authenticate an API and allows that specific API to access various user-related functions, e.g. make transfers with the user's wallets, list a user's transactions, create transaction requests, etc.
        </p>
        <Button size='small' onClick={this.onClickCreateEwalletKey} styleType={'secondary'}>
          <span>Generate Key</span>
        </Button>
        <Table
          rows={apiKeysRows}
          columns={columns}
          perPage={99999}
          loading={loadingStatus === 'DEFAULT'}
        />
      </KeySectionEwallet>
    )
  }

  render () {
    return (
      <ApiKeyProvider
        render={({ apiKeys, loadingStatus }) => {
          const apiKeysRows = apiKeys.map(key => {
            return {
              key: key.id,
              user: key.account_id,
              created_at: moment(key.created_at).format('ddd, DD/MM/YYYY hh:mm:ss'),
              secret: key.key,
              status: !key.deleted_at ? 'enabled' : 'disabled',
              ownerApp: key.owner_app
            }
          })
          return (
            <ApiKeyContainer>
              <TopNavigation
                title={'Manage API Keys'}
                buttons={null}
                secondaryAction={false}
                types={false}
              />
              {/* {this.renderAdminApiKey(
                apiKeysRows.filter(x => x.ownerApp === 'admin_api'),
                loadingStatus
              )} */}
              {this.renderEwalletApiKey(
                apiKeysRows.filter(x => x.ownerApp === 'ewallet_api'),
                loadingStatus
              )}
              <ConfirmationModal
                open={this.state.adminModalOpen}
                onRequestClose={this.onRequestClose}
                onOk={this.onClickOk('admin_api')}
              >
                <ConfirmCreateKeyContainer>
                  <h4>GENERATE ADMIN API KEY</h4>
                  <p>Are you sure you want to generate admin api key ?</p>
                </ConfirmCreateKeyContainer>
              </ConfirmationModal>
              <ConfirmationModal
                open={this.state.ewalletModalOpen}
                onRequestClose={this.onRequestClose}
                onOk={this.onClickOk('ewallet_api')}
              >
                <ConfirmCreateKeyContainer>
                  <h4>GENERATE EWALLET API KEY</h4>
                  <p>Are you sure you want to generate ewallet api key ?</p>
                </ConfirmCreateKeyContainer>
              </ConfirmationModal>
            </ApiKeyContainer>
          )
        }}
      />
    )
  }
}

export default enhance(ApiKeyPage)

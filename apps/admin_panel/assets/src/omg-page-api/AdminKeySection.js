import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Switch, Icon } from '../omg-uikit'
import Table from '../omg-table'
import AccessKeyFetcher from '../omg-access-key/accessKeysFetcher'
import moment from 'moment'
import ConfirmationModal from '../omg-confirmation-modal'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { createApiKey } from '../omg-api-keys/action'
import { createAccessKey, updateAccessKey } from '../omg-access-key/action'
import CreateAdminKeyModal from '../omg-create-admin-key-modal'
import queryString from 'query-string'
import { withRouter } from 'react-router-dom'
import Copy from '../omg-copy'

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
  td {
    white-space: nowrap;
  }
  td:nth-child(1) {
    width: 50%;
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
const columnsAdminKeys = [
  { key: 'key', title: 'ADMIN KEY' },
  { key: 'name', title: 'NAME' },
  { key: 'created_at', title: 'CREATED DATE' },
  { key: 'status', title: 'STATUS' },
  { key: 'global_role', title: 'GLOBAL ROLE' }
]
const enhance = compose(
  withRouter,
  connect(
    null,
    { createApiKey, createAccessKey, updateAccessKey }
  )
)
class ApiKeyPage extends Component {
  static propTypes = {
    location: PropTypes.object,
    updateAccessKey: PropTypes.func,
    createAdminKeyModalOpen: PropTypes.bool,
    query: PropTypes.object,
    fetcher: PropTypes.func,
    registerFetch: PropTypes.func,
    onRequestClose: PropTypes.func
  }

  static defaultProps = {
    fetcher: AccessKeyFetcher
  }
  state = {
    createAdminKeyModalOpen: false,
    privateKeyModalOpen: false,
    accessKey: '',
    secretKey: ''
  }
  onRequestCloseShowPrivateKey = () => {
    this.setState({
      secretKey: '',
      accessKey: '',
      submitStatus: 'DEFAULT',
      privateKeyModalOpen: false
    })
  }

  onSubmitSuccess = fetch => data => {
    fetch()
    this.setState({
      secretKey: data.secret_key,
      accessKey: data.access_key,
      privateKeyModalOpen: true
    })
  }
  onClickAccessKeySwitch = ({ id, expired, fetch }) => async e => {
    await this.props.updateAccessKey({ id, expired })
  }

  rowAdminKeyRenderer = fetch => (key, data, rows) => {
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

  renderConfirmPrivateKeyModal () {
    return (
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
            Please copy and keep this pair of acesss and secret key. Secret key will use to open
            your encrypted information.
          </p>
          <InputContainer>
            <InputLabel>Access Key</InputLabel>
            <input readOnly value={this.state.accessKey} spellCheck='false' />
            <Copy data={this.state.accessKey} />
          </InputContainer>
          <InputContainer>
            <InputLabel>Secret key</InputLabel>
            <input readOnly value={this.state.secretKey} spellCheck='false' />
            <Copy data={this.state.secretKey} />
          </InputContainer>
        </ConfirmCreateKeyContainer>
      </ConfirmationModal>
    )
  }

  render () {
    const Fetcher = this.props.fetcher
    return (
      <Fetcher
        query={{
          page: queryString.parse(this.props.location.search)['access_key_page'],
          perPage: 10
        }}
        {...this.props}
        render={({ data, individualLoadingStatus, pagination, fetch }) => {
          const apiKeysRows = data.map(key => {
            return {
              key: key.access_key,
              id: key.id,
              user: key.account_id,
              created_at: key.created_at,
              status: key.expired,
              name: key.name || 'Not Provided',
              global_role: key.global_role || 'none'
            }
          })
          return (
            <KeySection>
              <Table
                loadingRowNumber={6}
                rows={apiKeysRows}
                rowRenderer={this.rowAdminKeyRenderer(fetch)}
                columns={columnsAdminKeys}
                loadingStatus={individualLoadingStatus}
                navigation
                isFirstPage={pagination.is_first_page}
                isLastPage={pagination.is_last_page}
                pageEntity='access_key_page'
              />
              <CreateAdminKeyModal
                open={this.props.createAdminKeyModalOpen}
                onRequestClose={this.props.onRequestClose}
                onSubmitSuccess={this.onSubmitSuccess(fetch)}
                closeTimeoutMS={0}
                loading={this.state.submitStatus === 'SUBMITTING'}
              />
              {this.renderConfirmPrivateKeyModal()}
            </KeySection>
          )
        }}
      />
    )
  }
}

export default enhance(ApiKeyPage)

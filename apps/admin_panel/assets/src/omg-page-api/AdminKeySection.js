import React, { Component } from 'react'
import { withRouter } from 'react-router-dom'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import moment from 'moment'

import { Switch, Icon } from '../omg-uikit'
import Table from '../omg-table'
import AccessKeyFetcher from '../omg-access-key/accessKeysFetcher'
import ConfirmationModal from '../omg-confirmation-modal'
import { createApiKey } from '../omg-api-keys/action'
import { createAccessKey, updateAccessKey, downloadKey } from '../omg-access-key/action'
import CreateAdminKeyModal from '../omg-create-admin-key-modal'
import queryString from 'query-string'
import Copy from '../omg-copy'
import { createSearchAdminKeyQuery } from '../omg-access-key/searchField'

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
  td:nth-child(2) {
    width: 20%;
    position: relative;
  }
  td:first-child div {
    overflow: hidden;
    text-overflow: ellipsis;
  }
  i[name='Copy'] {
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
  max-width: 500px;
  a:hover{
    text-decoration: underline;
  }
  
  h4 {
    padding-bottom: 10px;
  }
  p {
    font-size: 12px;
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
const enhance = compose(
  withRouter,
  connect(
    null,
    { createApiKey, createAccessKey, updateAccessKey, downloadKey }
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
    onRequestClose: PropTypes.func,
    columnsAdminKeys: PropTypes.array,
    search: PropTypes.string,
    downloadKey: PropTypes.func,
    match: PropTypes.object,
    history: PropTypes.object
  }

  static defaultProps = {
    fetcher: AccessKeyFetcher,
    columnsAdminKeys: [
      { key: 'key', title: 'ACCESS KEY' },
      { key: 'name', title: 'LABEL' },
      { key: 'global_role', title: 'GLOBAL ROLE' },
      { key: 'created_at', title: 'CREATED AT' },
      { key: 'status', title: 'STATUS' }
    ]
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
    fetch()
  }
  onClickDownloadKey = e => {
    this.props.downloadKey({
      accessKey: this.state.accessKey,
      secretKey: this.state.secretKey
    })
  }

  onClickRow = (data, index) => e => {
    const { keyType } = this.props.match.params
    this.props.history.push(`${keyType || 'keys/admin'}/${data.id}`)
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
            <Icon name='Key' /><span>{data}</span> <Copy data={data} />
          </KeyContainer>
        )
      case 'name':
        return (
          <KeyContainer>
            <span>{data}</span>
          </KeyContainer>
        )
      case 'global_role':
      case 'account_role':
        return _.startCase(data)
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
            An access key and a secret have been generated. In order to access the admin API
            programmatically, you will need to use them together. We do not store the secret key in
            our database for security reasons. This is the only time you will see it, so copy it and
            store it somewhere safe. Note that you will be able to get the access key anytime from
            the admin panel.
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
          <a onClick={this.onClickDownloadKey}>Download a CSV backup of your keys</a>
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
          perPage: 10,
          ...createSearchAdminKeyQuery(this.props.search)
        }}
        {...this.props}
        render={({ data, individualLoadingStatus, pagination, fetch }) => {
          const apiKeysRows = data.map((item, index) => {
            let role
            if (item.hasOwnProperty('key')) {
              role = item.role
              item = item.key
            }
            return {
              id: item.id,
              key: item.access_key,
              user: item.account_id,
              created_at: item.created_at,
              status: item.expired,
              name: item.name || 'Not Provided',
              global_role: item.global_role || 'none',
              account_role: role || 'none'
            }
          })
          return (
            <KeySection>
              <Table
                loadingRowNumber={6}
                rows={apiKeysRows}
                onClickRow={this.onClickRow}
                rowRenderer={this.rowAdminKeyRenderer(fetch)}
                columns={this.props.columnsAdminKeys}
                loadingStatus={individualLoadingStatus}
                navigation
                isFirstPage={pagination.is_first_page}
                isLastPage={pagination.is_last_page}
                pageEntity='access_key_page'
              />
              <CreateAdminKeyModal
                accountId={this.props.match.params.accountId}
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

import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import Table from '../omg-table'
import { Switch, Icon } from '../omg-uikit'
import ApiKeysFetcher from '../omg-api-keys/apiKeysFetcher'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { createApiKey, updateApiKey } from '../omg-api-keys/action'
import CreateClientKeyModal from '../omg-create-client-key-modal'
import queryString from 'query-string'
import { withRouter } from 'react-router-dom'
import moment from 'moment'
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
    border: none;
    width: 20%;
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

const columnsApiKey = [
  { key: 'key', title: 'ACCESS KEY' },
  { key: 'name', title: 'LABEL' },
  { key: 'created_at', title: 'CREATED AT' },
  { key: 'status', title: 'STATUS' }
]
const enhance = compose(
  withRouter,
  connect(
    null,
    { createApiKey, updateApiKey }
  )
)
class ClientKeySection extends Component {
  static propTypes = {
    createApiKey: PropTypes.func,
    updateApiKey: PropTypes.func,
    location: PropTypes.object,
    createClientKeyModalOpen: PropTypes.bool,
    onRequestClose: PropTypes.func,
    search: PropTypes.string,
    history: PropTypes.object
  }
  state = {
    submitStatus: 'DEFAULT'
  }

  onClickCreateClientKey = fetch => async e => {
    this.setState({ submitStatus: 'SUBMITTING' })
    try {
      await this.props.createApiKey({ name: this.state.name })
      fetch()
      this.props.onRequestClose()
      this.setState({ submitStatus: 'SUCCESS' })
    } catch (error) {
      this.setState({ submitStatus: 'FAILED' })
    }
  }
  onClickSwitch = ({ id, expired, fetch }) => async e => {
    await this.props.updateApiKey({ id, expired })
  }
  onClickRow = (data, index) => e => {
    this.props.history.push(`client/${data.id}`)
  }
  onSubmitSuccess = fetch => () => {
    fetch()
    this.setState({ createClientKeyModalOpen: false })
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
            <Icon name='Key' /><span>{data}</span> <Copy data={data} />
          </KeyContainer>
        )
      case 'name':
        return (
          <KeyContainer>
            <span>{data}</span>
          </KeyContainer>
        )
      case 'created_at':
        return moment(data).format()
      default:
        return data
    }
  }

  render () {
    return (
      <ApiKeysFetcher
        query={{
          page: queryString.parse(this.props.location.search)['api_key_page'],
          perPage: 10,
          ...createSearchAdminKeyQuery(this.props.search)
        }}
        {...this.props}
        render={({ data, individualLoadingStatus, pagination, fetch }) => {
          const apiKeysRows = data
            .filter(key => !key.deleted_at)
            .map(key => {
              return {
                key: key.key,
                id: key.id,
                name: key.name || 'Not Provided',
                created_at: key.created_at,
                status: key.expired,
                updated_at: key.updated_at
              }
            })
          return (
            <KeySection>
              <Table
                onClickRow={this.onClickRow}
                hoverEffect={false}
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
              <CreateClientKeyModal
                open={this.props.createClientKeyModalOpen}
                onRequestClose={this.props.onRequestClose}
                onSubmitSuccess={this.onSubmitSuccess(fetch)}
                onOk={this.onClickCreateClientKey(fetch)}
                loading={this.state.submitStatus === 'SUBMITTING'}
              />
            </KeySection>
          )
        }}
      />
    )
  }
}

export default enhance(ClientKeySection)

import React, { Component } from 'react'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import queryString from 'query-string'
import { withRouter } from 'react-router-dom'
import moment from 'moment'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import Table from '../omg-table'
import { Switch, Icon, Id } from '../omg-uikit'
import ApiKeysFetcher from '../omg-api-keys/apiKeysFetcher'
import { createApiKey, enableApiKey } from '../omg-api-keys/action'
import CreateClientKeyModal from '../omg-create-client-key-modal'
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
  display: flex;
  flex-direction: row;
  white-space: nowrap;
  span {
    vertical-align: middle;
  }

  i {
    margin-right: 5px;
  }
  i[name='Key'] {
    margin-right: 15px;
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
    { createApiKey, enableApiKey }
  )
)
class ClientKeySection extends Component {
  static propTypes = {
    createApiKey: PropTypes.func,
    enableApiKey: PropTypes.func,
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
  onClickSwitch = ({ id, enabled, fetch }) => async e => {
    e.stopPropagation()
    await this.props.enableApiKey({ id, enabled })
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
            onClick={this.onClickSwitch({ id: rows.id, enabled: rows.status, fetch })}
          />
        )
      case 'key':
        return (
          <KeyContainer>
            <Icon name='Key' />
            <Id maxChar={20}>{data}</Id>
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

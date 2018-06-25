import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon } from '../omg-uikit'
import CreateTokenModal from '../omg-create-token-modal'
import ExportModal from '../omg-export-modal'
import TokenProvider from '../omg-token/TokensProvider'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'
const TokenDetailPageContainer = styled.div`
  position: relative;
  display: flex;
  flex-direction: column;
  > div {
    flex: 1;
  }
`
const columns = [
  { key: 'token', title: 'TOKEN NAME', sort: true },
  { key: 'symbol', title: 'SYMBOL', sort: true },
  { key: 'created', title: 'CREATED DATE', sort: true }
]
class TokenDetailPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    history: PropTypes.object,
    location: PropTypes.object
  }
  state = {
    createTokenModalOpen: false,
    exportModalOpen: false
  }
  onClickCreateToken = () => {
    this.setState({ createTokenModalOpen: true })
  }
  onRequestCloseCreateToken = () => {
    this.setState({ createTokenModalOpen: false })
  }
  onClickExport = () => {
    this.setState({ exportModalOpen: true })
  }
  onRequestCloseExport = () => {
    this.setState({ exportModalOpen: false })
  }

  renderExportButton = () => {
    return (
      <Button size='small' styleType='ghost' onClick={this.onClickExport} key={'exports'}>
        <Icon name='Export' />
        <span>Export</span>
      </Button>
    )
  }
  renderTransferToken = () => {
    return (
      <Button size='small' styleType='secondary' onClick={this.onClickCreateToken} key={'transfer'}>
        <span>Transfer Token</span>
      </Button>
    )
  }
  renderMintTokenButton = () => {
    return (
      <Button size='small' onClick={this.onClickCreateToken} key={'mint'}>
        <Icon name='Plus' /> <span>Create Token</span>
      </Button>
    )
  }
  rowRenderer (key, data, rows) {
    if (key === 'created') {
      return moment(data).format('ddd, DD/MM/YYYY hh:mm:ss')
    }
    return data
  }
  onClickRow = (data, index) => e => {
    const { params } = this.props.match
    this.props.history.push(`/${params.accountId}/token/${data.id}`)
  }
  renderTokenDetailPage = ({ tokens, loadingStatus }) => {
    const data = tokens.map(token => {
      return {
        key: token.id,
        token: token.name,
        symbol: token.symbol,
        created: token.created_at,
        id: token.id
      }
    })
    return (
      <TokenDetailPageContainer>
        <TopNavigation
          title={'Token'}
          buttons={[
            // this.renderExportButton(),
            // this.renderTransferToken(),
            this.renderMintTokenButton()
          ]}
        />
        <SortableTable
          rows={data}
          columns={columns}
          loading={loadingStatus !== 'SUCCESS'}
          perPage={20}
          onClickRow={this.onClickRow}
          rowRenderer={this.rowRenderer}
        />

        <ExportModal open={this.state.exportModalOpen} onRequestClose={this.onRequestCloseExport} />
        <CreateTokenModal
          open={this.state.createTokenModalOpen}
          onRequestClose={this.onRequestCloseCreateToken}
        />
      </TokenDetailPageContainer>
    )
  }

  render () {
    return (
      <TokenProvider
        render={this.renderTokenDetailPage}
        {...this.state}
        search={queryString.parse(this.props.location.search).search}
      />
    )
  }
}

export default withRouter(TokenDetailPage)

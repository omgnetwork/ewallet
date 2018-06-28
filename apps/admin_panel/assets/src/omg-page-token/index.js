import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon, Avatar } from '../omg-uikit'
import CreateTokenModal from '../omg-create-token-modal'
import ExportModal from '../omg-export-modal'
import TokenFetcher from '../omg-token/tokensFetcher'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import { NameColumn } from '../omg-page-account'
import moment from 'moment'
import queryString from 'query-string'
const TokenDetailPageContainer = styled.div`
  position: relative;
  display: flex;
  flex-direction: column;
  > div {
    flex: 1;
  }
  td:first-child {
    width: 50%;
  }
  td:nth-child(2),
  td:nth-child(3) {
    width: 25%;
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
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func
  }
  state = {
    createTokenModalOpen: false,
    exportModalOpen: false,
    loadMoreTime: 1
  }
  componentWillReceiveProps = nextProps => {
    const search = queryString.parse(this.props.location.search).search
    const nextSearch = queryString.parse(nextProps.location.search).search
    if (search !== nextSearch) {
      this.setState({ loadMoreTime: 1 })
    }
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

  onClickLoadMore = e => {
    this.setState(({ loadMoreTime }) => ({ loadMoreTime: loadMoreTime + 1 }))
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
    if (key === 'token') {
      return (
        <NameColumn>
          <Avatar image={rows.avatar} /> <span>{data}</span>
        </NameColumn>
      )
    }
    return data
  }
  onClickRow = (data, index) => e => {
    const { params } = this.props.match
    this.props.history.push(`/${params.accountId}/token/${data.id}`)
  }
  renderTokenDetailPage = ({ data: tokens, individualLoadingStatus, pagination }) => {
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
        <TopNavigation title={'Token'} buttons={[this.renderMintTokenButton()]} />
        <SortableTable
          rows={data}
          columns={columns}
          loadingStatus={individualLoadingStatus}
          perPage={20}
          onClickRow={this.onClickRow}
          rowRenderer={this.rowRenderer}
          isFirstPage={pagination.is_first_page}
          isLastPage={pagination.is_last_page}
          navigation
          onClickLoadMore={this.onClickLoadMore}
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
      <TokenFetcher
        render={this.renderTokenDetailPage}
        {...this.state}
        {...this.props}
        query={{
          page: this.state.loadMoreTime,
          perPage: 15,
          search: queryString.parse(this.props.location.search).search
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(TokenDetailPage)

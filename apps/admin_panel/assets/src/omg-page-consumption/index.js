import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon } from '../omg-uikit'
import CreateAccountModal from '../omg-create-account-modal'
import ExportModal from '../omg-export-modal'
import ConsumptionFetcher from '../omg-consumption/consumptionsFetcher'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'
const ConsumptionPageContainer = styled.div`
  position: relative;
  display: flex;
  flex-direction: column;
  padding-bottom: 50px;
  > div {
    flex: 1;
  }
  td {
    white-space: nowrap;
  }
  td:nth-child(2),
  td:nth-child(3) {
    width: 25%;
  }
`
const SortableTableContainer = styled.div`
  position: relative;
  i[name="Consumption"] {
    color: ${props => props.theme.colors.BL400};
  }
`
export const NameColumn = styled.div`
  > span {
    margin-left: 10px;
  }
`
class ConsumptionPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    history: PropTypes.object,
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func
  }
  constructor (props) {
    super(props)
    this.state = {
      createAccountModalOpen: false,
      exportModalOpen: false,
      loadMoreTime: 1
    }
    this.columns = [
      { key: 'id', title: 'REQUEST ID', sort: true },
      { key: 'type', title: 'TYPE', sort: true },
      { key: 'amount', title: 'AMOUNT', sort: true },
      { key: 'created_by', title: 'TO' },
      { key: 'created_at', title: 'CREATED DATE', sort: true },
      { key: 'require_confirmation', title: 'CONFIRMATION' }
    ]
  }
  renderCreateAccountButton = () => {
    return (
      <Button size='small' onClick={this.onClickCreateAccount} key={'create'}>
        <Icon name='Plus' /> <span>Create Account</span>
      </Button>
    )
  }
  onClickRow = (data, index) => e => {
    const { params } = this.props.match
    this.props.history.push(`/${params.accountId}/account/${data.id}`)
  }
  rowRenderer (key, data, rows) {
    if (key === 'require_confirmation') {
      return data ? 'Yes' : 'No'
    }
    if (key === 'id') {
      return (
        <NameColumn>
          <Icon name='Consumption' /> <span>{data}</span>
        </NameColumn>
      )
    }
    if (key === 'type') {
      return _.get(rows, 'transaction_request.type')
    }
    if (key === 'amount') {
      return `${(data / rows.token.subunit_to_unit || 0).toLocaleString()} ${rows.token.symbol}`
    }
    if (key === 'created_by') {
      return rows.user_id || rows.account.name || rows.account_id
    }
    if (key === 'created_at') {
      return moment(data).format('ddd, DD/MM/YYYY hh:mm:ss')
    }
    if (key === 'updated_at') {
      return moment(data).format('ddd, DD/MM/YYYY hh:mm:ss')
    }
    return data
  }
  renderConsumptionPage = ({ data: consumptions, individualLoadingStatus, pagination, fetch }) => {
    return (
      <ConsumptionPageContainer>
        <TopNavigation title={'Consumptions'} buttons={[]} />
        <SortableTableContainer innerRef={table => (this.table = table)} loadingStatus={individualLoadingStatus}>
          <SortableTable
            rows={consumptions}
            columns={this.columns}
            loadingStatus={individualLoadingStatus}
            rowRenderer={this.rowRenderer}
            onClickRow={this.onClickRow}
            isFirstPage={pagination.is_first_page}
            isLastPage={pagination.is_last_page}
            navigation
            onClickLoadMore={this.onClickLoadMore}
          />
        </SortableTableContainer>
        <CreateAccountModal
          open={this.state.createAccountModalOpen}
          onRequestClose={this.onRequestCloseCreateAccount}
          onCreateAccount={fetch}
        />
        <ExportModal open={this.state.exportModalOpen} onRequestClose={this.onRequestCloseExport} />
      </ConsumptionPageContainer>
    )
  }

  render () {
    return (
      <ConsumptionFetcher
        render={this.renderConsumptionPage}
        {...this.state}
        {...this.props}
        query={{
          page: queryString.parse(this.props.location.search).page,
          perPage: 10,
          search: queryString.parse(this.props.location.search).search
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(ConsumptionPage)

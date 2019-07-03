import React, { Component } from 'react'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'

import TopNavigation from '../omg-page-layout/TopNavigation'
import SortableTable from '../omg-table'
import { Button, Icon, Id } from '../omg-uikit'
import ConsumptionFetcher from '../omg-consumption/consumptionsFetcher'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import AdvancedFilter from '../omg-advanced-filter'

const ConsumptionPageContainer = styled.div`
  position: relative;
  padding-bottom: 50px;
  td {
    white-space: nowrap;
  }
  td:first-child {
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
  td:nth-child(2) {
    width: 150px;
    max-width: 150px;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  tr:hover {
    td:nth-child(1) {
      i {
        visibility: visible;
      }
    }
  }
  i[name='Copy'] {
    cursor: pointer;
    visibility: hidden;
    color: ${props => props.theme.colors.S500};
    :hover {
      color: ${props => props.theme.colors.B300};
    }
  }
`
const SortableTableContainer = styled.div`
  position: relative;
  i[name='Consumption'] {
    color: ${props => props.theme.colors.B100};
    padding: 8px;
    border-radius: 6px;
    border: 1px solid ${props => props.theme.colors.S400};
  }
`
const StyledIcon = styled.span`
  i {
    margin-right: 10px;
    font-size: 14px;
    font-weight: 400;
  }
`
export const NameColumn = styled.div`
  display: flex;
  flex-direction: row;
  > span {
    margin-left: 10px;
  }
  i[name='Consumption'] {
    margin-right: 15px;
    color: ${props => props.theme.colors.B100};
    padding: 8px;
    border-radius: 6px;
    border: 1px solid ${props => props.theme.colors.S400};
  }
`
class ConsumptionPage extends Component {
  static propTypes = {
    divider: PropTypes.bool,
    showFilter: PropTypes.bool,
    history: PropTypes.object,
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func,
    query: PropTypes.object,
    fetcher: PropTypes.func
  }
  static defaultProps = {
    query: {},
    showFilter: true,
    fetcher: ConsumptionFetcher
  }
  constructor (props) {
    super(props)
    this.columns = [
      { key: 'id', title: 'CONSUMPTION ID', sort: true },
      { key: 'type', title: 'TYPE', sort: true },
      { key: 'estimated_consumption_amount', title: 'AMOUNT', sort: true },
      { key: 'status', title: 'STATUS', sort: true },
      { key: 'created_by', title: 'CONSUMER' },
      { key: 'created_at', title: 'CREATED AT', sort: true }
    ]
  }
  state = {
    advancedFilterModalOpen: false,
    matchAll: [],
    matchAny: []
  }
  renderCreateAccountButton = () => {
    return (
      <Button size='small' onClick={this.onClickCreateAccount} key={'create'}>
        <Icon name='Plus' />
        <span>Create Account</span>
      </Button>
    )
  }
  onClickRow = (data, index) => e => {
    const searchObject = queryString.parse(this.props.location.search)
    this.props.history.push({
      search: queryString.stringify({
        ...searchObject,
        'show-consumption-tab': data.id
      })
    })
  }
  renderCreator = consumption => {
    return (
      <span>
        {consumption.account && (
          <span>
            <StyledIcon>
              <Icon name='Merchant' />
            </StyledIcon>
            {consumption.account.name}
          </span>
        )}
        {consumption.user && consumption.user.email && (
          <span>
            <StyledIcon>
              <Icon name='People' />
            </StyledIcon>
            {consumption.user.email}
          </span>
        )}
        {consumption.user && consumption.user.provider_user_id && (
          <span>
            <StyledIcon>
              <Icon name='People' />
            </StyledIcon>
            {consumption.user.provider_user_id}
          </span>
        )}
      </span>
    )
  }
  rowRenderer = (key, data, rows) => {
    if (key === 'require_confirmation') {
      return data ? 'Yes' : 'No'
    }
    if (key === 'id') {
      return (
        <NameColumn>
          <StyledIcon>
            <Icon name='Consumption' />
          </StyledIcon>
          <Id>{data}</Id>
        </NameColumn>
      )
    }
    if (key === 'type') {
      return _.upperFirst(_.get(rows, 'transaction_request.type'))
    }
    if (key === 'status') {
      return _.upperFirst(data)
    }
    if (key === 'estimated_consumption_amount') {
      return `${formatReceiveAmountToTotal(data, rows.token.subunit_to_unit)} ${
        rows.token.symbol
      }`
    }
    if (key === 'created_by') {
      return this.renderCreator(rows)
    }
    if (key === 'created_at') {
      return moment(data).format()
    }
    if (key === 'updated_at') {
      return moment(data).format()
    }
    return data
  }
  renderAdvancedFilterButton = () => {
    return (
      <Button
        key='filter'
        size='small'
        styleType='secondary'
        onClick={() => this.setState({ advancedFilterModalOpen: true })}
      >
        <Icon name='Filter' /><span>Filter</span>
      </Button>
    )
  }
  renderConsumptionPage = ({
    data: consumptions,
    individualLoadingStatus,
    pagination,
    fetch
  }) => {
    const {
      location: { search }
    } = this.props
    const activeIndexKey = queryString.parse(search)['show-consumption-tab']
    return (
      <ConsumptionPageContainer>
        <TopNavigation
          divider={this.props.divider}
          title={'Transaction Consumptions'}
          buttons={[this.props.showFilter && this.renderAdvancedFilterButton()]}
        />
        <AdvancedFilter
          title='Filter Transaction Consumption'
          page='transaction-consumptions'
          open={this.state.advancedFilterModalOpen}
          onRequestClose={() => this.setState({ advancedFilterModalOpen: false })}
          onFilter={({ matchAll, matchAny }) => this.setState({ matchAll, matchAny })}
        />
        <SortableTableContainer
          ref={table => (this.table = table)}
          loadingStatus={individualLoadingStatus}
        >
          <SortableTable
            rows={consumptions}
            columns={this.columns}
            loadingStatus={individualLoadingStatus}
            rowRenderer={this.rowRenderer}
            onClickRow={this.onClickRow}
            isFirstPage={pagination.is_first_page}
            isLastPage={pagination.is_last_page}
            navigation
            activeIndexKey={activeIndexKey}
          />
        </SortableTableContainer>
      </ConsumptionPageContainer>
    )
  }

  render () {
    const Fetcher = this.props.fetcher
    return (
      <Fetcher
        render={this.renderConsumptionPage}
        {...this.state}
        {...this.props}
        query={{
          page: queryString.parse(this.props.location.search).page,
          perPage: Math.floor(window.innerHeight / 65),
          matchAll: this.state.matchAll,
          matchAny: this.state.matchAny,
          searchTerms: {
            id: queryString.parse(this.props.location.search).search
          },
          ...this.props.query
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(ConsumptionPage)

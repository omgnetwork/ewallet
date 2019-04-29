import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon } from '../omg-uikit'
import ConsumptionFetcher from '../omg-consumption/consumptionsFetcher'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import Copy from '../omg-copy'
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
  td:first-child{
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
    margin-left: 5px;
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
    margin-top: -3px;
    margin-right: 10px;
    margin-top
    font-size: 14px;
    font-weight: 400;
  }
`
export const NameColumn = styled.div`
  > span {
    margin-left: 10px;
  }
`
class ConsumptionPage extends Component {
  static propTypes = {
    divider: PropTypes.bool,
    history: PropTypes.object,
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func,
    query: PropTypes.object,
    fetcher: PropTypes.func
  }
  static defaultProps = {
    query: {},
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
  renderCreateAccountButton = () => {
    return (
      <Button size='small' onClick={this.onClickCreateAccount} key={'create'}>
        <Icon name='Plus' /> <span>Create Account</span>
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
        {consumption.account &&
          <span>
            <StyledIcon><Icon name='Merchant' /></StyledIcon>
            {consumption.account.name}
          </span>

        }
        {consumption.user && consumption.user.email &&
          <span>
            <StyledIcon><Icon name='People' /></StyledIcon>
            {consumption.user.email}
          </span>
        }
        {consumption.user && consumption.user.provider_user_id &&
          <span>
            <StyledIcon><Icon name='People' /></StyledIcon>
            {consumption.user.provider_user_id}
          </span>
        }
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
          <Icon name='Consumption' /> <span>{data}</span> <Copy data={data} />
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
      return `${formatReceiveAmountToTotal(data, rows.token.subunit_to_unit)} ${rows.token.symbol}`
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
  renderConsumptionPage = ({ data: consumptions, individualLoadingStatus, pagination, fetch }) => {
    const activeIndexKey = queryString.parse(this.props.location.search)['show-consumption-tab']
    return (
      <ConsumptionPageContainer>
        <TopNavigation divider={this.props.divider} title={'Transaction Consumptions'} buttons={[]} />
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
          searchTerms: { id: queryString.parse(this.props.location.search).search },
          ...this.props.query
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(ConsumptionPage)

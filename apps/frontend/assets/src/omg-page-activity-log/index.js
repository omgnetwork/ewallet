import React, { Component } from 'react'
import styled from 'styled-components'
import { withRouter, Link } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'

import TopNavigation from '../omg-page-layout/TopNavigation'
import SortableTable from '../omg-table'
import ActivityLogFetcher from '../omg-activity-log/ActivityLogFetcher'
import { createSearchActivityLogQuery } from './searchField'
import { Icon, Button } from '../omg-uikit'
import AdvancedFilter from '../omg-advanced-filter'

const ActivityLogPageContainer = styled.div`
  position: relative;
  padding-bottom: 50px;
  td:first-child {
    width: 30%;
    max-width: 30%;
  }
  td:nth-child(2),
  td:nth-child(3) {
    width: 25%;
  }
  td {
    white-space: nowrap;
    a:hover {
      text-decoration: underline;
    }
  }
  tr:hover {
    td:nth-child(2) {
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
  td:nth-child(2),
  td:nth-child(3) {
    width: 25%;
  }
`
const SortableTableContainer = styled.div`
  position: relative;
`
export const NameColumn = styled.div`
  > span {
    margin-left: 10px;
  }
`
const OriginatorDetailContianer = styled.div`
  color: ${props => props.theme.colors.B100};
`
class ActivityLogPage extends Component {
  static propTypes = {
    divider: PropTypes.bool,
    showFilter: PropTypes.bool,
    history: PropTypes.object,
    query: PropTypes.oneOfType([PropTypes.func, PropTypes.object]),
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func,
    topNavigation: PropTypes.bool
  }

  static defaultProps = {
    topNavigation: true,
    showFilter: true
  }

  state = {
    advancedFilterModalOpen: false,
    matchAll: [],
    matchAny: []
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

  onClickRow = (data, index) => e => {
    // Click a link, ignore
    if (e.target.nodeName === 'A') return
    const searchObject = queryString.parse(this.props.location.search)
    this.props.history.push({
      search: queryString.stringify({
        ...searchObject,
        'show-activity-tab': data.id
      })
    })
  }

  getColumns = accounts => {
    return [
      { key: 'originator', title: 'ORIGINATOR' },
      { key: 'action', title: 'ACTION' },
      { key: 'target', title: 'TARGET' },
      { key: 'created_at', title: 'CREATED AT' }
    ]
  }

  getOriginatorOrDetail (originatorType, originatorOrTarget) {
    switch (originatorType) {
      case 'account':
        return originatorOrTarget.name || originatorOrTarget.calling_name
      case 'transaction':
        return (
          <span>
            {originatorOrTarget.from.address} <Icon name='Arrow-Right' />{' '}
            {originatorOrTarget.to.address}{' '}
          </span>
        )
      case 'user':
        return originatorOrTarget.email || originatorOrTarget.username || originatorOrTarget.id
      case 'token':
        return originatorOrTarget.name || originatorOrTarget.calling_name
      case 'setting':
        return _.startCase(originatorOrTarget.key)
      case 'key':
        return _.startCase(originatorOrTarget.key)

      case 'mint':
        return originatorOrTarget.token.name
      case 'exchange_pair':
        return (
          <span>
            {originatorOrTarget.from_token.name} <Icon name='Arrow-Right' />
            {originatorOrTarget.to_token.name}
          </span>
        )
      case 'membership':
        return originatorOrTarget.account.name

      default:
        return null
    }
  }
  rowRenderer = (key, data, row) => {
    switch (key) {
      case 'originator':
        return (
          <span>
            {row.originator ? (
              <span>
                <span>{_.startCase(row.originator_type)}</span>{' '}
                {this.getLink(row.originator_type, row.originator.id || row.originator.address)}
                <OriginatorDetailContianer>
                  {this.getOriginatorOrDetail(row.originator_type, row.originator)}
                </OriginatorDetailContianer>
              </span>
            ) : (
              _.startCase(row.originator_type)
            )}
          </span>
        )
      case 'target':
        return (
          <span>
            {row.target ? (
              <span>
                <span>{_.startCase(row.target_type)}</span>{' '}
                {this.getLink(row.target_type, row.target.id || row.target.address)}
                <OriginatorDetailContianer>
                  {this.getOriginatorOrDetail(row.target_type, row.target)}
                </OriginatorDetailContianer>
              </span>
            ) : (
              _.startCase(row.target_type)
            )}
          </span>
        )
      case 'created_at':
        return moment(data).format()
      case 'avatar':
        return null
      case 'action':
        return _.startCase(data)
      default:
        return data
    }
  }
  getLink (type, id) {
    switch (type) {
      case 'wallet':
        return <Link to={`/wallets/${id}`}>{id}</Link>
      case 'account':
        return <Link to={`/accounts/${id}`}>{id}</Link>
      case 'user':
        return <Link to={`/users/${id}`}>{id}</Link>
      case 'token':
        return <Link to={`/tokens/${id}`}>{id}</Link>
      case 'transaction':
        const transactionQuery = {
          ...queryString.parse(this.props.location.search),
          'show-transaction-tab': id
        }
        return (
          <Link
            to={{
              search: queryString.stringify(transactionQuery)
            }}
          >
            {id}
          </Link>
        )
      case 'transaction_request':
        const transactionRequestQuery = {
          ...queryString.parse(this.props.location.search),
          'show-request-tab': id
        }
        return (
          <Link
            to={{
              search: queryString.stringify(transactionRequestQuery)
            }}
          >
            {id}
          </Link>
        )
      case 'transaction_consumption':
        const transactionConsumptionQuery = {
          ...queryString.parse(this.props.location.search),
          'show-consumption-tab': id
        }
        return (
          <Link
            to={{
              search: queryString.stringify(transactionConsumptionQuery)
            }}
          >
            {id}
          </Link>
        )
      default:
        return null
    }
  }

  renderActivityPage = ({ data: activities, individualLoadingStatus, pagination, fetch }) => {
    return (
      <ActivityLogPageContainer>
        {this.props.topNavigation && (
          <TopNavigation
            divider={this.props.divider}
            title={'Activity Logs'}
            buttons={[this.props.showFilter && this.renderAdvancedFilterButton()]}
            normalPlaceholder='originator id, action'
          />
        )}
        <AdvancedFilter
          title='Filter Activity Log'
          page='activitylogs'
          open={this.state.advancedFilterModalOpen}
          onRequestClose={() => this.setState({ advancedFilterModalOpen: false })}
          onFilter={({ matchAll, matchAny }) => this.setState({ matchAll, matchAny })}
        />
        <SortableTableContainer
          ref={table => (this.table = table)}
          loadingStatus={individualLoadingStatus}
        >
          <SortableTable
            activeIndexKey={queryString.parse(this.props.location.search)['show-activity-tab']}
            rows={activities}
            columns={this.getColumns()}
            loadingStatus={individualLoadingStatus}
            rowRenderer={this.rowRenderer}
            isFirstPage={pagination.is_first_page}
            isLastPage={pagination.is_last_page}
            navigation
            onClickRow={this.onClickRow}
          />
        </SortableTableContainer>
      </ActivityLogPageContainer>
    )
  }

  render () {
    const search = queryString.parse(this.props.location.search).search
    const query =
      typeof this.props.query === 'function' ? this.props.query(search) : this.props.query
    return (
      <ActivityLogFetcher
        render={this.renderActivityPage}
        {...this.state}
        {...this.props}
        query={{
          page: Number(queryString.parse(this.props.location.search).page),
          matchAll: this.state.matchAll,
          matchAny: [
            ...createSearchActivityLogQuery(search).matchAny,
            ...this.state.matchAny
          ],
          ...query
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(ActivityLogPage)

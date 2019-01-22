import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import ActivityLogFetcher from '../omg-activity-log/ActivityLogFetcher'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'
import Link from '../omg-links'
import { createSearchActivityLogQuery } from './searchField'
import { Icon } from '../omg-uikit'
const AccountPageContainer = styled.div`
  position: relative;
  display: flex;
  flex-direction: column;
  padding-bottom: 50px;
  > div {
    flex: 1;
  }
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
    margin-left: 5px;
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
class AccountPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    history: PropTypes.object,
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func
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
      { key: 'created_at', title: 'CREATED DATE' }
    ]
  }

  getOriginatorDetail (originatorType, originator) {
    switch (originatorType) {
      case 'account':
        return originator.name || originator.calling_name
      case 'transaction':
        return (
          <span>
            {originator.from.address} <Icon name='Arrow-Right' /> {originator.to.address}{' '}
          </span>
        )
      case 'user':
        return originator.email || originator.username || originator.id
      case 'token':
        return originator.name || originator.calling_name

      default:
        return originatorType
    }
  }
  rowRenderer = (key, data, row) => {
    switch (key) {
      case 'originator':
        return (
          <span>
            {row.originator ? (
              <span>
                <span>{_.capitalize(row.originator_type)}</span>{' '}
                {this.getLink(row.originator_type, row.originator.id || row.originator.address)}
                <OriginatorDetailContianer>
                  {this.getOriginatorDetail(row.originator_type, row.originator)}
                </OriginatorDetailContianer>
              </span>
            ) : (
              _.capitalize(row.originator_type)
            )}
          </span>
        )
      case 'target':
        return (
          <span>
            {row.target ? (
              <span>
                <span>{_.capitalize(row.target_type)}</span>{' '}
                {this.getLink(row.target_type, row.target.id || row.target.address)}
                <OriginatorDetailContianer>
                  {this.getOriginatorDetail(row.target_type, row.target)}
                </OriginatorDetailContianer>
              </span>
            ) : (
              _.capitalize(row.target_type)
            )}
          </span>
        )
      case 'created_at':
        return moment(data).format('ddd, DD/MM/YYYY hh:mm:ss')
      case 'avatar':
        return null
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
        const query = {
          ...queryString.parse(this.props.location.search),
          'show-transaction-tab': id
        }
        return (
          <Link
            to={{
              search: queryString.stringify(query)
            }}
          >
            {id}
          </Link>
        )
      default:
        return <span>{id}</span>
    }
  }
  renderActivityPage = ({ data: activities, individualLoadingStatus, pagination, fetch }) => {
    return (
      <AccountPageContainer>
        <TopNavigation
          title={'Activity Logs'}
          buttons={[]}
          normalPlaceholder='originator id, action'
        />
        <SortableTableContainer
          innerRef={table => (this.table = table)}
          loadingStatus={individualLoadingStatus}
        >
          <SortableTable
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
      </AccountPageContainer>
    )
  }

  render () {
    const search = queryString.parse(this.props.location.search).search
    return (
      <ActivityLogFetcher
        render={this.renderActivityPage}
        {...this.state}
        {...this.props}
        query={{
          page: queryString.parse(this.props.location.search).page,
          ...createSearchActivityLogQuery(search)
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(AccountPage)

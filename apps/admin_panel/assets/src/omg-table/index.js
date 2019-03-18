import React, { PureComponent } from 'react'
import { Table, Icon, Button } from '../omg-uikit'
import { withRouter } from 'react-router'
import queryString from 'query-string'
import PropTypes from 'prop-types'
import { DropdownBoxItem, DropdownBox } from '../omg-uikit/dropdown'
import withDropdownState from '../omg-uikit/dropdown/withDropdownState'
import styled from 'styled-components'

export const ThContent = styled.div`
  padding: 4px 10px;
  letter-spacing: 1px;
  font-size: 10px;
  font-weight: 600;
  color: ${props => (props.active ? props.theme.colors.B400 : props.theme.colors.B100)};
`
const LoadMoreButton = styled(Button)`
  padding-top: 5px;
  padding-bottom: 5px;
  i {
    margin-right: 5px;
  }
`
const TableContainer = styled.div`
  width: 100%;
  table {
    width: 100%;
    text-align: left;
    tbody tr:hover {
      background-color: ${props => props.theme.colors.S100};
    }
    tbody td {
      border-bottom: 1px solid ${props => props.theme.colors.S200};
    }
    tr {
      cursor: pointer;
    }
    td {
      opacity: ${props => (props.loading && props.loadingEffect ? 0.6 : 1)};
      transition: 0.1s;
      padding: 10px;
      vertical-align: middle;
      color: ${props => props.theme.colors.B200};
      :first-child {
        padding-left: 10px;
      }
      :last-child {
        padding-right: 10px;
      }
    }
    th {
      white-space: nowrap;
      padding: 8px 0;
      cursor: pointer;
    }
  }
`
const NavigationContainer = styled.div`
  text-align: right;
  padding-top: 40px;
  > button {
    padding: 5px 10px;
    i {
      line-height: 12px;
    }
  }
  > button:first-child {
    margin-right: 5px;
  }
`

class SortableTable extends PureComponent {
  static propTypes = {
    history: PropTypes.object,
    location: PropTypes.object,
    rows: PropTypes.array,
    columns: PropTypes.array,
    loadingStatus: PropTypes.string,
    perPage: PropTypes.number,
    rowRenderer: PropTypes.func,
    onClickRow: PropTypes.func,
    isLastPage: PropTypes.bool,
    isFirstPage: PropTypes.bool,
    navigation: PropTypes.bool,
    onClickLoadMore: PropTypes.func,
    pagination: PropTypes.bool,
    pageEntity: PropTypes.string,
    loadingEffect: PropTypes.bool
  }
  static defaultProps = {
    pageEntity: 'page',
    loadingEffect: true,
    navigation: false
  }

  constructor (props) {
    super(props)
    this._onClickPrev = _.throttle(this.onClickPrev, 500, {
      leading: true,
      trailing: true
    })
    this._onClickNext = _.throttle(this.onClickNext, 500, {
      leading: true,
      trailing: true
    })
  }

  onSelectFilter = (col, item) => {
    const oldSearchObj = queryString.parse(this.props.location.search)
    this.props.history.push({
      search: queryString.stringify({
        ...oldSearchObj,
        ...{ [`filter-${col.key}`]: item }
      })
    })
  }
  onClickPagination = page => {
    const oldSearchObj = queryString.parse(this.props.location.search)
    this.props.history.push({
      search: queryString.stringify({
        ...oldSearchObj,
        ...{ page }
      })
    })
  }
  onClickSort = col => {
    const searchObject = queryString.parse(this.props.location.search)
    const sortOrderKey = 'sort-order'
    const sortByKey = 'sort-by'
    const sortOrder = searchObject[sortOrderKey]
    this.props.history.push({
      search: queryString.stringify({
        ...searchObject,
        ...{ [sortOrderKey]: sortOrder === 'asc' ? 'desc' : 'asc' },
        ...{ [sortByKey]: col.key }
      })
    })
  }
  getPage = () => {
    const searchObject = queryString.parse(this.props.location.search)
    return Number(searchObject[this.props.pageEntity]) || 1
  }
  onClickPrev = e => {
    if (!this.props.isFirstPage) {
      const searchObject = queryString.parse(this.props.location.search)
      this.props.history.push({
        search: queryString.stringify({
          ...searchObject,
          ...{ [this.props.pageEntity]: Number(searchObject[this.props.pageEntity]) - 1 }
        })
      })
    }
  }
  onClickNext = e => {
    if (!this.props.isLastPage) {
      const searchObject = queryString.parse(this.props.location.search)
      this.props.history.push({
        search: queryString.stringify({
          ...searchObject,
          ...{ [this.props.pageEntity]: Number(searchObject[this.props.pageEntity] || 1) + 1 }
        })
      })
    }
  }

  columnRenderer = col => {
    const searchObject = queryString.parse(this.props.location.search)
    const filter = searchObject[`filter-${col.key}`]
    if (col.sort) {
      return (
        <SortHeader
          key={col.key}
          col={col}
          active={searchObject['sort-by'] === col.key}
          sortOrder={searchObject['sort-order']}
          onClickSort={this.onClickSort}
        />
      )
    }
    if (col.filter) {
      return (
        <FilterHeader
          col={col}
          onSelectFilter={this.onSelectFilter}
          filterOptions={col.filterOptions}
          selectedItem={filter}
          key={col.key}
        />
      )
    }
    if (col.hide) {
      return null
    }
    return (
      <th key={col.key}>
        <ThContent>{col.title}</ThContent>
      </th>
    )
  }

  getFilteredData = () => {
    let shouldFilter = this.props.location.search
    const filterQuery = _.reduce(
      queryString.parse(this.props.location.search),
      (prev, curr, key) => {
        const split = key.split('-')
        if (split[0] === 'filter') {
          prev[split[1]] = curr
        }
        return prev
      },
      {}
    )
    const sortBy = [queryString.parse(this.props.location.search)['sort-by']]
    const sortOrder = [queryString.parse(this.props.location.search)['sort-order']]
    const result = shouldFilter
      ? _.chain(this.props.rows)
          .filter(d => {
            return _.reduce(
              filterQuery,
              (prev, value, key) => {
                return prev && (value === 'ALL' || d[key] === value)
              },
              true
            )
          })
          .orderBy(sortBy, sortOrder)
          .value()
      : this.props.rows
    return result
  }
  renderLoadMore = () => {
    return (
      <LoadMoreButton
        styleType='secondary'
        onClick={this.props.onClickLoadMore}
        disabled={this.props.isLastPage}
        size='small'
      >
        <Icon name='Chevron-Down' />
        <span>Load More...</span>
      </LoadMoreButton>
    )
  }
  render () {
    return (
      <TableContainer
        loading={this.props.loadingStatus === 'PENDING'}
        loadingEffect={this.props.loadingEffect}
      >
        <Table
          {...this.props}
          columns={this.props.columns}
          rows={this.getFilteredData()}
          columnRenderer={this.columnRenderer}
          onClickColumn={this.onClickColumn}
          rowRenderer={this.props.rowRenderer}
          onClickRow={this.props.onClickRow}
          onClickPagination={this.onClickPagination}
          loading={
            this.props.loadingStatus === 'INITIATED' || this.props.loadingStatus === 'DEFAULT'
          }
          pagination={this.props.pagination}
          page={this.getPage()}
          perPage={this.props.perPage}
        />
        {this.props.navigation &&
          this.props.loadingStatus === 'SUCCESS' &&
          !(this.props.isFirstPage && this.props.isLastPage) && (
            <NavigationContainer>
              <Button
                onClick={this._onClickPrev}
                styleType='secondary'
                disabled={this.props.isFirstPage}
                style={{ pointerEvent: this.props.loadingStatus !== 'SUCCESS' ? 'none' : 'auto' }}
              >
                <Icon name='Chevron-Left' />
              </Button>
              <Button
                onClick={this._onClickNext}
                styleType='secondary'
                disabled={this.props.isLastPage}
                style={{ pointerEvent: this.props.loadingStatus !== 'SUCCESS' ? 'none' : 'auto' }}
              >
                <Icon name='Chevron-Right' />
              </Button>
            </NavigationContainer>
          )}
      </TableContainer>
    )
  }
}

class SortHeader extends React.Component {
  static propTypes = {
    onClickSort: PropTypes.func,
    col: PropTypes.object,
    active: PropTypes.bool,
    sortOrder: PropTypes.string
  }
  onClickSort = e => {
    this.props.onClickSort(this.props.col)
  }
  render () {
    return (
      <th key={`col-header-${this.props.col.key}`} onClick={this.onClickSort}>
        <ThContent active={this.props.active}>
          <span>{this.props.col.title}</span>{' '}
          {this.props.active ? (
            this.props.sortOrder === 'asc' ? (
              <Icon name='Arrow-Up' />
            ) : (
              <Icon name='Arrow-Down' />
            )
          ) : null}
        </ThContent>
      </th>
    )
  }
}
const FilterHeader = withDropdownState(
  class FilterHeader extends React.Component {
    static propTypes = {
      filterOptions: PropTypes.array,
      onClickButton: PropTypes.func,
      col: PropTypes.object,
      selectedItem: PropTypes.string,
      open: PropTypes.bool,
      onSelectFilter: PropTypes.func,
      closeDropdown: PropTypes.func
    }
    onClickItem = e => {
      this.props.closeDropdown()
    }
    render () {
      return (
        <th key={`col-header-${this.props.col.key}`} onClick={this.props.onClickButton}>
          <ThContent>
            <div style={{ display: 'inline-block', position: 'relative' }}>
              <span>
                {this.props.col.title} {this.props.selectedItem && `(${this.props.selectedItem}) `}
              </span>
              {this.props.open ? <Icon name='Chevron-Up' /> : <Icon name='Chevron-Down' />}
              {this.props.open && (
                <DropdownBox>
                  {this.props.filterOptions.map(x => {
                    return (
                      <DropdownBoxItem onClick={e => this.props.onSelectFilter(this.props.col, x)}>
                        {x}
                      </DropdownBoxItem>
                    )
                  })}
                </DropdownBox>
              )}
            </div>
          </ThContent>
        </th>
      )
    }
  }
)
export default withRouter(SortableTable)

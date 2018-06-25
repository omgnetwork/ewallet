import React, { PureComponent } from 'react'
import { Table, Icon } from '../omg-uikit'
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
const TableContainer = styled.div`
  table {
    width: 100%;
    text-align: left;
    thead {
      tr {
        border-top: 1px solid ${props => props.theme.colors.S400};
        border-bottom: 1px solid ${props => props.theme.colors.S400};
      }
    }
    * {
      vertical-align: middle;
    }
    tbody tr:hover {
      background-color: ${props => props.theme.colors.S100};
    }
    tr {
      border-bottom: 1px solid ${props => props.theme.colors.S300};
      padding: 20px 0;
      cursor: pointer;
    }
    td {
      padding: 10px;
      vertical-align: top;
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
      :not(:last-child) {
        ${ThContent} {
          border-right: 1px solid ${props => props.theme.colors.S400};
        }
      }
    }
  }
`

class SortableTable extends PureComponent {
  static propTypes = {
    history: PropTypes.object,
    location: PropTypes.object,
    dataSource: PropTypes.oneOfType([PropTypes.array]),
    columns: PropTypes.oneOfType([PropTypes.array]),
    loading: PropTypes.bool,
    perPage: PropTypes.number,
    rowRenderer: PropTypes.func,
    onClickRow: PropTypes.func
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
    const key = `sort-${col.key}`
    const sortOrder = searchObject[key]
    this.props.history.push({
      search: queryString.stringify({
        ...searchObject,
        ...{ [key]: sortOrder === 'asc' ? 'desc' : 'asc' },
        ...{ 'main-sort': col.key }
      })
    })
  }
  getPage = () => {
    const searchObject = queryString.parse(this.props.location.search)
    return Number(searchObject.page) || 1
  }
  columnRenderer = col => {
    const searchObject = queryString.parse(this.props.location.search)
    const key = `sort-${col.key}`
    const sortOrder = searchObject[key]
    const filter = searchObject[`filter-${col.key}`]
    if (col.sort) {
      return (
        <SortHeader
          key={col.key}
          col={col}
          active={searchObject['main-sort'] === col.key}
          onClickSort={this.onClickSort}
          sortOrder={sortOrder}
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
    const sortQuery = _.reduce(
      queryString.parse(this.props.location.search),
      (prev, curr, key) => {
        const split = key.split('-')
        if (split[0] === 'sort') prev[split[1]] = curr
        return prev
      },
      {}
    )
    const mainSort = queryString.parse(this.props.location.search)['main-sort']
    const sortKeys = _.uniq([mainSort, ..._.keys(sortQuery)])
    const sortOrders = _.uniq([sortQuery[mainSort], ..._.values(sortQuery)])
    return shouldFilter
      ? _
          .chain(this.props.dataSource)
          .filter(d => {
            return _.reduce(
              filterQuery,
              (prev, value, key) => {
                return prev && (value === 'ALL' || d[key] === value)
              },
              true
            )
          })
          .orderBy(sortKeys, sortOrders)
          .value()
      : this.props.dataSource
  }

  render () {
    return (
      <TableContainer>
        <Table
          columns={this.props.columns}
          rows={this.getFilteredData()}
          columnRenderer={this.columnRenderer}
          rowRenderer={this.props.rowRenderer}
          onClickColumn={this.onClickColumn}
          onClickRow={this.props.onClickRow}
          onClickPagination={this.onClickPagination}
          loading={this.props.loading}
          page={this.getPage()}
          perPage={this.props.perPage}
          {...this.props}
        />
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
          {this.props.sortOrder === 'asc' ? <Icon name='Arrow-Up' /> : <Icon name='Arrow-Down' />}
        </ThContent>
      </th>
    )
  }
}
const FilterHeader = withDropdownState(
  class extends React.Component {
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

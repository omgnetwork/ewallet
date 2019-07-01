import React from 'react'
import { connect } from 'react-redux'
import queryString from 'query-string'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'

import { selectNewTransactions } from '../omg-transaction/selector'
import SortableTable from '../omg-table'
import { tableColumsKeys } from './constants'
import rowRenderer from './transactionTableRowRenderer'

const TableContainer = styled.div`
  td:nth-child(3) {
    white-space: nowrap;
    > div {
      overflow: hidden;
      text-overflow: ellipsis;
    }
  }
  td:nth-child(1) {
    padding-right: 0;
    border-bottom: none;
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
  table {
    td {
      vertical-align: middle;
    }
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

function TransactionTable (props) {
  const searchObject = queryString.parse(props.location.search)

  const onClickRow = data => () => {
    props.history.push({
      search: queryString.stringify({
        ...searchObject,
        'show-transaction-tab': data.id
      })
    })
  }
  const activeIndexKey = searchObject['show-transaction-tab']
  return (
    <TableContainer>
      <SortableTable
        rows={[...props.newTransactions, ...props.transactions]}
        columns={tableColumsKeys}
        rowRenderer={rowRenderer}
        perPage={15}
        loadingStatus={props.loadingStatus}
        isFirstPage={props.pagination.is_first_page}
        isLastPage={props.pagination.is_last_page}
        navigation
        onClickRow={onClickRow}
        activeIndexKey={activeIndexKey}
      />
    </TableContainer>
  )
}

TransactionTable.propTypes = {
  newTransactions: PropTypes.array,
  transactions: PropTypes.array,
  loadingStatus: PropTypes.string,
  pagination: PropTypes.object,
  location: PropTypes.object,
  history: PropTypes.object
}

export default connect(
  state => ({
    newTransactions: selectNewTransactions(state)
  }),
  null
)(withRouter(TransactionTable))

import React from 'react'
import { connect } from 'react-redux'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'
import { selectNewWallets } from '../omg-wallet/selector'
import SortableTable from '../omg-table'
import { walletColumsKeys } from './constants'
import rowRenderer from './walletTableRowRenderer'

const TableContainer = styled.div`
  td {
    white-space: nowrap;
  }
  td:nth-child(1) {
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
  td:nth-child(1),
  td:nth-child(2),
  td:nth-child(3),
  td:nth-child(4),
  td:nth-child(5) {
    width: 20%;
  }
  tbody td:first-child {
    border-bottom: none;
  }
`

function WalletsTable (props) {
  const onClickRow = (data, index) => e => {
    props.history.push(`/wallets/${data.address}`)
  }
  const wallets = [...props.newWallets, ...props.wallets]
  return (
    <TableContainer>
      <SortableTable
        rows={wallets.map(d => ({ ...d, id: d.address }))}
        columns={walletColumsKeys}
        rowRenderer={rowRenderer}
        perPage={15}
        loadingStatus={props.loadingStatus}
        isFirstPage={props.pagination.is_first_page}
        isLastPage={props.pagination.is_last_page}
        navigation
        onClickRow={onClickRow}
      />
    </TableContainer>
  )
}

WalletsTable.propTypes = {
  newWallets: PropTypes.array,
  wallets: PropTypes.array,
  loadingStatus: PropTypes.string,
  pagination: PropTypes.object,
  history: PropTypes.object
}

export default connect(
  state => ({
    newWallets: selectNewWallets(state)
  }),
  null
)(withRouter(WalletsTable))

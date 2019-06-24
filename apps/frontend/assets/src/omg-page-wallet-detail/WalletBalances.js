import React from 'react'
import PropTypes from 'prop-types'

import { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import { formatReceiveAmountToTotal } from '../utils/formatter'

function WalletBalances ({ wallet = {} }) {
  return wallet.balances ? (
    <>
      {wallet.balances.map(balance => {
        return (
          <DetailGroup key={balance.token.id}>
            <b>{balance.token.name}</b>{' '}
            <span>
              {formatReceiveAmountToTotal(
                balance.amount,
                balance.token.subunit_to_unit
              )}{' '}
              {balance.token.symbol}
            </span>
          </DetailGroup>
        )
      })}
    </>
  ) : null
}

WalletBalances.propTypes = {
  wallet: PropTypes.object
}

export default WalletBalances

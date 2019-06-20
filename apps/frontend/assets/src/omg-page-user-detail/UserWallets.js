import React from 'react'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import queryString from 'query-string'
import { UserWalletsFetcher } from '../omg-wallet/walletsFetcher'
import WalletTable from '../omg-page-wallets/WalletTable'
function UserWallets (props) {
  const { page, search } = queryString.parse(props.location.search)

  return (
    <UserWalletsFetcher
      userId={props.match.params.userId}
      query={{
        page,
        perPage: 15,
        search
      }}
      render={({
        data: wallets,
        individualLoadingStatus,
        pagination,
        fetch
      }) => {
        return (
          <WalletTable
            loadingStatus={individualLoadingStatus}
            pagination={pagination}
            wallets={wallets}
          />
        )
      }}
    />
  )
}

UserWallets.propTypes = {
  match: PropTypes.object,
  location: PropTypes.object
}

export default withRouter(UserWallets)

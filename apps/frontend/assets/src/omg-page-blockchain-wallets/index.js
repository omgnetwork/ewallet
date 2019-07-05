import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Link, Route, Switch } from 'react-router-dom'

import CreateTransactionButton from '../omg-transaction/CreateTransactionButton'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { Tag } from '../omg-uikit'

const BlockchainTokensPage = () => {
  return <div>BlockchainTokensPage</div>
}

const InternalTokensPage = () => {
  return <div>InternalTokensPage</div>
}

const BlockchainTransactionsPage = () => {
  return <div>BlockchainTransactionsPage</div>
}

const BlockchainSettingsPage = () => {
  return <div>BlockchainSettingsPage</div>
}

const KeyTopBar = styled.div`
  margin-bottom: 20px;
  p {
    color: ${props => props.theme.colors.B100};
    max-width: 80%;
  }
  > div:first-child {
    display: flex;
    align-items: center;
  }
  button:last-child {
    margin-left: auto;
  }
`
const KeyTopButtonsContainer = styled.div`
  margin: 25px 0;
  a {
    margin-right: 10px;
  }
`

const BlockchainWalletPage = ({ location: { pathname } }) => {
  const activeTab = pathname.split('/')[2]

  return (
    <div>
      <TopNavigation
        divider
        title='Blockchain Wallet'
        description='These are all blockchain wallets associated to you. Click each one to view their details.'
        types={false}
        searchBar={false}
        buttons={[
          <CreateTransactionButton key='transfer' />
        ]}
      />
      <KeyTopBar>
        <KeyTopButtonsContainer>
          <Link to='blockchain_tokens'>
            <Tag
              title='Blockchain Tokens'
              icon='Token'
              active={activeTab === 'blockchain_tokens'}
              hoverStyle
            />
          </Link>
          <Link to='internal_tokens'>
            <Tag
              title='Internal Tokens'
              icon='Token'
              active={activeTab === 'internal_tokens'}
              hoverStyle
            />
          </Link>
          <Link to='blockchain_transactions'>
            <Tag
              title='Transaction'
              icon='Transaction'
              active={activeTab === 'blockchain_transactions'}
              hoverStyle
            />
          </Link>
          <Link to='blockchain_settings'>
            <Tag
              title='Settings'
              icon='Setting'
              active={activeTab === 'blockchain_settings'}
              hoverStyle
            />
          </Link>
        </KeyTopButtonsContainer>
      </KeyTopBar>

      <Switch>
        <Route exact path='/blockchain_tokens' component={BlockchainTokensPage} />
        <Route exact path='/internal_tokens' component={InternalTokensPage} />
        <Route exact path='/blockchain_transactions' component={BlockchainTransactionsPage} />
        <Route exact path='/blockchain_settings' component={BlockchainSettingsPage} />
      </Switch>
    </div>
  )
}

BlockchainWalletPage.propTypes = {
  location: PropTypes.object
}

export default BlockchainWalletPage

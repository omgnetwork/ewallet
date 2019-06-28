import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'
import { connect } from 'react-redux'
import { compose } from 'recompose'

import { Button } from '../omg-uikit'
import TransactionRequestDetail from './TransactionRequestDetail'
import ConsumeBox from './ConsumeBox'
import * as transactionRequestActions from '../omg-transaction-request/action'

const TransactionReqeustPropertiesContainer = styled.div`
  height: calc(100vh - 160px);
  overflow: auto;
  > button {
    margin: 20px 0;
  }
  b {
    font-weight: 600;
    color: ${props => props.theme.colors.B200};
  }
`

function PropertiesTab ({ transactionRequest, cancelTransactionRequest }) {
  return (
    <TransactionReqeustPropertiesContainer>
      <ConsumeBox transactionRequest={transactionRequest} />
      <TransactionRequestDetail transactionRequest={transactionRequest} />
      <Button
        styleType='danger'
        onClick={() => cancelTransactionRequest(transactionRequest.id)}
        disabled={!!transactionRequest.expiration_reason}
      >
        Cancel This Request
      </Button>
    </TransactionReqeustPropertiesContainer>
  )
}

const enhance = compose(
  withRouter,
  connect(
    null,
    {
      cancelTransactionRequest: id =>
        transactionRequestActions.cancelTransactionRequestById(id)
    }
  )
)

PropertiesTab.propTypes = {
  transactionRequest: PropTypes.object,
  cancelTransactionRequest: PropTypes.func
}
export default enhance(PropertiesTab)

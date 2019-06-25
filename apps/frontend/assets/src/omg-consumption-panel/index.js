import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'
import queryString from 'query-string'

import ConsumptionProvider from '../omg-consumption/consumptionProvider'
import { Icon } from '../omg-uikit'
import TransactionRequestDetail from '../omg-transaction-request-tab/TransactionRequestDetail'
import ConsumptionBox from './ConsumptionBox'

const PanelContainer = styled.div`
  height: 100vh;
  position: fixed;
  right: 0;
  z-index: 10;
  width: 560px;
  background-color: white;
  overflow: auto;
  padding: 40px 30px;
  box-shadow: 0 0 15px 0 rgba(4, 7, 13, 0.1);
  > i {
    position: absolute;
    right: 25px;
    color: ${props => props.theme.colors.S500};
    top: 25px;
    cursor: pointer;
  }
`

const SubDetailTitle = styled.div`
  margin-top: 10px;
  color: ${props => props.theme.colors.B100};
  margin-bottom: 10px;
  > span {
    padding: 0 5px;
    :first-child {
      padding-left: 0;
    }
  }
`
class TransactionRequestPanel extends Component {
  static propTypes = {
    history: PropTypes.object,
    location: PropTypes.object
  }

  state = {}

  onClickClose = () => {
    const searchObject = queryString.parse(this.props.location.search)
    delete searchObject['show-consumption-tab']
    this.props.history.push({
      search: queryString.stringify(searchObject)
    })
  }
  render () {
    const searchObject = queryString.parse(this.props.location.search)
    return (
      <ConsumptionProvider
        consumptionId={searchObject['show-consumption-tab']}
        render={({ consumption }) => {
          const tq = consumption.transaction_request || {}
          return (
            <PanelContainer>
              <Icon name='Close' onClick={this.onClickClose} />
              <h4>Consumption</h4>
              <SubDetailTitle>
                <span>{consumption.id}</span> | <span>{tq.type}</span>
              </SubDetailTitle>
              <ConsumptionBox consumption={consumption} />
              <TransactionRequestDetail transactionRequest={tq} />
            </PanelContainer>
          )
        }}
      />
    )
  }
}

export default withRouter(TransactionRequestPanel)

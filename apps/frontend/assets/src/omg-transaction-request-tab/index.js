import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import TabPanel from './TabPanel'
import TransactionRequestProvider from '../omg-transaction-request/transactionRequestProvider'
import { Icon } from '../omg-uikit'
import { withRouter } from 'react-router-dom'
import queryString from 'query-string'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { formatReceiveAmountToTotal } from '../utils/formatter'

import { consumeTransactionRequest } from '../omg-transaction-request/action'
import { selectPendingConsumptions } from '../omg-consumption/selector'
import ActivityList from './ActivityList'
import PropertyTab from './PropertiesTab'

const PanelContainer = styled.div`
  height: 100vh;
  position: fixed;
  z-index: 10;
  right: 0;
  width: 560px;
  background-color: white;
  padding: 40px 30px;
  box-shadow: 0 0 15px 0 rgba(4, 7, 13, 0.1);
  > i {
    position: absolute;
    right: 0;
    color: ${props => props.theme.colors.S500};
    top: 0;
    cursor: pointer;
    padding: 20px;
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
const RedDot = styled.div`
  display: inline-block;
  margin-left: 3px;
  background-color: ${props => props.theme.colors.R300};
  width: 7px;
  height: 7px;
  border-radius: 50%;
  vertical-align: middle;
  visibility: ${props => (props.show ? 'visible' : 'hidden')};
`
const enhance = compose(
  withRouter,
  connect(
    (state, props) => ({
      pendingConsumptions: selectPendingConsumptions(
        queryString.parse(props.location.search)['show-request-tab']
      )(state)
    }),
    { consumeTransactionRequest }
  )
)

class TransactionRequestPanel extends Component {
  static propTypes = {
    history: PropTypes.object,
    location: PropTypes.object,
    pendingConsumptions: PropTypes.array
  }

  constructor (props) {
    super(props)
    this.state = {
      consumeAddress: '',
      amount: null,
      searchTokenValue: ''
    }
  }

  onClickClose = () => {
    const searchObject = queryString.parse(this.props.location.search)
    delete searchObject['active-tab']
    delete searchObject['show-request-tab']
    delete searchObject['page-activity']
    this.props.history.push({
      search: queryString.stringify(searchObject)
    })
  }

  onClickTab = tab => e => {
    const searchObject = queryString.parse(this.props.location.search)
    this.props.history.push({
      search: queryString.stringify({
        ...searchObject,
        'active-tab': tab
      })
    })
  }

  render = () => {
    return (
      <TransactionRequestProvider
        transactionRequestId={queryString.parse(this.props.location.search)['show-request-tab']}
        render={({ transactionRequest: tq }) => {
          const amount = tq.allow_amount_override
            ? ''
            : formatReceiveAmountToTotal(tq.amount, _.get(tq, 'token.subunit_to_unit'))
          return (
            <PanelContainer>
              <Icon name='Close' onClick={this.onClickClose} />
              <h4>
                Request to {tq.type} {amount} {_.get(tq, 'token.symbol')}
              </h4>
              <SubDetailTitle>
                <span>{tq.type}</span> | <span>{tq.user_id || _.get(tq, 'account.name')}</span>
              </SubDetailTitle>
              <TabPanel
                activeTabKey={
                  queryString.parse(this.props.location.search)['active-tab'] || 'activity'
                }
                onClickTab={this.onClickTab}
                data={[
                  {
                    key: 'activity',
                    tabTitle: (
                      <div style={{ marginLeft: '5px' }}>
                        <span>PENDING CONSUMPTION</span>{' '}
                        <RedDot show={!!this.props.pendingConsumptions.length} />
                      </div>
                    ),
                    tabContent: <ActivityList />
                  },
                  {
                    key: 'properties',
                    tabTitle: 'PROPERTIES',
                    tabContent: <PropertyTab transactionRequest={tq} />
                  }
                ]}
              />
            </PanelContainer>
          )
        }}
      />
    )
  }
}

export default enhance(TransactionRequestPanel)

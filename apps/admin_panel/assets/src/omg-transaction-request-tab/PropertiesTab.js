import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import { withRouter } from 'react-router-dom'
import TransactionRequestDetail from './TransactionRequestDetail'
import ConsumeBox from './ConsumeBox'
const TransactionReqeustPropertiesContainer = styled.div`
  height: calc(100vh - 160px);
  overflow: auto;
  b {
    font-weight: 600;
    color: ${props => props.theme.colors.B200};
  }
`

class PropertiesTab extends Component {
  static propTypes = {
    match: PropTypes.object,
    transactionRequests: PropTypes.array
  }
  state = {}

  render = () => {
    return (
      <TransactionReqeustPropertiesContainer>
        <ConsumeBox transactionRequests={this.props.transactionRequests} />
        <TransactionRequestDetail transactionRequests={this.props.transactionRequests} />
      </TransactionReqeustPropertiesContainer>
    )
  }
}

export default withRouter(PropertiesTab)

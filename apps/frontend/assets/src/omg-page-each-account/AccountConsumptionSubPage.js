import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { withRouter } from 'react-router-dom'

import ConsumptionPage from '../omg-page-consumption'
import { consumptionsAccountFetcher } from '../omg-consumption/consumptionsFetcher'

export default withRouter(
  class AccountConsumptionSubPage extends Component {
    static propTypes = {
      match: PropTypes.object
    }

    render () {
      return (
        <ConsumptionPage
          showFilter={false}
          divider={false}
          fetcher={consumptionsAccountFetcher}
          accountId={this.props.match.params.accountId}
        />
      )
    }
  }
)

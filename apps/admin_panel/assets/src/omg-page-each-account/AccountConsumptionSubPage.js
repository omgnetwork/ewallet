import React, { Component } from 'react'
import PropTypes from 'prop-types'
import ConsumptionPage from '../omg-page-consumption'
import { consumptionsAccountFetcher } from '../omg-consumption/consumptionsFetcher'
import { withRouter } from 'react-router-dom'
export default withRouter(
  class AccountConsumptionSubPage extends Component {
    static propTypes = {
      match: PropTypes.object
    }

    render () {
      return (
        <ConsumptionPage
          divider={false}
          fetcher={consumptionsAccountFetcher}
          accountId={this.props.match.params.accountId}
        />
      )
    }
  }
)

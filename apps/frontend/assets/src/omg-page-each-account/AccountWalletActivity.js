import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { withRouter } from 'react-router-dom'
import ActivityPage from '../omg-page-activity-log'
export default withRouter(
  class AccountActivitySubPage extends Component {
    static propTypes = {
      match: PropTypes.object
    }

    getQuery = (value = '') => {
      return {
        matchAny: [
          {
            field: 'originator_identifier',
            comparator: 'contains',
            value: this.props.match.params.walletAddress
          },
          {
            field: 'target_identifier',
            comparator: 'contains',
            value: this.props.match.params.walletAddress
          }
        ],
        matchAll: [
          {
            field: 'action',
            comparator: 'contains',
            value
          }
        ]
      }
    }
    render () {
      return <ActivityPage query={this.getQuery} divider={false} />
    }
  }
)

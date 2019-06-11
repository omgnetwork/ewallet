import React from 'react'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import ActivityLogPage from '../omg-page-activity-log'
function UserActivityLogPage (props) {
  return (
    <ActivityLogPage
      divider={false}
      topNavigation={false}
      query={{
        matchAny: [
          {
            field: 'originator_identifier',
            comparator: 'eq',
            value: props.match.params.userId
          },
          {
            field: 'target_identifier',
            comparator: 'eq',
            value: props.match.params.userId
          }
        ]
      }}
    />
  )
}

UserActivityLogPage.propTypes = {
  match: PropTypes.object
}

export default withRouter(UserActivityLogPage)

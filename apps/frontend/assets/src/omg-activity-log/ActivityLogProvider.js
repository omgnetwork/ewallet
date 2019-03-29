import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectGetActivityById } from './selector'
import { getActivityLogById } from '../omg-activity-log/action'
class ActivityProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    getActivityLogById: PropTypes.func,
    activity: PropTypes.object,
    activityId: PropTypes.string
  }

  componentDidMount () {
    // Endpoint is not exist yet
    // if (!this.props.activity) {
    //   this.props.getActivityLogById(this.props.activityId)
    // }
  }
  render () {
    return this.props.render({
      activity: this.props.activity
    })
  }
}
export default connect(
  (state, props) => {
    return {
      activity: selectGetActivityById(state)(props.activityId)
    }
  },
  { getActivityLogById }
)(ActivityProvider)

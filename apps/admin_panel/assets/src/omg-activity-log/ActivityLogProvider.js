import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectGetActivityById } from './selector'
class ActivityProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    getactivityById: PropTypes.func,
    activity: PropTypes.object,
    activityId: PropTypes.string
  }

  componentDidMount () => {
    if (!this.props.activity) {
      this.props.getactivityById(this.props.activityId)
    }
  }
  render () {
    return this.props.render({
      activity: this.props.activity,
      wallet: this.props.wallet
    })
  }
}
export default connect(
  (state, props) => {
    return {
      activity: selectGetActivityById(state)(this.props.activityId)
    }
  },
  { ActivityProvider  , getWalletsByUserId }
)(UserProvider)

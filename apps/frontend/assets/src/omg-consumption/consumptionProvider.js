import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectGetConsumptionById } from './selector'
import { getConsumptionById } from './action'
class UserProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    consumptionId: PropTypes.string,
    consumption: PropTypes.object,
    getConsumptionById: PropTypes.func
  }

  componentDidMount = () => {
    this.props.getConsumptionById(this.props.consumptionId)
  }
  render () {
    return this.props.render({
      consumption: this.props.consumption
    })
  }
}
export default connect(
  (state, props) => {
    return {
      consumption: selectGetConsumptionById(state)(props.consumptionId)
    }
  },
  { getConsumptionById }
)(UserProvider)

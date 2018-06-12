import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectAlerts } from './selector'
import { TransitionGroup, CSSTransition } from 'react-transition-group'
import styled from 'styled-components'
import { clearAlert } from '../omg-alert/action'
const AlertContainer = styled.div`
  position: fixed;
  top: 15px;
  width: 400px;
  left: 0;
  right: 0;
  margin: 0 auto;
  z-index: 1000;
`
const AlertItemContainer = styled.div`
  border: 1px solid ${props => props.type === 'error' ? '#FC7166' : '#65d2bb;'};
  border-radius: 2px;
  background-color: ${props => props.type === 'error' ? '#FFEFED' : '#e8fbf7'};
  padding: 10px;
  font-size: 12px;
  color: ${props => props.theme.colors.B300};
  margin-bottom: 5px;
`
class AlertItem extends Component {
  static propTypes = {
    id: PropTypes.string,
    children: PropTypes.node.isRequired,
    clearAlert: PropTypes.func,
    type: PropTypes.string
  }
  componentDidMount = () => {
    setTimeout(() => {
      this.props.clearAlert(this.props.id)
    }, 3000)
  }

  render () {
    return <AlertItemContainer type={this.props.type}>{this.props.children}</AlertItemContainer>
  }
}

class Alert extends Component {
  static propTypes = {
    alerts: PropTypes.array,
    clearAlert: PropTypes.func
  }

  render () {
    return (
      <AlertContainer>
        <TransitionGroup>
          {this.props.alerts.map((alert, i) => {
            return (
              <CSSTransition
                key={alert.id}
                timeout={{
                  enter: 100,
                  exit: 0
                }}
                classNames='fade'
              >
                <AlertItem id={alert.id} clearAlert={this.props.clearAlert} type={alert.type}>
                  {alert.text}
                </AlertItem>
              </CSSTransition>
            )
          })}
        </TransitionGroup>
      </AlertContainer>
    )
  }
}

export default connect(
  state => {
    return {
      alerts: selectAlerts(state)
    }
  },
  { clearAlert }
)(Alert)

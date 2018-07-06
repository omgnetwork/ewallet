import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectAlerts } from './selector'
import { TransitionGroup, CSSTransition } from 'react-transition-group'
import styled from 'styled-components'
import { clearAlert } from '../omg-alert/action'
import { Icon } from '../omg-uikit'
const AlertContainer = styled.div`
  position: fixed;
  top: 15px;
  display: flex;
  margin: 0 auto;
  left: 50%;
  transform: translateX(-50%);
  z-index: 1000;
  text-align: left;
  line-height: 1.5;
`
const AlertItemContainer = styled.div`
  border-radius: 2px;
  padding: 10px 40px 10px 10px;
  font-size: 12px;
  color: ${props => props.theme.colors.B300};
  margin-bottom: 5px;
  display: flex;
  border: 1px solid #c9d1e2;
  align-items: left;
  min-width: 400px;
  max-width: 500px;
  background-color: ${props => props.theme.colors.S100};
  position: relative;
  b {
    color: ${props => props.theme.colors.B400};
  }
  i[name="Close"] {
    position: absolute;
    right: 10px;
    cursor: pointer;
    padding: 5px;
  }
`

const AlertItemSuccess = AlertItemContainer.extend`
  background-color: #e8fbf7;
  border: 1px solid #65d2bb;
`
const AlertItemError = AlertItemContainer.extend`
  border: 1px solid #fc7166;
  background-color: #ffefed;
`
const SuccessChecked = styled.div`
  border-radius: 50%;
  width: 20px;
  height: 20px;
  text-align: center;
  display: inline-block;
  background-color: #0ebf9a;
  vertical-align: middle;
  position: relative;
  flex: 0 0 auto;
  margin-right: 10px;
  i {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    color: white;
    left: 0;
    right: 0;
    margin: 0 auto;
  }
`
const ErrorChecked = SuccessChecked.extend`
  background-color: #ef3526;
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
    }, 5000)
  }

  render () {
    const alertType = {
      success: (
        <AlertItemSuccess>
          <SuccessChecked>
            <Icon name='Checked' />
          </SuccessChecked>
          {this.props.children}
        </AlertItemSuccess>
      ),
      error: (
        <AlertItemError>
          <ErrorChecked>
            <i>!</i>
          </ErrorChecked>
          {this.props.children}
        </AlertItemError>
      ),
      default: <AlertItemContainer>{this.props.children}</AlertItemContainer>
    }
    return alertType[this.props.type || 'default']
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
                  <Icon name='Close' onClick={e => this.props.clearAlert(alert.id)} />
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

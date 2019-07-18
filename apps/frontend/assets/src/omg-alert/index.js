import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { TransitionGroup, CSSTransition } from 'react-transition-group'
import styled from 'styled-components'
import { connect } from 'react-redux'

import { selectAlerts } from './selector'
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
  position: relative;
  padding: 10px 24px;
  font-size: 12px;
  color: ${props => props.theme.colors.B300};
  margin-bottom: 5px;
  border-radius: 4px;
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

const AlertItemSuccess = styled(AlertItemContainer)`
  background-color: #e8fbf7;
`
const AlertItemError = styled(AlertItemContainer)`
  background-color: #ffefed;
`
const AlertItemWarn = styled(AlertItemContainer)`
  background-color: #ffe29e;
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
const ErrorChecked = styled(SuccessChecked)`
  background-color: #ef3526;
`
const WarnChecked = styled(SuccessChecked)`
  background-color: #f59701;
`
const Checked = styled(SuccessChecked)`
  background-color: transparent;
  i {
    color: black;
  }
`
const AlertAction = styled.div`
  border: 1px solid ${props => props.theme.colors.B100};
  cursor: pointer;
  border-radius: 4px;
  padding: 0 5px;
  margin-left: 4px;
`
const AlertActions = styled.div`
  display: flex;
  flex-direction: row;
  float: right;
`
class AlertItem extends Component {
  static propTypes = {
    id: PropTypes.string,
    children: PropTypes.node.isRequired,
    clearAlert: PropTypes.func,
    type: PropTypes.oneOf(['default', 'success', 'error', 'warn']),
    icon: PropTypes.string,
    duration: PropTypes.number
  }
  static defaultProps = {
    type: 'default',
    duration: 5000
  }
  componentDidMount = () => {
    if (this.props.duration !== -1) {
      setTimeout(() => {
        this.props.clearAlert(this.props.id)
      }, this.props.duration)
    }
  }

  render () {
    const alertType = {
      success: (
        <AlertItemSuccess>
          {this.props.icon && (
            <Checked>
              <Icon name={this.props.icon} />
            </Checked>
          )}
          {!this.props.icon && (
            <SuccessChecked>
              <Icon name='Checked' />
            </SuccessChecked>
          )}
          {this.props.children}
        </AlertItemSuccess>
      ),
      error: (
        <AlertItemError>
          {this.props.icon && (
            <Checked>
              <Icon name={this.props.icon} />
            </Checked>
          )}
          {!this.props.icon && (
            <ErrorChecked>
              <i>!</i>
            </ErrorChecked>
          )}
          {this.props.children}
        </AlertItemError>
      ),
      warn: (
        <AlertItemWarn>
          {this.props.icon && (
            <Checked>
              <Icon name={this.props.icon} />
            </Checked>
          )}
          {!this.props.icon && (
            <WarnChecked>
              <i>!</i>
            </WarnChecked>
          )}
          {this.props.children}
        </AlertItemWarn>
      ),
      default: <AlertItemContainer>{this.props.children}</AlertItemContainer>
    }
    return alertType[this.props.type]
  }
}

class Alert extends Component {
  static propTypes = {
    alerts: PropTypes.array,
    clearAlert: PropTypes.func
  }

  actionClick = (action, id) => {
    action()
    this.props.clearAlert(id)
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
                <AlertItem
                  id={alert.id}
                  clearAlert={this.props.clearAlert}
                  type={alert.type}
                  icon={alert.icon}
                  duration={alert.duration}
                >
                  {alert.text}

                  <AlertActions>
                    {!!alert.actions && alert.actions.map((action, i) => (
                      <AlertAction
                        key={i}
                        onClick={() => this.actionClick(action.onClick, alert.id)}
                      >
                        {action.text}
                      </AlertAction>
                    ))}
                  </AlertActions>

                  {!alert.actions && (
                    <Icon name='Close' onClick={e => this.props.clearAlert(alert.id)} />
                  )}
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

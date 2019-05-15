import { CSSTransition } from 'react-transition-group'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
class Fade extends Component {
  static propTypes = {
    children: PropTypes.node
  }
  render () {
    return (
      <CSSTransition
        {...this.props}
        classNames='fade'
      >
        {this.props.children}
      </CSSTransition>
    )
  }
}
export default Fade

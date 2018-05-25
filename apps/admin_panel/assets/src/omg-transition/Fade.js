import { CSSTransition } from 'react-transition-group'
import React, { Component } from 'react'

class Fade extends Component {

  render () {
    return (
      <CSSTransition
        key={this.props}
        {...this.props}
        classNames='example'
      />
    )
  }
}
export default Fade

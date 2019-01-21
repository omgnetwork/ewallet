import React, { Component } from 'react'
import ReactDOM from 'react-dom'
const clickOutsideEnhancer = BaseComponent =>
  class ClickOutsideEnhancer extends Component {
    componentDidMount = () => {
      this.targetComponent = ReactDOM.findDOMNode(this.component) // eslint-disable-line react/no-find-dom-node
      document.addEventListener('click', this.handleClickDocument)
    }
    componentWillUnmount = () => {
      document.removeEventListener('click', this.handleClickDocument)
    }

    handleClickDocument = e => {
      if (this.component && !this.component.contains(e.target)) {
        this.component.handleClickOutside()
      }
    }
    render () {
      return <BaseComponent {...this.props} ref={component => (this.component = component)} />
    }
  }

export default clickOutsideEnhancer

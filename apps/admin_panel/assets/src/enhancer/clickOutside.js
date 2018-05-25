import React, { Component } from 'react'
import ReactDOM from 'react-dom'
const ClickOutsideEnhancer = BaseComponent =>
  class extends Component {
    componentDidMount = () => {
      this.targetComponent = ReactDOM.findDOMNode(this.component)
      document.addEventListener('click', this.handleClickDocument)
    }
    componentWillUnmount = () => {
      document.removeEventListener('click', this.handleClickDocument)
    }

    handleClickDocument = (e) => {
      if (this.targetComponent && !this.targetComponent.contains(e.target)) {
        this.component.handleClickOutside()
      }
    }
    render () {
      return <BaseComponent {...this.props} ref={component => this.component = component} />
    }
  }

export default ClickOutsideEnhancer

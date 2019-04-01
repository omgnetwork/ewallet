import React, { Component } from 'react'
import { hot } from 'react-hot-loader/root'
import 'reset-css'
class App extends Component {
  componentDidCatch () {
    return 'Something very bad happened, please contact admin.'
  }
  render () {
    return (
      <div>ClientApp</div>
    )
  }
}

export default hot(App)

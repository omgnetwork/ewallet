import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { Link, withRouter } from 'react-router-dom'
import path from 'path'
import _ from 'lodash'
export class LinkWithAccount extends Component {
  static propTypes = {
    to: PropTypes.oneOfType([PropTypes.string, PropTypes.object]),
    children: PropTypes.node,
    match: PropTypes.object.isRequired,
    location: PropTypes.object.isRequired
  }

  createPathWithAccount () {
    const props = {}
    const to =
      typeof this.props.to === 'object'
        ? path.join(
            `/${this.props.match.params.accountId}`,
            _.get(this.props, 'to.pathname', this.props.location.pathname)
          )
        : path.join(`/${this.props.match.params.accountId}`, this.props.to)
    const search = typeof this.props.to === 'object' ? _.get(this.props, 'to.search') : undefined
    if (to) Object.assign(props, { pathname: to })
    if (search) Object.assign(props, { search })
    return props
  }

  render () {
    return <Link to={this.createPathWithAccount()}>{this.props.children}</Link>
  }
}

export default withRouter(LinkWithAccount)

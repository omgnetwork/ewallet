import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { Manager, Reference, Popper } from 'react-popper'
export default class PopperRenderer extends Component {
  static propTypes = {
    renderReference: PropTypes.func,
    renderPopper: PropTypes.func,
    open: PropTypes.bool,
    offset: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
    modifiers: PropTypes.object
  }
  static defaultProps = {
    offset: 0
  }

  render () {
    return (
      <Manager>
        <Reference>
          {({ ref, style }) => (
            <div ref={ref} style={{ ...style, zIndex: 1 }}>
              {this.props.renderReference()}
            </div>
          )}
        </Reference>
        {this.props.open && (
          <Popper
            placement='bottom-end'
            positionFixed
            modifiers={{
              offset: {
                enabled: true,
                offset: this.props.offset
              },
              preventOverflow: {
                enabled: true,
                boundariesElement: document.getElementById('app')
              },
              ...this.props.modifiers
            }}
          >
            {({ ref, style, placement, arrowProps, outOfBoundaries }) => {
              return (
                <div ref={ref} style={{ ...style, zIndex: 1 }} data-placement={placement}>
                  {this.props.renderPopper()}
                </div>
              )
            }}
          </Popper>
        )}
      </Manager>
    )
  }
}

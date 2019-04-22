import React from 'react'
import PropTypes from 'prop-types'
import { TransitionMotion, spring } from 'react-motion'

const Accordion = ({ children: child, path, height }) => {
  const springConfig = { stiffness: 200, damping: 25 }

  const willEnter = () => ({
    height: 0
  })

  const willLeave = () => ({
    height: spring(0, springConfig)
  })

  const getStyles = () => {
    return child
      ? [{
        key: path,
        style: {
          height: spring(
            height,
            springConfig
          )
        },
        data: { child }
      }]
      : []
  }

  return (
    <TransitionMotion
      willEnter={willEnter}
      willLeave={willLeave}
      styles={getStyles()}
    >
      {(interpolated) => (
        <>
          {interpolated.map((item) => {
            return (
              <div
                key={item.key}
                style={{
                  height: `${item.style.height}px`,
                  overflow: 'hidden'
                }}
              >
                {item.data.child}
              </div>
            )
          })}
        </>
      )}
    </TransitionMotion>
  )
}

Accordion.propTypes = {
  path: PropTypes.string.isRequired,
  height: PropTypes.number.isRequired,
  children: PropTypes.any
}

export default Accordion

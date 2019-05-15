import React from 'react'
import PropTypes from 'prop-types'
import { TransitionMotion, spring } from 'react-motion'

const SlideInRight = ({ children: child, path, width }) => {
  const springConfig = { stiffness: 150, damping: 20 }

  const willEnter = () => ({
    xPosition: width
  })

  const willLeave = () => ({
    xPosition: spring(width, springConfig)
  })

  const finalStyles = () => ({
    xPosition: spring(0, springConfig)
  })

  const getStyles = () => {
    return child
      ? [{
        key: path,
        style: finalStyles(),
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
                  transform: `translateX(${item.style.xPosition}px)`
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

SlideInRight.propTypes = {
  path: PropTypes.string.isRequired,
  width: PropTypes.number.isRequired,
  children: PropTypes.any
}

export default SlideInRight

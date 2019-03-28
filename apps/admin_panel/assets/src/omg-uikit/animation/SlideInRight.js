import React from 'react'
import { TransitionMotion, spring } from 'react-motion'

const SlideInRight = ({ children: child, path, width }) => {

  const springConfig = {stiffness: 150, damping: 20}

  const willEnter = () => ({
    xPosition: width
  })
  
  const willLeave = () => ({
    xPosition: spring(width, springConfig)
  })
  
  const finalStyles = () => ({
    xPosition: spring(0, springConfig),
  })

  const getStyles = () => {
    return child
      ? [{
          key: path,
          style: finalStyles(),
          data: {child}
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
                  transform: `translateX(${item.style.xPosition}px)`,
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

export default SlideInRight
/* eslint-disable react/prop-types */
import React, { useEffect } from 'react'

const BlockchainSettings = (props) => {
  useEffect(() => {
    return props.handleCancelClick
  }, [])

  return (
    <div>BlockchainSettings</div>
  )
}

export default BlockchainSettings

import AccountNavgiationBar from './AccountNavigationBar'
import React from 'react'
export default function AccountLayout (props) {
  return (
    <div>
      <AccountNavgiationBar />
      {props.children}
    </div>
  )
}

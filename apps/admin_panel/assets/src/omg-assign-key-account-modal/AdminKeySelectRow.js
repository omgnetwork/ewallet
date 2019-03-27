import React from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
const AdminKeySlectRowContainer = styled.div`
  align-items: center;
  > div:first-child {
    margin-right: 10px;
  }
`
const AdminKeySlectRowName = styled.div`
  margin-bottom: 5px;
`
const AdminKeySlectRowId = styled.div`
  color: ${props => props.theme.colors.B100};
  font-size: 12px;
`

AdminKeySlectRow.propTypes = {
  adminKey: PropTypes.object
}
export default function AdminKeySlectRow ({ adminKey }) {
  return (
    <AdminKeySlectRowContainer>
      <AdminKeySlectRowName>{adminKey.name}</AdminKeySlectRowName>
      <AdminKeySlectRowId>{adminKey.access_key}</AdminKeySlectRowId>
    </AdminKeySlectRowContainer>
  )
}

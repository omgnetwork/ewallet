import React from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
import moment from 'moment'
const AdminKeySlectRowContainer = styled.div`
  align-items: center;

  max-width: 400px;
  > div:first-child {
    margin-right: 10px;
    text-overflow: ellipsis;
    overflow: hidden;
  }
`
const AdminKeySlectRowName = styled.div`
`
const AdminKeySlectRowId = styled.div`
  color: ${props => props.theme.colors.B100};
  font-size: 12px;
`
const AdminKeyRowDate = styled.div`
  font-size: 10px;
  margin-top: 5px;
  color: ${props => props.theme.colors.S500};
`
AdminKeySlectRow.propTypes = {
  adminKey: PropTypes.object
}
export default function AdminKeySlectRow ({ adminKey }) {
  return (
    <AdminKeySlectRowContainer>
      <AdminKeySlectRowName>{adminKey.name}</AdminKeySlectRowName>
      <AdminKeySlectRowId>{adminKey.access_key}</AdminKeySlectRowId>
      <AdminKeyRowDate>{moment(adminKey.created_at).format()}</AdminKeyRowDate>
    </AdminKeySlectRowContainer>
  )
}

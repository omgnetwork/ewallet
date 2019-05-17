import React from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
import moment from 'moment'

const AdminKeySelectRowContainer = styled.div`
  align-items: center;

  max-width: 400px;
  > div:first-child {
    margin-right: 10px;
    text-overflow: ellipsis;
    overflow: hidden;
  }
`
const AdminKeySelectRowName = styled.div`
`
const AdminKeySelectRowId = styled.div`
  color: ${props => props.theme.colors.B300};
  font-size: 12px;
`
const AdminKeyRowDate = styled.div`
  font-size: 10px;
  margin-top: 5px;
  color: ${props => props.theme.colors.S500};
`
AdminKeySelectRow.propTypes = {
  adminKey: PropTypes.object
}
export default function AdminKeySelectRow ({ adminKey }) {
  return (
    <AdminKeySelectRowContainer>
      <AdminKeySelectRowName>{adminKey.name}</AdminKeySelectRowName>
      <AdminKeySelectRowId>{adminKey.access_key}</AdminKeySelectRowId>
      <AdminKeyRowDate>{moment(adminKey.created_at).format()}</AdminKeyRowDate>
    </AdminKeySelectRowContainer>
  )
}

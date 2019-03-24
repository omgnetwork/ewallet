import React, { useState } from 'react'
import AdminKeySection from '../omg-page-api/AdminKeySection'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { Button } from '../omg-uikit'
import styled from 'styled-components'

const AccountKeySubPageContainer = styled.div`
  button {
    padding-left: 30px;
    padding-right: 30px;
  }
`
export default function AccountKeySubPage () {
  const [createAdminKeyModalOpen, setCreateAdminKeyModalOpen] = useState(false)
  return (
    <AccountKeySubPageContainer>
      <TopNavigation
        title='Keys'
        divider={false}
        buttons={[
          <Button key='key' onClick={e => setCreateAdminKeyModalOpen(true)}>
            Generate key
          </Button>
        ]}
      />
      <AdminKeySection
        createAdminKeyModalOpen={createAdminKeyModalOpen}
        onRequestClose={() => setCreateAdminKeyModalOpen(false)}
      />
    </AccountKeySubPageContainer>
  )
}

import React, { useState } from 'react'
import AdminKeySection from '../omg-page-api/AdminKeySection'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { Button } from '../omg-uikit'
export default function AccountKeySubPage () {
  const [createAdminKeyModalOpen, setCreateAdminKeyModalOpen] = useState(false)
  return (
    <div>
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
    </div>
  )
}

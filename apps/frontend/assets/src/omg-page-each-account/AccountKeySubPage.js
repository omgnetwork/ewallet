import React, { useState } from 'react'
import { withRouter } from 'react-router-dom'
import queryString from 'query-string'

import AdminKeySection from '../omg-page-api/AdminKeySection'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { Button } from '../omg-uikit'
import AccountKeyFetcher from '../omg-account/accountKeyFetcher'
import { createSearchAdminSubKeyQuery } from '../omg-access-key/searchField'
import AssignKeyModal from '../omg-assign-key-account-modal'

export default withRouter(function AccountKeySubPage (props) {
  const [assignAdminKeyModalOpen, setAssignAdminKeyModalOpen] = useState(false)
  const [createAdminKeyModalOpen, setCreateAdminKeyModalOpen] = useState(false)
  const [fetcher, setFetcher] = useState(_.noop)

  const { search, access_key_page } = queryString.parse(props.location.search)
  return (
    <>
      <TopNavigation
        title='Keys'
        divider={false}
        buttons={[
          <Button key='generate-assign-key' size='small' onClick={e => setAssignAdminKeyModalOpen(true)}>
            <span>Assign</span>
          </Button>,
          <Button key='generate-admin-key' size='small' onClick={e => setCreateAdminKeyModalOpen(true)} styleType={'secondary'}>
            <span>Generate Admin Key</span>
          </Button>
        ]}
      />
      <AdminKeySection
        subPage
        clickRow={false}
        createAdminKeyModalOpen={createAdminKeyModalOpen}
        onRequestClose={e => setCreateAdminKeyModalOpen(false)}
        fetcher={AccountKeyFetcher}
        registerFetch={fetcher => setFetcher(fetcher)}
        columnsAdminKeys={[
          { key: 'key', title: 'ACCESS KEY' },
          { key: 'name', title: 'LABEL' },
          { key: 'global_role', title: 'GLOBAL ROLE' },
          { key: 'account_role', title: 'ACCOUNT ROLE' },
          { key: 'created_at', title: 'CREATED AT' },
          { key: 'status', title: 'STATUS' }
        ]}
        query={{
          page: access_key_page,
          perPage: 10,
          accountId: props.match.params.accountId,
          ...createSearchAdminSubKeyQuery(search)
        }}
      />
      <AssignKeyModal
        onSubmitSuccess={() => fetcher.fetch()}
        open={assignAdminKeyModalOpen}
        accountId={props.match.params.accountId}
        onRequestClose={() => setAssignAdminKeyModalOpen(false)}
      />
    </>
  )
})

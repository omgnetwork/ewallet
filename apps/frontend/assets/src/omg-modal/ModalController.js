import React from 'react'
import { connect } from 'react-redux'
import { selectGetModalById } from './selector'
import { closeModal, openModal } from './action'

import CreateTransactionModal from '../omg-create-transaction-modal'
import CreateBlockchainTransactionModal from '../omg-create-blockchain-transaction-modal'
import Enable2FaModal from '../omg-2fa-modal/Enable2FaModal'
import Enter2FaModal from '../omg-2fa-modal/Enter2FaModal'
import Disable2FaModal from '../omg-2fa-modal/Disable2FaModal'
import BlockchainDepositModal from '../omg-blockchain-deposit-modal'
import BlockchainWalletModal from '../omg-blockchain-wallet-modal'
import HotWalletTransferModal from '../omg-hot-wallet-transfer-modal'
import InternalToExternalModal from '../omg-internal-to-external-modal'
import ImportTokenModal from '../omg-import-token-modal'
import ExportModal from '../omg-export-modal'
import ExchangePairModal from '../omg-exchange-rate-modal'
import CreateTokenModal from '../omg-create-token-modal'

// ADD YOUR NEW MODAL HERE
const modals = [
  { id: 'createTransaction', modal: CreateTransactionModal },
  { id: 'createBlockchainTransaction', modal: CreateBlockchainTransactionModal },
  { id: 'enable2FaModal', modal: Enable2FaModal },
  { id: 'enter2FaModal', modal: Enter2FaModal },
  { id: 'disable2FaModal', modal: Disable2FaModal },
  { id: 'blockchainDepositModal', modal: BlockchainDepositModal },
  { id: 'blockchainWalletModal', modal: BlockchainWalletModal },
  { id: 'hotWalletTransferModal', modal: HotWalletTransferModal },
  { id: 'internalToExternalModal', modal: InternalToExternalModal },
  { id: 'importTokenModal', modal: ImportTokenModal },
  { id: 'exportModal', modal: ExportModal },
  { id: 'exchangePairModal', modal: ExchangePairModal },
  { id: 'createTokenModal', modal: CreateTokenModal }
]

function ModalController (props) {
  return modals.map(({ id, modal: Modal }) => {
    const modal = props.selectModalById(id) || {}
    return (
      <Modal
        key={id}
        onRequestClose={() => props.closeModal({ id })}
        {...modal}
      />
    )
  })
}

export default connect(
  state => ({ selectModalById: selectGetModalById(state) }),
  { closeModal, openModal }
)(ModalController)

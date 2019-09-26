import RootChain from '@omisego/omg-js-rootchain'
import { transaction } from '@omisego/omg-js-util'

import erc20abi from 'human-standard-token-abi'
import config from './config'

const confirmTransaction = (web3, txnHash, options) => {
  const interval = options && options.interval ? options.interval : config.confirmInterval
  const blocksToWait = options && options.blocksToWait ? options.blocksToWait : config.confirmBlocks
  var transactionReceiptAsync = async function (txnHash, resolve, reject) {
    try {
      var receipt = await web3.eth.getTransactionReceipt(txnHash)
      if (!receipt) {
        setTimeout(function () {
          transactionReceiptAsync(txnHash, resolve, reject)
        }, interval)
      } else {
        if (blocksToWait > 0) {
          var resolvedReceipt = await receipt
          if (!resolvedReceipt || !resolvedReceipt.blockNumber) {
            setTimeout(function () {
              transactionReceiptAsync(txnHash, resolve, reject)
            }, interval)
          } else {
            try {
              var block = await web3.eth.getBlock(resolvedReceipt.blockNumber)
              var current = await web3.eth.getBlock('latest')
              if (current.number - block.number >= blocksToWait) {
                var txn = await web3.eth.getTransaction(txnHash)
                if (txn.blockNumber != null) {
                  resolve(resolvedReceipt)
                } else {
                  reject(new Error('Transaction with hash: ' + txnHash + ' ended up in an uncle block.'))
                }
              } else {
                setTimeout(function () {
                  transactionReceiptAsync(txnHash, resolve, reject)
                }, interval)
              }
            } catch (e) {
              setTimeout(function () {
                transactionReceiptAsync(txnHash, resolve, reject)
              }, interval)
            }
          }
        } else resolve(receipt)
      }
    } catch (e) {
      reject(e)
    }
  }

  if (Array.isArray(txnHash)) {
    var promises = []
    txnHash.forEach(function (oneTxHash) {
      promises.push(confirmTransaction(web3, oneTxHash, options))
    })
    return Promise.all(promises)
  } else {
    return new Promise(function (resolve, reject) {
      transactionReceiptAsync(txnHash, resolve, reject)
    })
  }
}

export const externalPlasmaDeposit = async ({
  web3,
  from,
  value,
  currency = transaction.ETH_CURRENCY,
  approveDeposit = false,
  gasPrice = 1000000,
  gasLimit = 2000000
}) => {
  const depositTx = transaction.encodeDeposit(from, value, currency)
  const rootChain = new RootChain(web3, config.plasmaContractAddress)

  if (currency === transaction.ETH_CURRENCY) {
    return rootChain.depositEth(depositTx, value, { from })
  }

  if (approveDeposit) {
    const erc20 = new web3.eth.Contract(erc20abi, currency)
    const receipt = await erc20.methods
      .approve(rootChain.plasmaContractAddress, value)
      .send({ from, gasPrice, gas: gasLimit })
    await confirmTransaction(web3, receipt.transactionHash)
  }
  return rootChain.depositToken(depositTx, { from })
}

// attempt to return raw web3 call myself...
// if (currency === transaction.ETH_CURRENCY) {
//   const plasmaContract = new web3.eth.Contract(contractAbi, config.plasmaContractAddress)
//   const txDetails = {
//     from,
//     to: config.plasmaContractAddress,
//     value,
//     data: getTxData(
//       web3,
//       plasmaContract,
//       'deposit',
//       depositTx
//     ),
//     gas: gasLimit,
//     gasPrice
//   }
//   return web3.eth.sendTransaction(txDetails)
// }

// const rootChain = new RootChain(web3, config.plasmaContractAddress)
// if (approveDeposit) {
//   const erc20 = new web3.eth.Contract(erc20abi, currency)
//   const receipt = await erc20.methods
//     .approve(rootChain.plasmaContractAddress, value)
//     .send({ from, gasPrice, gas: gasLimit })
//   await confirmTransaction(web3, receipt.transactionHash)
// }
// return rootChain.depositToken(depositTx, { from })
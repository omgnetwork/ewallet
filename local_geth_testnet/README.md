# Local testnet geth setup for the eWallet

This document will go throught a list of commands to run in order to have a working local geth testnet setup.

At the end you will have the following:
- A primary address with some ETH and OMG
- A secondary address that can be used as a recipient
- A copy of the OMG ERC20 contract deployed locally

## Prerequisite

- Geth: (https://geth.ethereum.org/downloads/)
- eWallet setup locally

## Setup

### Generate an ethereum account in the eWallet

Open a terminal windows at the root of the `eWallet` folder and run the elixir console:

> `iex -S mix`

then generate a new ethereum wallet that will be stored in the database:

> `Keychain.Wallet.generate()`

Look at the output and note the address:

`{:ok, {"0xprimary_address", "public_key"}}`

Get the private key for the generated wallet (replace the wallet address with the one from above):

> `Keychain.Key.private_key_for_wallet("0xprimary_address")` 

It will return the private key, keep it for later:

`"p_key"`


### Import the generated account to geth

Open a new terminal window at the root of the `local_geth_testnet` folder

We first need to init the blockchain:

> `./init.sh`

Then we can open the `geth` console:

> `./console.sh`

We then import the previously generated account in geth:

> `personal.importRawKey("p_key", "password")`


Where `p_key` is the private key obtained previously and `password` is the password that will be used to protect the account. 
> Note that this is a local testnet, never use a simple password in a production environment!

This will output the address of the account that should match the address generated in the elixir console previously.

The account has been added to your personal accounts, you can check it with:

> `personal.listAccounts`

Set this address as the default address for geth: 

> `eth.defaultAccount = eth.accounts[0]`

Start the miner for a few seconds to get some ether:

> `miner.start()`

Then stop it after a few seconds:

> `miner.stop()`

### Deploy a copy of the OMG ERC20 contract

Next we will deploy a copy the omg contract to our local testnet.

First, unlock the main account:

> `personal.unlockAccount(eth.accounts[0], "password", 0)`

Then deploy it:

```
var omgtokenContract = web3.eth.contract([{"constant":true,"inputs":[],"name":"mintingFinished","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function","stateMutability":"view"},{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function","stateMutability":"view"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[],"payable":false,"type":"function","stateMutability":"nonpayable"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function","stateMutability":"view"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[],"payable":false,"type":"function","stateMutability":"nonpayable"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function","stateMutability":"view"},{"constant":false,"inputs":[],"name":"unpause","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function","stateMutability":"nonpayable"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_amount","type":"uint256"}],"name":"mint","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function","stateMutability":"nonpayable"},{"constant":true,"inputs":[],"name":"paused","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function","stateMutability":"view"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"type":"function","stateMutability":"view"},{"constant":false,"inputs":[],"name":"finishMinting","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function","stateMutability":"nonpayable"},{"constant":false,"inputs":[],"name":"pause","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function","stateMutability":"nonpayable"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function","stateMutability":"view"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function","stateMutability":"view"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[],"payable":false,"type":"function","stateMutability":"nonpayable"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_amount","type":"uint256"},{"name":"_releaseTime","type":"uint256"}],"name":"mintTimelocked","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function","stateMutability":"nonpayable"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"type":"function","stateMutability":"view"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"type":"function","stateMutability":"nonpayable"},{"anonymous":false,"inputs":[{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Mint","type":"event"},{"anonymous":false,"inputs":[],"name":"MintFinished","type":"event"},{"anonymous":false,"inputs":[],"name":"Pause","type":"event"},{"anonymous":false,"inputs":[],"name":"Unpause","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"owner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"}]);
var omgtoken = omgtokenContract.new(
   {
     from: web3.eth.accounts[0], 
     data: '0x60606040526000600360146101000a81548160ff0219169083151502179055506000600360156101000a81548160ff0219169083151502179055506000600455604060405190810160405280600881526020017f4f4d47546f6b656e000000000000000000000000000000000000000000000000815250600590805190602001906200008d9291906200012b565b50604060405190810160405280600381526020017f4f4d47000000000000000000000000000000000000000000000000000000000081525060069080519060200190620000dc9291906200012b565b5060126007555b33600360006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505b620001da565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f106200016e57805160ff19168380011785556200019f565b828001600101855582156200019f579182015b828111156200019e57825182559160200191906001019062000181565b5b509050620001ae9190620001b2565b5090565b620001d791905b80821115620001d3576000816000905550600101620001b9565b5090565b90565b61190380620001ea6000396000f300606060405236156100fa576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806305d2035b146100fc57806306fdde0314610126578063095ea7b3146101bf57806318160ddd146101fe57806323b872dd14610224578063313ce567146102825780633f4ba83a146102a857806340c10f19146102d25780635c975abb1461032957806370a08231146103535780637d64bcb41461039d5780638456cb59146103c75780638da5cb5b146103f157806395d89b4114610443578063a9059cbb146104dc578063c14a3b8c1461051b578063dd62ed3e146105a3578063f2fde38b1461060c575bfe5b341561010457fe5b61010c610642565b604051808215151515815260200191505060405180910390f35b341561012e57fe5b610136610655565b6040518080602001828103825283818151815260200191508051906020019080838360008314610185575b80518252602083111561018557602082019150602081019050602083039250610161565b505050905090810190601f1680156101b15780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b34156101c757fe5b6101fc600480803573ffffffffffffffffffffffffffffffffffffffff169060200190919080359060200190919050506106f3565b005b341561020657fe5b61020e610877565b6040518082815260200191505060405180910390f35b341561022c57fe5b610280600480803573ffffffffffffffffffffffffffffffffffffffff1690602001909190803573ffffffffffffffffffffffffffffffffffffffff1690602001909190803590602001909190505061087d565b005b341561028a57fe5b6102926108aa565b6040518082815260200191505060405180910390f35b34156102b057fe5b6102b86108b0565b604051808215151515815260200191505060405180910390f35b34156102da57fe5b61030f600480803573ffffffffffffffffffffffffffffffffffffffff1690602001909190803590602001909190505061097f565b604051808215151515815260200191505060405180910390f35b341561033157fe5b610339610b04565b604051808215151515815260200191505060405180910390f35b341561035b57fe5b610387600480803573ffffffffffffffffffffffffffffffffffffffff16906020019091905050610b17565b6040518082815260200191505060405180910390f35b34156103a557fe5b6103ad610b61565b604051808215151515815260200191505060405180910390f35b34156103cf57fe5b6103d7610c13565b604051808215151515815260200191505060405180910390f35b34156103f957fe5b610401610ce1565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b341561044b57fe5b610453610d07565b60405180806020018281038252838181518152602001915080519060200190808383600083146104a2575b8051825260208311156104a25760208201915060208101905060208303925061047e565b505050905090810190601f1680156104ce5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b34156104e457fe5b610519600480803573ffffffffffffffffffffffffffffffffffffffff16906020019091908035906020019091905050610da5565b005b341561052357fe5b610561600480803573ffffffffffffffffffffffffffffffffffffffff16906020019091908035906020019091908035906020019091905050610dd0565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b34156105ab57fe5b6105f6600480803573ffffffffffffffffffffffffffffffffffffffff1690602001909190803573ffffffffffffffffffffffffffffffffffffffff16906020019091905050610ef5565b6040518082815260200191505060405180910390f35b341561061457fe5b610640600480803573ffffffffffffffffffffffffffffffffffffffff16906020019091905050610f7d565b005b600360159054906101000a900460ff1681565b60058054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156106eb5780601f106106c0576101008083540402835291602001916106eb565b820191906000526020600020905b8154815290600101906020018083116106ce57829003601f168201915b505050505081565b6000811415801561078157506000600260003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205414155b1561078c5760006000fd5b80600260003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508173ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925836040518082815260200191505060405180910390a35b5050565b60045481565b600360149054906101000a900460ff16156108985760006000fd5b6108a3838383611057565b5b5b505050565b60075481565b6000600360009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614151561090f5760006000fd5b600360149054906101000a900460ff16151561092b5760006000fd5b6000600360146101000a81548160ff0219169083151502179055507f7805862f689e2f13df9f062ff482ad3ad112aca9e0847911ed832e158c525b3360405180905060405180910390a1600190505b5b5b90565b6000600360009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161415156109de5760006000fd5b600360159054906101000a900460ff16156109f95760006000fd5b610a0e8260045461131a90919063ffffffff16565b600481905550610a6682600160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205461131a90919063ffffffff16565b600160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508273ffffffffffffffffffffffffffffffffffffffff167f0f6798a560793a54c3bcfe86a93cde1e73087d944c0ea20544137d4121396885836040518082815260200191505060405180910390a2600190505b5b5b92915050565b600360149054906101000a900460ff1681565b6000600160008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205490505b919050565b6000600360009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16141515610bc05760006000fd5b6001600360156101000a81548160ff0219169083151502179055507fae5184fba832cb2b1f702aca6117b8d265eaf03ad33eb133f19dde0f5920fa0860405180905060405180910390a1600190505b5b90565b6000600360009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16141515610c725760006000fd5b600360149054906101000a900460ff1615610c8d5760006000fd5b6001600360146101000a81548160ff0219169083151502179055507f6985a02210a168e66602d3235cb6db0e70f92b3ba4d376a33c0f3d9434bff62560405180905060405180910390a1600190505b5b5b90565b600360009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b60068054600181600116156101000203166002900480601f016020809104026020016040519081016040528092919081815260200182805460018160011615610100020316600290048015610d9d5780601f10610d7257610100808354040283529160200191610d9d565b820191906000526020600020905b815481529060010190602001808311610d8057829003601f168201915b505050505081565b600360149054906101000a900460ff1615610dc05760006000fd5b610dca828261133a565b5b5b5050565b60006000600360009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16141515610e315760006000fd5b600360159054906101000a900460ff1615610e4c5760006000fd5b308584610e57611512565b808473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020018281526020019350505050604051809103906000f0801515610eda57fe5b9050610ee6818561097f565b508091505b5b5b509392505050565b6000600260008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205490505b92915050565b600360009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16141515610fda5760006000fd5b600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff161415156110525780600360006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505b5b5b50565b6000606060048101600036905010156110705760006000fd5b600260008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054915061114183600160008773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205461131a90919063ffffffff16565b600160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055506111d683600160008873ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020546114e790919063ffffffff16565b600160008773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000208190555061122c83836114e790919063ffffffff16565b600260008773ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508373ffffffffffffffffffffffffffffffffffffffff168573ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef856040518082815260200191505060405180910390a35b5b5050505050565b60006000828401905061132f84821015611501565b8091505b5092915050565b604060048101600036905010156113515760006000fd5b6113a382600160003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020546114e790919063ffffffff16565b600160003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000208190555061143882600160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205461131a90919063ffffffff16565b600160008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508273ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef846040518082815260200191505060405180910390a35b5b505050565b60006114f583831115611501565b81830390505b92915050565b80151561150e5760006000fd5b5b50565b6040516103b5806115238339019056006060604052341561000c57fe5b6040516060806103b5833981016040528080519060200190919080519060200190919080519060200190919050505b428111151561004a5760006000fd5b82600060006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555081600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550806002819055505b5050505b6102ce806100e76000396000f30060606040526000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff1680634e71d92d1461003b575bfe5b341561004357fe5b61004b61004d565b005b6000600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161415156100ac5760006000fd5b60025442101515156100be5760006000fd5b600060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166370a08231306000604051602001526040518263ffffffff167c0100000000000000000000000000000000000000000000000000000000028152600401808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001915050602060405180830381600087803b151561018057fe5b6102c65a03f1151561018e57fe5b5050506040518051905090506000811115156101aa5760006000fd5b600060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1663a9059cbb600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16836040518363ffffffff167c0100000000000000000000000000000000000000000000000000000000028152600401808373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200182815260200192505050600060405180830381600087803b151561028d57fe5b6102c65a03f1151561029b57fe5b5050505b505600a165627a7a72305820c0a95fe7588e9adb3840b927f9afbac74d6315c45c89865628e4d3322685b4ce0029a165627a7a7230582038ead1e3ed7886dffa32a00235af2bfcecf6957890b3f41fe8b861117312abc30029', 
     gas: '4700000'
   }, function (e, contract){
    if (typeof contract.address !== 'undefined') {
        console.log('==========================================')
        console.log('Contract mined!')
        console.log('Address:')
        console.log(contract.address)
        console.log('==========================================')
    }
 })
 ```

Start the miner to commit the transaction:

> `miner.start(1)`

Wait until you see that the contract is deploy, it will show in the console as something like:

```
==========================================
Contract mined!
Address:
0xcontract_address
==========================================
```

Note the contract address for later and stop the miner:

> `miner.stop()`

Then mint 100 OMG to the main account:

> `omgtoken.mint(eth.accounts[0], web3.toWei(100, "ether"))`

Start the miner again to commit the transaction:

> `miner.start(1)`

Wait until the transaction gets mined then stop the miner.

> `miner.stop()`

You can check your OMG balance with:

> `omgtoken.balanceOf(eth.accounts[0])`

which should output:

`100000000000000000000` (value is displayed down to 18 decimals)

### Generate a secodary address

We now generate a secondary address that can be used as the recipient of transactions:

> `personal.newAccount("password")`

Which outputs an address that you can note down for later use.
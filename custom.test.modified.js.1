const hre = require('hardhat')
const { ethers, waffle } = hre
const { loadFixture } = waffle
const { expect } = require('chai')
const { utils } = ethers

const Utxo = require('../src/utxo')
const { transaction, registerAndTransact, prepareTransaction, buildMerkleTree } = require('../src/index')
const { toFixedHex, poseidonHash } = require('../src/utils')
const { Keypair } = require('../src/keypair')
const { encodeDataForBridge } = require('./utils')

const MERKLE_TREE_HEIGHT = 5
const l1ChainId = 1
const MINIMUM_WITHDRAWAL_AMOUNT = utils.parseUnits(process.env.MINIMUM_WITHDRAWAL_AMOUNT || '0.05')
const MAXIMUM_DEPOSIT_AMOUNT = utils.parseUnits(process.env.MAXIMUM_DEPOSIT_AMOUNT || '1')

describe('Custom Tests', function () {
  this.timeout(20000)

  async function deploy(contractName, ...args) {
    const Factory = await ethers.getContractFactory(contractName)
    const instance = await Factory.deploy(...args)
    return instance.deployed()
  }

  async function fixture() {
    require('../scripts/compileHasher')
    const [sender, gov, l1Unwrapper, multisig] = await ethers.getSigners()
    const verifier2 = await deploy('Verifier2')
    const verifier16 = await deploy('Verifier16')
    const hasher = await deploy('Hasher')

    const token = await deploy('PermittableToken', 'Wrapped ETH', 'WETH', 18, l1ChainId)
    await token.mint(sender.address, utils.parseUnits('10000'))

    const amb = await deploy('MockAMB', gov.address, l1ChainId)
    const omniBridge = await deploy('MockOmniBridge', amb.address)

    /** @type {TornadoPool} */
    const tornadoPoolImpl = await deploy(
      'TornadoPool',
      verifier2.address,
      verifier16.address,
      MERKLE_TREE_HEIGHT,
      hasher.address,
      token.address,
      omniBridge.address,
      l1Unwrapper.address,
      gov.address,
      l1ChainId,
      multisig.address,
    )

    const { data } = await tornadoPoolImpl.populateTransaction.initialize(
      MINIMUM_WITHDRAWAL_AMOUNT,
      MAXIMUM_DEPOSIT_AMOUNT,
    )
    const proxy = await deploy(
      'CrossChainUpgradeableProxy',
      tornadoPoolImpl.address,
      gov.address,
      data,
      amb.address,
      l1ChainId,
    )

    const tornadoPool = tornadoPoolImpl.attach(proxy.address)

    await token.approve(tornadoPool.address, utils.parseUnits('10000'))

    return { tornadoPool, token, proxy, omniBridge, amb, gov, multisig }
  }

  it('[assignment] ii. deposit 0.1 ETH in L1 -> withdraw 0.08 ETH in L2 -> assert balances', async () => {
    const { tornadoPool, token, omniBridge } = await loadFixture(fixture)

    //
    // 1. deposit 0.1 ETH
    //

    const aliceKeypair = new Keypair() // contains private and public keys
    const aliceAddress = aliceKeypair.address()

    const depositAmount = utils.parseUnits('0.1')
    const depositUtxo = new Utxo({ amount: depositAmount })
    const { args, extData } = await prepareTransaction({ tornadoPool, outputs: [depositUtxo] })
    const tokenBridgedData = encodeDataForBridge({ proof: args, extData })
    const tokenBridgedTx = await tornadoPool.populateTransaction.onTokenBridged(
      token.address,
      depositUtxo.amount,
      tokenBridgedData,
    )

    await token.transfer(omniBridge.address, depositAmount)
    const transferTx = await token.populateTransaction.transfer(tornadoPool.address, depositAmount)

    await omniBridge.execute([
      { who: token.address, callData: transferTx.data },
      { who: tornadoPool.address, callData: tokenBridgedTx.data },
    ])

    //
    // 2. withdraw
    //
    const withdrawAmount = utils.parseUnits('0.08')
    const recipient = '0x0000000000000000000000000000000000000001'
    const withdrawUtxo = new Utxo({
      amount: depositAmount.sub(withdrawAmount),
      keypair: aliceKeypair,
    })
    await transaction({
      tornadoPool,
      inputs: [depositUtxo],
      outputs: [withdrawUtxo],
      recipient: recipient,
    })

    //
    // 3. checks
    //
    expect(await token.balanceOf(recipient)).to.eq(utils.parseUnits('0.08'))

    const bridgeBalance = await token.balanceOf(omniBridge.address)
    expect(bridgeBalance).to.eq(0)

    const poolBalance = await token.balanceOf(tornadoPool.address)
    expect(poolBalance).to.eq(utils.parseUnits('0.02'))
  })

  it('[assignment] iii. see assignment doc for details', async () => {
    const { tornadoPool, token, omniBridge } = await loadFixture(fixture)
    const aliceKeypair = new Keypair()
    const aliceAddress = aliceKeypair.address()
    const bobKeypair = new Keypair()
    const bobAddress = bobKeypair.address()

    //
    // 1. alice deposits
    //

    const depositAmount = utils.parseUnits('0.13')
    const depositUtxo = new Utxo({ amount: depositAmount, keypair: aliceKeypair })

    const { args, extData } = await prepareTransaction({ tornadoPool, outputs: [depositUtxo] })
    const onTokenBridgedData = encodeDataForBridge({ proof: args, extData })
    const onTokenBridgedTx = await tornadoPool.populateTransaction.onTokenBridged(
      token.address,
      depositUtxo.amount,
      onTokenBridgedData,
    )

    await token.transfer(omniBridge.address, depositAmount)
    const transferTx = await token.populateTransaction.transfer(tornadoPool.address, depositAmount)

    await omniBridge.execute([
      { who: token.address, callData: transferTx.data },
      { who: tornadoPool.address, callData: onTokenBridgedTx.data },
    ])

    //
    // 2. alice sends to bob
    //

    // Create two transactions, one to transfer to Bob, one represent the remaining balance
    const sendAmount = utils.parseUnits('0.06')
    const sendUtxo = new Utxo({ amount: sendAmount, keypair: Keypair.fromString(bobAddress) })
    const aliceChangeUtxo = new Utxo({
      amount: depositAmount.sub(sendAmount),
      keypair: depositUtxo.keypair,
    })

    // Execute the transactions. The original depositUtxo will be "spent" and can not be used again
    // Two new commitments for the output transactions will be added to the tree, and can be spent in the future
    // Since the two output transaction amounts add up to the exact amount of the input, no actual token transfer happens
    await transaction({ tornadoPool, inputs: [depositUtxo], outputs: [sendUtxo, aliceChangeUtxo] })

    //
    // 3. bob withdraws on l2
    //

    const bobBalanceUtxo = new Utxo({
      amount: sendAmount,
      keypair: bobKeypair,
      blinding: sendUtxo.blinding,
    })
    const bobRecipient = '0x0000000000000000000000000000000000000001'
    await transaction({
      tornadoPool,
      inputs: [bobBalanceUtxo],
      recipient: bobRecipient,
    })

    //
    // 4. alice withdraws all funds in L1
    //

    const aliceRecipient = '0x1234560000000000000000000000000000000002'
    await transaction({
      tornadoPool,
      inputs: [aliceChangeUtxo],
      recipient: aliceRecipient,
      isL1Withdrawal: true,
    })

    //
    // 5. checks
    //

    const bobRecipientBalance = await token.balanceOf(bobRecipient)
    expect(bobRecipientBalance).to.be.equal(utils.parseUnits('0.06'))

    const aliceRecipientBalance = await token.balanceOf(aliceRecipient)
    expect(aliceRecipientBalance).to.be.equal(0)

    const omniBridgeBalance = await token.balanceOf(omniBridge.address)
    expect(omniBridgeBalance).to.be.equal(utils.parseUnits('0.07'))

    const poolBalance = await token.balanceOf(tornadoPool.address)
    expect(poolBalance).to.be.equal(0)
  })
})

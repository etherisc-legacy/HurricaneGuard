/**
 * Unit tests for HurricaneResponseNewPolicy
 *
 * @author Christoph Mussenbrock
 * @description t.b.d
 * @copyright (c) 2017 etherisc GmbH
 *
 * Hurricane Response
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */

/* global artifacts */
/* global contract */
/* global it */
/* global web3 */
/* global assert */

const log = require('../util/logger')

const HurricaneResponseAccessController = artifacts.require('HurricaneResponseAccessController')
const HurricaneResponseController = artifacts.require('HurricaneResponseController')
const HurricaneResponseDatabase = artifacts.require('HurricaneResponseDatabase')
const HurricaneResponseLedger = artifacts.require('HurricaneResponseLedger')
const HurricaneResponseNewPolicy = artifacts.require('HurricaneResponseNewPolicy')
const HurricaneResponseUnderwrite = artifacts.require('HurricaneResponseUnderwrite')
const HurricaneResponsePayout = artifacts.require('HurricaneResponsePayout')

contract('Test group: Destruct all contracts', (accounts) => {
  it('should destroy all contracts and refund to owner', async () => {
    const instances = {}
    let grandTotal = 0

    instances.CT = await HurricaneResponseController.deployed()
    instances.AC = await HurricaneResponseAccessController.deployed()
    instances.DB = await HurricaneResponseDatabase.deployed()
    instances.LG = await HurricaneResponseLedger.deployed()
    instances.NP = await HurricaneResponseNewPolicy.deployed()
    instances.UW = await HurricaneResponseUnderwrite.deployed()
    instances.PY = await HurricaneResponsePayout.deployed()

    const accountBalance = web3.fromWei(await web3.eth.getBalance(accounts[1]), 'ether').toFixed(2)
    grandTotal += Number(accountBalance)
    log.info(`Acc Balance before: ${grandTotal}`)

    const CTBalance = web3.fromWei(await web3.eth.getBalance(instances.CT.address), 'ether').toFixed(2)
    grandTotal += Number(CTBalance)
    log.info(`CT Balance: ${CTBalance}`)

    const LGBalance = web3.fromWei(await web3.eth.getBalance(instances.LG.address), 'ether').toFixed(2)
    grandTotal += Number(LGBalance)
    log.info(`LG Balance: ${LGBalance}`)

    const UWBalance = web3.fromWei(await web3.eth.getBalance(instances.UW.address), 'ether').toFixed(2)
    grandTotal += Number(UWBalance)
    log.info(`UW Balance: ${UWBalance}`)

    const PYBalance = web3.fromWei(await web3.eth.getBalance(instances.PY.address), 'ether').toFixed(2)
    grandTotal += Number(PYBalance)
    log.info(`PY Balance: ${PYBalance}`)

    const { logs } = await instances.CT.destructAll({
      from: accounts[1],
      gas: 4700000
    })

    log.info(logs)

    const newBalance = web3.fromWei(await web3.eth.getBalance(accounts[1]), 'ether').toFixed(2)
    grandTotal -= newBalance
    log.info(`Acc. Balance after: ${newBalance}`)
    log.info(`Diff              : ${grandTotal.toFixed(2)}`)

    assert(grandTotal < 0.1, 'Diff should be less than 0.01 ETH')
  })
})

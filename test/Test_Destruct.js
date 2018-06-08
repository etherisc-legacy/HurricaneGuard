/**
 * Unit tests for HurricaneGuardNewPolicy
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

const HurricaneGuardAccessController = artifacts.require('HurricaneGuardAccessController')
const HurricaneGuardController = artifacts.require('HurricaneGuardController')
const HurricaneGuardDatabase = artifacts.require('HurricaneGuardDatabase')
const HurricaneGuardLedger = artifacts.require('HurricaneGuardLedger')
const HurricaneGuardNewPolicy = artifacts.require('HurricaneGuardNewPolicy')
const HurricaneGuardUnderwrite = artifacts.require('HurricaneGuardUnderwrite')
const HurricaneGuardPayout = artifacts.require('HurricaneGuardPayout')

contract('Test group: Destruct all contracts', (accounts) => {
  it('should destroy all contracts and refund to owner', async () => {
    const instances = {}
    let grandTotal = 0

    instances.CT = await HurricaneGuardController.deployed()
    instances.AC = await HurricaneGuardAccessController.deployed()
    instances.DB = await HurricaneGuardDatabase.deployed()
    instances.LG = await HurricaneGuardLedger.deployed()
    instances.NP = await HurricaneGuardNewPolicy.deployed()
    instances.UW = await HurricaneGuardUnderwrite.deployed()
    instances.PY = await HurricaneGuardPayout.deployed()

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

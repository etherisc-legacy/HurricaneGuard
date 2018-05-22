/**
 * Unit tests for deploy
 *
 * @author Christoph Mussenbrock
 * @description t.b.d
 * @copyright (c) 2017 etherisc GmbH
 *
 */

/* global artifacts */
/* global contract */
/* global it */
/* global assert */
/* global before */
/* global after */
/* global web3 */

const utils = require('../util/test-utils.js')

const HurricaneResponseController = artifacts.require('HurricaneResponseController')
const HurricaneResponseAccessController = artifacts.require('HurricaneResponseAccessController')
const HurricaneResponseDatabase = artifacts.require('HurricaneResponseDatabase')
const HurricaneResponseLedger = artifacts.require('HurricaneResponseLedger')
const HurricaneResponseNewPolicy = artifacts.require('HurricaneResponseNewPolicy')
const HurricaneResponseUnderwrite = artifacts.require('HurricaneResponseUnderwrite')
const HurricaneResponsePayout = artifacts.require('HurricaneResponsePayout')

const contractLabel = contract => web3.toUtf8(contract)

contract('After deploy', (accounts) => {
  let HRC
  let HR_DB

  const contracts = {
    'HR.Owner': accounts[1],
    'HR.Controller': HurricaneResponseController,
    'HR.Funder': accounts[2],
    'HR.CustomersAdmin': accounts[3],
    'HR.Emergency': accounts[4],
    'HR.AccessController': HurricaneResponseAccessController,
    'HR.Database': HurricaneResponseDatabase,
    'HR.Ledger': HurricaneResponseLedger,
    'HR.NewPolicy': HurricaneResponseNewPolicy,
    'HR.Underwrite': HurricaneResponseUnderwrite,
    'HR.Payout': HurricaneResponsePayout
  }

  const ledger = {
    Premium: 0,
    RiskFund: 1000000000000000000,
    Payout: 0,
    Balance: -1000000000000000000,
    Reward: 0,
    OraclizeCosts: 0
  }

  before(async () => {
    HRC = await HurricaneResponseController.deployed()
    HR_DB = await HurricaneResponseDatabase.deployed()
  })

  Object.keys(contracts).forEach((key, i) =>
    it(`should have ${key} registered properly`, async () => {
      const label = contractLabel(await HRC.contractIds(i))
      const address = await HRC.contracts(label)

      assert.equal(key, label)
      assert.equal(address[0], contracts[key].address || contracts[key])
    })
  )

  Object.keys(ledger).forEach((key, i) => {
    it(`${key} in HR.Database should be set to ${ledger[key]}`, async () => {
      const value = await HR_DB.ledger(i)
      assert.equal(ledger[key], value.valueOf())
    })
  })

  it('should throw on invalid index in ledger', async () => {
    try {
      await HR_DB.ledger(6)
      assert.fail('should have thrown before')
    } catch (error) {
      utils.assertJump(error)
    }
  })

  after(async () => {
    if (web3.version.network < 1000) {
      await HRC.destructAll({ from: accounts[1], gas: 4700000 })
    }
  })
})

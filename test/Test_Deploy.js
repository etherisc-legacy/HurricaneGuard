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

const HurricaneGuardController = artifacts.require('HurricaneGuardController')
const HurricaneGuardAccessController = artifacts.require('HurricaneGuardAccessController')
const HurricaneGuardDatabase = artifacts.require('HurricaneGuardDatabase')
const HurricaneGuardLedger = artifacts.require('HurricaneGuardLedger')
const HurricaneGuardNewPolicy = artifacts.require('HurricaneGuardNewPolicy')
const HurricaneGuardUnderwrite = artifacts.require('HurricaneGuardUnderwrite')
const HurricaneGuardPayout = artifacts.require('HurricaneGuardPayout')

const contractLabel = contract => web3.toUtf8(contract)

contract('After deploy', (accounts) => {
  let HRC
  let HG_DB

  const contracts = {
    'HG.Owner': accounts[1],
    'HG.Controller': HurricaneGuardController,
    'HG.Funder': accounts[2],
    'HG.CustomersAdmin': accounts[3],
    'HG.Emergency': accounts[4],
    'HG.AccessController': HurricaneGuardAccessController,
    'HG.Database': HurricaneGuardDatabase,
    'HG.Ledger': HurricaneGuardLedger,
    'HG.NewPolicy': HurricaneGuardNewPolicy,
    'HG.Underwrite': HurricaneGuardUnderwrite,
    'HG.Payout': HurricaneGuardPayout
  }

  const ledger = {
    Premium: 0,
    RiskFund: 2000000000000000000,
    Payout: 0,
    Balance: -2000000000000000000,
    Reward: 0,
    OraclizeCosts: 0
  }

  before(async () => {
    HRC = await HurricaneGuardController.deployed()
    HG_DB = await HurricaneGuardDatabase.deployed()
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
    it(`${key} in HG.Database should be set to ${ledger[key]}`, async () => {
      const value = await HG_DB.ledger(i)
      assert.equal(ledger[key], value.valueOf())
    })
  })

  it('should throw on invalid index in ledger', async () => {
    try {
      await HG_DB.ledger(6)
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

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
/* global after */
/* global before */

const utils = require('../util/test-utils.js')

contract('HurricaneResponsePayout', async (accounts) => {
  let HR

  before(async () => {
    HR = await utils.getDeployedContracts(artifacts)
  })

  // todo: checkConstants
  // ORACLIZE_STATUS_BASE_URL
  // ORACLIZE_STATUS_QUERY
  // ORACLIZE_GAS
  // MAX_PAYOUT

  /*
   * Initilization
   */
  it('controller should be set to HR.Controller', async () => {
    const controller = await HR.PY.controller.call()
    assert.equal(controller, HR.C.address)
  })

  it('HR.Payout should be registered in HR.Controller', async () => {
    const addr = await HR.C.getContract.call('HR.Payout')
    assert.equal(addr, HR.PY.address)
  })

  // todo: check onlyController

  // todo: test setContracts

  /*
   * setContracts tests
   */
  // it('Should not be accessed from external account', async () => {
  //   await HR.PY.setContracts()
  //     .should.be.rejectedWith(utils.EVMThrow)
  // })

  it('Access to `schedulePayoutOraclizeCall` should be limited', async () => {
    const permissions = utils.expectedPermissions(HR, accounts, {
      'HR.CustomersAdmin': 101
    })

    permissions.forEach(async (perm) => {
      const [ label, caller, access ] = perm

      assert.equal(
        await HR.DB.getAccessControl.call(
          HR.PY.address,
          caller,
          access
        ),
        !!perm[2],
        `Access from ${label} should be set to ${access}`)
    })
  })

  it('Access to `fund` should be limited', async () => {
    const permissions = utils.expectedPermissions(HR, accounts, {
      'HR.Funder': 102
    })

    permissions.forEach(async (perm) => {
      const [ label, caller, access ] = perm

      assert.equal(
        await HR.DB.getAccessControl.call(
          HR.PY.address,
          caller,
          access
        ),
        !!perm[2],
        `Access from ${label} should be set to ${access}`)
    })
  })

  /*
   * fund tests
   */
  // it('Should accept ETH from HR.Funder', async () => {
  //   const balanceBefore = web3.eth.getBalance(HR.PY.address)
  //   const value = web3.toWei(10, 'ether')
  //
  //   try {
  //     await HR.PY.fund({ from: accounts[2], value })
  //     assert.ok('should not be rejected')
  //   } catch (error) {
  //     utils.assertJump(error)
  //   }
  //
  //   const balanceAfter = web3.eth.getBalance(HR.PY.address)
  //
  //   Number(balanceAfter).should.be.greaterThan(Number(balanceBefore))
  //   Number(balanceAfter).should.be.equal(Number(value) + Number(balanceBefore))
  // })

  // it('Should not accept ETH from other accounts', async () => {
  //   try {
  //     await HR.PY.fund({ from: accounts[1], value: web3.toWei(10, 'ether') })
  //     assert.fail('should be rejected')
  //   } catch (error) {
  //     utils.assertJump(error)
  //   }
  // })

  /*
   * todo: schedulePayoutOraclizeCall tests
   */

  /*
   * todo: __callback tests
   */

  /*
   * todo: payOut tests
   */

  after(async () => {
    if (web3.version.network < 1000) {
      await HR.C.destructAll({ from: accounts[1], gas: 4700000 })
    }
  })
})

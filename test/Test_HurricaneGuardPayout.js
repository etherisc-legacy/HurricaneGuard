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
/* global after */
/* global before */

const utils = require('../util/test-utils.js')

contract('HurricaneGuardPayout', async (accounts) => {
  let HG

  before(async () => {
    HG = await utils.getDeployedContracts(artifacts)
  })

  // todo: checkConstants
  // ORACLIZE_STATUS_BASE_URL
  // ORACLIZE_STATUS_QUERY
  // ORACLIZE_GAS
  // MAX_PAYOUT

  /*
   * Initilization
   */
  it('controller should be set to HG.Controller', async () => {
    const controller = await HG.PY.controller.call()
    assert.equal(controller, HG.C.address)
  })

  it('HG.Payout should be registered in HG.Controller', async () => {
    const addr = await HG.C.getContract.call('HG.Payout')
    assert.equal(addr, HG.PY.address)
  })

  // todo: check onlyController

  // todo: test setContracts

  /*
   * setContracts tests
   */
  // it('Should not be accessed from external account', async () => {
  //   await HG.PY.setContracts()
  //     .should.be.rejectedWith(utils.EVMThrow)
  // })

  it('Access to `schedulePayoutOraclizeCall` should be limited', async () => {
    const permissions = utils.expectedPermissions(HG, accounts, {
      'HG.CustomersAdmin': 101
    })

    permissions.forEach(async (perm) => {
      const [ label, caller, access ] = perm

      assert.equal(
        await HG.DB.getAccessControl.call(
          HG.PY.address,
          caller,
          access
        ),
        !!perm[2],
        `Access from ${label} should be set to ${access}`)
    })
  })

  it('Access to `fund` should be limited', async () => {
    const permissions = utils.expectedPermissions(HG, accounts, {
      'HG.Funder': 102
    })

    permissions.forEach(async (perm) => {
      const [ label, caller, access ] = perm

      assert.equal(
        await HG.DB.getAccessControl.call(
          HG.PY.address,
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
  // it('Should accept ETH from HG.Funder', async () => {
  //   const balanceBefore = web3.eth.getBalance(HG.PY.address)
  //   const value = web3.toWei(10, 'ether')
  //
  //   try {
  //     await HG.PY.fund({ from: accounts[2], value })
  //     assert.ok('should not be rejected')
  //   } catch (error) {
  //     utils.assertJump(error)
  //   }
  //
  //   const balanceAfter = web3.eth.getBalance(HG.PY.address)
  //
  //   Number(balanceAfter).should.be.greaterThan(Number(balanceBefore))
  //   Number(balanceAfter).should.be.equal(Number(value) + Number(balanceBefore))
  // })

  // it('Should not accept ETH from other accounts', async () => {
  //   try {
  //     await HG.PY.fund({ from: accounts[1], value: web3.toWei(10, 'ether') })
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
      await HG.C.destructAll({ from: accounts[1], gas: 4700000 })
    }
  })
})

/**
 * Deployment script for FlightDelay
 *
 * @author Christoph Mussenbrock
 * @description Deploy FlightDelayController
 * @copyright (c) 2017 etherisc GmbH
 *
 * Hurricane Response with Underwriting and Payout
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */

/* global web3 */
/* global artifacts */

const log = require('../util/logger')

const HurricaneResponseAddressResolver = artifacts.require('HurricaneResponseAddressResolver.sol')
const HurricaneResponseController = artifacts.require('HurricaneResponseController.sol')
const HurricaneResponseAccessController = artifacts.require('HurricaneResponseAccessController.sol')
const HurricaneResponseDatabase = artifacts.require('HurricaneResponseDatabase.sol')
const HurricaneResponseLedger = artifacts.require('HurricaneResponseLedger.sol')
const HurricaneResponseNewPolicy = artifacts.require('HurricaneResponseNewPolicy.sol')
const HurricaneResponseUnderwrite = artifacts.require('HurricaneResponseUnderwrite.sol')
const HurricaneResponsePayout = artifacts.require('HurricaneResponsePayout.sol')

const strings = artifacts.require('./../vendors/strings.sol')

module.exports = (deployer, network, accounts) => {
  let controller

  const fund = value => web3.toWei(value, 'ether')

  log.info('Deploy HurricaneResponseController contract')

  return deployer
    // Deploy contracts
    .deploy(HurricaneResponseController)
    .then(() => log.info(`Deploy contracts for controller at: ${HurricaneResponseController.address}`))
    .then(() => deployer.deploy(HurricaneResponseAccessController, HurricaneResponseController.address))
    .then(() => deployer.deploy(HurricaneResponseDatabase, HurricaneResponseController.address))
    .then(() => deployer.link(strings, [HurricaneResponseNewPolicy, HurricaneResponseUnderwrite, HurricaneResponsePayout]))
    .then(() => deployer.deploy(HurricaneResponseLedger, HurricaneResponseController.address))
    .then(() => deployer.deploy(HurricaneResponseNewPolicy, HurricaneResponseController.address))
    .then(() => deployer.deploy(HurricaneResponseUnderwrite, HurricaneResponseController.address))
    .then(() => deployer.deploy(HurricaneResponsePayout, HurricaneResponseController.address))

    // Get controller instance
    .then(() => HurricaneResponseController.deployed())
    .then((_i) => {
      controller = _i
      return Promise.resolve()
    })

    // Register contracts
    .then(() => log.info('Register administators'))
    .then(() => controller.registerContract(accounts[2], 'HR.Funder', false))

    .then(() => controller.registerContract(accounts[3], 'HR.CustomersAdmin', false))
    .then(() => controller.registerContract(accounts[4], 'HR.Emergency', false))

    .then(() => log.info('Register contracts'))
    .then(() => controller.registerContract(HurricaneResponseAccessController.address, 'HR.AccessController', true))
    .then(() => controller.registerContract(HurricaneResponseDatabase.address, 'HR.Database', true))
    .then(() => controller.registerContract(HurricaneResponseLedger.address, 'HR.Ledger', true))
    .then(() => controller.registerContract(HurricaneResponseNewPolicy.address, 'HR.NewPolicy', true))
    .then(() => controller.registerContract(HurricaneResponseUnderwrite.address, 'HR.Underwrite', true))
    .then(() => controller.registerContract(HurricaneResponsePayout.address, 'HR.Payout', true))

    // Set new owner
    .then(() => log.info('Transfer ownership'))
    .then(() => controller.transferOwnership(accounts[1]))

    // Setup contracts
    .then(() => log.info('Setup contracts'))
    .then(() => controller.setAllContracts({from: accounts[1]}))

    // Fund Contracts

    // Fund HR.Ledger
    .then(() => log.info('Fund HR.Ledger'))
    .then(() => HurricaneResponseLedger.deployed())
    .then(HR_LG => {
      log.info(`Funder: ${accounts[2]}`)
      return HR_LG.fund({from: accounts[2], value: fund(1), gas: 5e5})
    })

    // Fund HR.Underwrite
    .then(() => log.info('Fund HR.Underwrite'))
    .then(() => HurricaneResponseUnderwrite.deployed())
    .then(HR_UW => HR_UW.fund({from: accounts[2], value: fund(0.5), gas: 5e5}))

    // Fund HR.Payout
    .then(() => log.info('Fund HR.Payout'))
    .then(() => HurricaneResponsePayout.deployed())
    .then(HR_PY => HR_PY.fund({from: accounts[2], value: fund(0.5), gas: 5e5}))

    .then(() => log.info('Deploy AddressResolver'))

    // Deploy AddressResolver on Testrpc
    .then(() => {
      // todo: check the account nonce, determine if we really need to deploy AR
      return deployer.deploy(HurricaneResponseAddressResolver)
        .then(() => HurricaneResponseAddressResolver.deployed())
        .then(HR_AR => HR_AR.setAddress(HurricaneResponseNewPolicy.address))
    })

    .then(() => {
      log.info(`Deployer: ${accounts[0]}`)
      log.info(`HR.Owner: ${accounts[1]}`)
      log.info(`HR.Funder: ${accounts[2]}`)
      log.info(`HR.CustomersAdmin: ${accounts[3]}`)
      log.info(`HR.Emergency: ${accounts[4]}`)
      log.info(`HR.Controller: ${HurricaneResponseController.address}`)
      log.info(`HR.AccessController: ${HurricaneResponseAccessController.address}`)
      log.info(`HR.Database: ${HurricaneResponseDatabase.address}`)
      log.info(`HR.Ledger: ${HurricaneResponseLedger.address}`)
      log.info(`HR.NewPolicy: ${HurricaneResponseNewPolicy.address}`)
      log.info(`HR.Underwrite: ${HurricaneResponseUnderwrite.address}`)
      log.info(`HR.Payout: ${HurricaneResponsePayout.address}`)
    })

    .catch(err => {
      console.log(err)
    })
}

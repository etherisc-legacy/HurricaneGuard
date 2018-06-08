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

const HurricaneGuardAddressResolver = artifacts.require('HurricaneGuardAddressResolver.sol')
const HurricaneGuardController = artifacts.require('HurricaneGuardController.sol')
const HurricaneGuardAccessController = artifacts.require('HurricaneGuardAccessController.sol')
const HurricaneGuardDatabase = artifacts.require('HurricaneGuardDatabase.sol')
const HurricaneGuardLedger = artifacts.require('HurricaneGuardLedger.sol')
const HurricaneGuardNewPolicy = artifacts.require('HurricaneGuardNewPolicy.sol')
const HurricaneGuardUnderwrite = artifacts.require('HurricaneGuardUnderwrite.sol')
const HurricaneGuardPayout = artifacts.require('HurricaneGuardPayout.sol')

const strings = artifacts.require('./../vendors/strings.sol')

module.exports = (deployer, network, accounts) => {
  let controller

  const fund = value => web3.toWei(value, 'ether')

  log.info('Deploy HurricaneGuardController contract')

  return deployer
    // Deploy contracts
    .deploy(HurricaneGuardController)
    .then(() => log.info(`Deploy contracts for controller at: ${HurricaneGuardController.address}`))
    .then(() => deployer.deploy(HurricaneGuardAccessController, HurricaneGuardController.address))
    .then(() => deployer.deploy(HurricaneGuardDatabase, HurricaneGuardController.address))
    .then(() => deployer.link(strings, [HurricaneGuardNewPolicy, HurricaneGuardUnderwrite, HurricaneGuardPayout]))
    .then(() => deployer.deploy(HurricaneGuardLedger, HurricaneGuardController.address))
    .then(() => deployer.deploy(HurricaneGuardNewPolicy, HurricaneGuardController.address))
    .then(() => deployer.deploy(HurricaneGuardUnderwrite, HurricaneGuardController.address))
    .then(() => deployer.deploy(HurricaneGuardPayout, HurricaneGuardController.address))

    // Get controller instance
    .then(() => HurricaneGuardController.deployed())
    .then((_i) => {
      controller = _i
      return Promise.resolve()
    })

    // Register contracts
    .then(() => log.info('Register administators'))
    .then(() => controller.registerContract(accounts[2], 'HG.Funder', false))

    .then(() => controller.registerContract(accounts[3], 'HG.CustomersAdmin', false))
    .then(() => controller.registerContract(accounts[4], 'HG.Emergency', false))

    .then(() => log.info('Register contracts'))
    .then(() => controller.registerContract(HurricaneGuardAccessController.address, 'HG.AccessController', true))
    .then(() => controller.registerContract(HurricaneGuardDatabase.address, 'HG.Database', true))
    .then(() => controller.registerContract(HurricaneGuardLedger.address, 'HG.Ledger', true))
    .then(() => controller.registerContract(HurricaneGuardNewPolicy.address, 'HG.NewPolicy', true))
    .then(() => controller.registerContract(HurricaneGuardUnderwrite.address, 'HG.Underwrite', true))
    .then(() => controller.registerContract(HurricaneGuardPayout.address, 'HG.Payout', true))

    // Set new owner
    .then(() => log.info('Transfer ownership'))
    .then(() => controller.transferOwnership(accounts[1]))

    // Setup contracts
    .then(() => log.info('Setup contracts'))
    .then(() => controller.setAllContracts({from: accounts[1]}))

    // Fund Contracts

    // Fund HG.Ledger
    .then(() => log.info('Fund HG.Ledger'))
    .then(() => HurricaneGuardLedger.deployed())
    .then(HG_LG => {
      log.info(`Funder: ${accounts[2]}`)
      return HG_LG.fund({from: accounts[2], value: fund(2), gas: 5e5})
    })

    // Fund HG.Underwrite
    .then(() => log.info('Fund HG.Underwrite'))
    .then(() => HurricaneGuardUnderwrite.deployed())
    .then(HG_UW => HG_UW.fund({from: accounts[2], value: fund(1.5), gas: 5e5}))

    // Fund HG.Payout
    .then(() => log.info('Fund HG.Payout'))
    .then(() => HurricaneGuardPayout.deployed())
    .then(HG_PY => HG_PY.fund({from: accounts[2], value: fund(1.5), gas: 5e5}))

    .then(() => log.info('Deploy AddressResolver'))

    // Deploy AddressResolver on Testrpc
    .then(() => {
      // todo: check the account nonce, determine if we really need to deploy AR
      return deployer.deploy(HurricaneGuardAddressResolver)
        .then(() => HurricaneGuardAddressResolver.deployed())
        .then(HG_AR => HG_AR.setAddress(HurricaneGuardNewPolicy.address))
    })

    .then(() => {
      log.info(`Deployer: ${accounts[0]}`)
      log.info(`HG.Owner: ${accounts[1]}`)
      log.info(`HG.Funder: ${accounts[2]}`)
      log.info(`HG.CustomersAdmin: ${accounts[3]}`)
      log.info(`HG.Emergency: ${accounts[4]}`)
      log.info(`HG.Controller: ${HurricaneGuardController.address}`)
      log.info(`HG.AccessController: ${HurricaneGuardAccessController.address}`)
      log.info(`HG.Database: ${HurricaneGuardDatabase.address}`)
      log.info(`HG.Ledger: ${HurricaneGuardLedger.address}`)
      log.info(`HG.NewPolicy: ${HurricaneGuardNewPolicy.address}`)
      log.info(`HG.Underwrite: ${HurricaneGuardUnderwrite.address}`)
      log.info(`HG.Payout: ${HurricaneGuardPayout.address}`)
    })

    .catch(err => {
      console.log(err)
    })
}

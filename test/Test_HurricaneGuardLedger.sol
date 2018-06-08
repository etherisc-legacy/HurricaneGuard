pragma solidity ^0.4.11;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

import "../contracts/HurricaneGuardController.sol";
import "../contracts/HurricaneGuardLedger.sol";
import "../contracts/HurricaneGuardAccessController.sol";

contract Test_HurricaneGuardLedger {
	HurricaneGuardController HG_CT;
  HurricaneGuardLedger HG_LG;
  HurricaneGuardAccessController HG_AC;

  function test_init () {
    HG_CT = HurricaneGuardController(DeployedAddresses.HurricaneGuardController());
    HG_LG = HurricaneGuardLedger(DeployedAddresses.HurricaneGuardLedger());
    HG_AC = HurricaneGuardAccessController(DeployedAddresses.HurricaneGuardAccessController());
  }

  function test_controller_should_be_set() {
    address controller = HG_LG.controller();
    address SystemController = DeployedAddresses.HurricaneGuardController();

    Assert.equal(controller, SystemController, "Controller should be set properly");
  }

  function test_access_permissions() {
    bool permissions = HG_AC.checkPermission(104, address(this));

    Assert.equal(permissions, false, "This contracts should not have 104 permissions");
  }

  function test_set_permissions() {
    HG_AC.setPermissionById(199, "HG.Controller");

    bool permissions = HG_AC.checkPermission(199, DeployedAddresses.HurricaneGuardController());

    Assert.equal(permissions, true, "This contracts should not have 199 permissions");
  }
}

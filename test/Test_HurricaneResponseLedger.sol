pragma solidity ^0.4.11;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";

import "../contracts/HurricaneResponseController.sol";
import "../contracts/HurricaneResponseLedger.sol";
import "../contracts/HurricaneResponseAccessController.sol";

contract Test_HurricaneResponseLedger {
	HurricaneResponseController HR_CT;
  HurricaneResponseLedger HR_LG;
  HurricaneResponseAccessController HR_AC;

  function test_init () {
    HR_CT = HurricaneResponseController(DeployedAddresses.HurricaneResponseController());
    HR_LG = HurricaneResponseLedger(DeployedAddresses.HurricaneResponseLedger());
    HR_AC = HurricaneResponseAccessController(DeployedAddresses.HurricaneResponseAccessController());
  }

  function test_controller_should_be_set() {
    address controller = HR_LG.controller();
    address SystemController = DeployedAddresses.HurricaneResponseController();

    Assert.equal(controller, SystemController, "Controller should be set properly");
  }

  function test_access_permissions() {
    bool permissions = HR_AC.checkPermission(104, address(this));

    Assert.equal(permissions, false, "This contracts should not have 104 permissions");
  }

  function test_set_permissions() {
    HR_AC.setPermissionById(199, "HR.Controller");

    bool permissions = HR_AC.checkPermission(199, DeployedAddresses.HurricaneResponseController());

    Assert.equal(permissions, true, "This contracts should not have 199 permissions");
  }
}

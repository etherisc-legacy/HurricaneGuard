/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Access controller
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 *
 * HurricaneGuard with Underwriting and Payout
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */


pragma solidity 0.4.21;


import "./HurricaneGuardControlledContract.sol";
import "./HurricaneGuardDatabaseInterface.sol";
import "./HurricaneGuardConstants.sol";


contract HurricaneGuardAccessController is HurricaneGuardControlledContract, HurricaneGuardConstants {
  HurricaneGuardDatabaseInterface internal HG_DB;

  modifier onlyEmergency() {
    require(msg.sender == HG_CI.getContract("HG.Emergency"));
    _;
  }

  function HurricaneGuardAccessController(address _controller) public {
    setController(_controller);
  }

  function setContracts() public onlyController {
    HG_DB = HurricaneGuardDatabaseInterface(getContract("HG.Database"));
  }

  function setPermissionById(uint8 _perm, bytes32 _id) public {
    HG_DB.setAccessControl(msg.sender, HG_CI.getContract(_id), _perm);
  }

  function fixPermission(address _target, address _accessor, uint8 _perm, bool _access) public onlyEmergency {
    HG_DB.setAccessControl(
      _target,
      _accessor,
      _perm,
      _access
    );
  }

  function setPermissionById(uint8 _perm, bytes32 _id, bool _access) public {
    HG_DB.setAccessControl(
      msg.sender,
      HG_CI.getContract(_id),
      _perm,
      _access
    );
  }

  function setPermissionByAddress(uint8 _perm, address _addr) public {
    HG_DB.setAccessControl(msg.sender, _addr, _perm);
  }

  function setPermissionByAddress(uint8 _perm, address _addr, bool _access) public {
    HG_DB.setAccessControl(
      msg.sender,
      _addr,
      _perm,
      _access
    );
  }

  function checkPermission(uint8 _perm, address _addr) public returns (bool _success) {
    _success = HG_DB.getAccessControl(msg.sender, _addr, _perm);
  }
}

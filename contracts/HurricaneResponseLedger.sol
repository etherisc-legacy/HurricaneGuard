/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Ledger contract
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 *
 * Hurricane Response with Underwriting and Payout
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */


pragma solidity ^0.4.11;


import "./HurricaneResponseControlledContract.sol";
import "./HurricaneResponseAccessControllerInterface.sol";
import "./HurricaneResponseDatabaseInterface.sol";
import "./HurricaneResponseLedgerInterface.sol";
import "./HurricaneResponseConstants.sol";

contract HurricaneResponseLedger is HurricaneResponseControlledContract, HurricaneResponseLedgerInterface, HurricaneResponseConstants {
  HurricaneResponseDatabaseInterface HR_DB;
  HurricaneResponseAccessControllerInterface HR_AC;

  function HurricaneResponseLedger(address _controller) {
    setController(_controller);
  }

  function setContracts() onlyController {
    HR_AC = HurricaneResponseAccessControllerInterface(getContract("HR.AccessController"));
    HR_DB = HurricaneResponseDatabaseInterface(getContract("HR.Database"));

    HR_AC.setPermissionById(101, "HR.NewPolicy");
    HR_AC.setPermissionById(101, "HR.Controller"); // todo: check!

    HR_AC.setPermissionById(102, "HR.Payout");
    HR_AC.setPermissionById(102, "HR.NewPolicy");
    HR_AC.setPermissionById(102, "HR.Controller"); // todo: check!
    HR_AC.setPermissionById(102, "HR.Underwrite");
    HR_AC.setPermissionById(102, "HR.Owner");

    HR_AC.setPermissionById(103, "HR.Funder");
    HR_AC.setPermissionById(103, "HR.Underwrite");
    HR_AC.setPermissionById(103, "HR.Payout");
    HR_AC.setPermissionById(103, "HR.Ledger");
    HR_AC.setPermissionById(103, "HR.NewPolicy");
    HR_AC.setPermissionById(103, "HR.Controller");
    HR_AC.setPermissionById(103, "HR.Owner");

    HR_AC.setPermissionById(104, "HR.Funder");
  }

  /*
   * @dev Fund contract
   */
  function fund() payable {
    require(HR_AC.checkPermission(104, msg.sender));

    bookkeeping(Acc.Balance, Acc.RiskFund, msg.value);

    // todo: fire funding event
  }

  function receiveFunds(Acc _to) payable {
    require(HR_AC.checkPermission(101, msg.sender));

    LogReceiveFunds(msg.sender, uint8(_to), msg.value);

    bookkeeping(Acc.Balance, _to, msg.value);
  }

  function sendFunds(address _recipient, Acc _from, uint _amount) returns (bool _success) {
    require(HR_AC.checkPermission(102, msg.sender));

    if (this.balance < _amount) {
      return false; // unsufficient funds
    }

    LogSendFunds(_recipient, uint8(_from), _amount);

    bookkeeping(_from, Acc.Balance, _amount); // cash out payout

    if (!_recipient.send(_amount)) {
      bookkeeping(Acc.Balance, _from, _amount);
      _success = false;
    } else {
      _success = true;
    }
  }

  // invariant: acc_Premium + acc_RiskFund + acc_Payout + acc_Balance + acc_Reward + acc_OraclizeCosts == 0

  function bookkeeping(Acc _from, Acc _to, uint256 _amount) {
    require(HR_AC.checkPermission(103, msg.sender));

    // check against type cast overflow
    assert(int256(_amount) > 0);

    // overflow check is done in FD_DB
    HR_DB.setLedger(uint8(_from), -int(_amount));
    HR_DB.setLedger(uint8(_to), int(_amount));
  }
}

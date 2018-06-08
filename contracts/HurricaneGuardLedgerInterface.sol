/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Ledger contract interface
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock, Stephan Karpischek
 *
 * HurricaneGuard with Underwriting and Payout
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */


pragma solidity ^0.4.11;


import "./HurricaneGuardDatabaseModel.sol";

contract HurricaneGuardLedgerInterface is HurricaneGuardDatabaseModel {
  function receiveFunds(Acc _to) payable;

  function sendFunds(address _recipient, Acc _from, uint _amount) returns (bool _success);

  function bookkeeping(Acc _from, Acc _to, uint amount);
}

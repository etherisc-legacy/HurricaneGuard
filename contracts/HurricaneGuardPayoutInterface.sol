/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Payout contract interface
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock, Stephan Karpischek
 *
 * Hurricane Response with Underwriting and Payout
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */


pragma solidity ^0.4.11;


contract HurricaneGuardPayoutInterface {
  function schedulePayoutOraclizeCall(uint _policyId, bytes32 _riskId, uint _offset);
}

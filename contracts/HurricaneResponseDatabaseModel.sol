/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description Database model
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


contract HurricaneResponseDatabaseModel {

  // Ledger accounts.
  enum Acc {
    Premium,      // 0
    RiskFund,     // 1
    Payout,       // 2
    Balance,      // 3
    Reward,       // 4
    OraclizeCosts // 5
  }

  // policy Status Codes and meaning:
  //
  // 00 = Applied:	  the customer has payed a premium, but the oracle has
  //					        not yet checked and confirmed.
  //					        The customer can still revoke the policy.
  // 01 = Accepted:	  the oracle has checked and confirmed.
  //					        The customer can still revoke the policy.
  // 02 = Revoked:	  The customer has revoked the policy.
  //					        The premium minus cancellation fee is payed back to the
  //					        customer by the oracle.
  // 03 = PaidOut:	  An atmospheric event of specified intensity happened
  //                  at a specifc distance from the submitted location.
  //					        The oracle has checked and payed out.
  // 04 = Expired:	  The season covered has ended.
  //					        No payout.
  // 05 = Declined:	  The application was invalid.
  //					        The premium minus cancellation fee is payed back to the
  //					        customer by the oracle.
  // 06 = SendFailed:	During Revoke, Decline or Payout, sending ether failed
  //					        for unknown reasons.
  //					        The funds remain in the contracts RiskFund.


  //                   00       01        02       03        04      05           06
  enum policyState { Applied, Accepted, Revoked, PaidOut, Expired, Declined, SendFailed }

  // oraclize callback types:
  enum oraclizeState { ForUnderwriting, ForPayout }

  //               00   01   02   03
  enum Currency { ETH, EUR, USD, GBP }

  // the policy structure: this structure keeps track of the individual parameters of a policy.
  // typically customer address, premium and some status information.
  struct Policy {
    // 0 - the customer
    address customer;

    // 1 - premium
    uint premium;
    // risk specific parameters:
    // 2 - pointer to the risk in the risks mapping
    bytes32 riskId;
    // custom payout pattern
    // in future versions, customer will be able to tamper with this array.
    // to keep things simple, we have decided to hard-code the array for all policies.
    // uint8[5] pattern;
    // 3 - probability weight. this is the central parameter
    uint weight;
    // 4 - calculated Payout
    uint calculatedPayout;
    // 5 - actual Payout
    uint actualPayout;

    // status fields:
    // 6 - the state of the policy
    policyState state;
    // 7 - time of last state change
    uint stateTime;
    // 8 - state change message/reason
    bytes32 stateMessage;
    // 9 - TLSNotary Proof
    bytes proof;
    // 10 - Currency
    Currency currency;
    // 10 - External customer id
    bytes32 customerExternalId;
    // 11 - Policy lat, lng
    bytes32 latlng;
  }

  // the risk structure; this structure keeps track of the risk-
  // specific parameters.
  // several policies can share the same risk structure
  // (typically same people in a specific geographic
  // area [market] for a particular season)
  struct Risk {
    // 0 - Market, "PR" for pilot
    bytes32 market;
    // 1 - Season, the current year
    bytes32 season;
    // 2 - the event category that triggered payouts
    bytes32 category;
    // 3 - we limit the cumulated weighted premium to avoid cluster risks
    uint cumulatedWeightedPremium;
    // 4 - max cumulated Payout for this risk
    uint premiumMultiplier;
  }

  // the oraclize callback structure: we use several oraclize calls.
  // all oraclize calls will result in a common callback to __callback(...).
  // to keep track of the different querys we have to introduce this struct.
  struct OraclizeCallback {
    // for which policy have we called?
    uint policyId;
    // for which purpose did we call? {ForUnderwrite | ForPayout}
    oraclizeState oState;
  }

  struct Customer {
    bytes32 customerExternalId;
    bool identityConfirmed;
  }
}

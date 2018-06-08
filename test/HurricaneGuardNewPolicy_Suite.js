/**
 * Unit tests for FlightDelayNewPolicy
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

/* global web3 */

const padRight = (s, len, ch) => (s + Array(len).join(ch || ' ')).slice(0, len)

const bytes32 = s => padRight(web3.toHex(s), 66, '0')

const standardTx = value => context => ({
  from: context.defAccount,
  gas: 4.7e6,
  value: value || web3.toWei(1000, 'finney')
})

// keccak256 for PR + 2018
const riskId = '0xc3fc85f142288d154421a7b6a31db9a536243b2a4d0c100aef252ae89c8a524a'

const standardPolicy = (latlng, market, season, customerId, currency) => (id) => {
  return {
    id,
    latlng,
    market,
    season,
    customerId,
    currency,
    riskId
  }
}

const standardTimeoutHandler = (resolve, reject, context) => () => {
  context.logger.logLine('running into timeout', '', 'info')
  reject('Shit! we got stuck.')
}

const standardLogHandler = eventDef => (resolve, reject, context) => (log) => {
  if (log.event === 'LogSetState') {
    // eslint-disable-next-line
    context.lastState = context.web3.toUtf8(log.args._stateMessage)
    context.logger.logLine('SetState', context.lastState, 'info')
  }
  if (context.eventsHappened(eventDef)) {
    resolve(`Hurray - ${context.lastState}`)
  }
}

const testSuite = [
  {
    testId: '#01',
    shouldDoSomething: 'should process with ETH #01 - No covered hurricane event (no payout)',
    data: standardPolicy('44.6,10.43', 'PR', '2018', 'A000001', 0 /* ETH */),
    timeoutHandler: standardTimeoutHandler,
    timeoutValue: 80000,
    logHandlerUnderwrite: standardLogHandler([
      {
        event: 'LogReceiveFunds'
      }, {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('Policy underwritten by oracle')
        }
      }
    ]),
    logHandlerPayout: standardLogHandler([
      {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('No covered event for payout')
        }
      }
    ]),
    tx: standardTx(web3.toWei(0.5, 'ether')),
    payoutTx: standardTx(0)
  }, {
    testId: '#02',
    shouldDoSomething: 'should process with USD #02 - No covered hurricane event (no payout)',
    data: standardPolicy('44.6,10.43', 'PR', '2018', 'A000002', 2 /* USD */),
    timeoutHandler: standardTimeoutHandler,
    timeoutValue: 80000,
    logHandlerUnderwrite: standardLogHandler([
      {
        event: 'LogReceiveFunds'
      }, {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('Policy underwritten by oracle')
        }
      }
    ]),
    logHandlerPayout: standardLogHandler([
      {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('No covered event for payout')
        }
      }
    ]),
    tx: standardTx(2500),
    payoutTx: standardTx(0)
  }, {
    testId: '#03',
    shouldDoSomething: 'should process with USD #03 - Category 5 hurricane event (full payout)',
    data: standardPolicy('-79.9763878,-83.8465009', 'PR', '2018', 'A000003', 2 /* USD */),
    timeoutHandler: standardTimeoutHandler,
    timeoutValue: 80000,
    logHandlerUnderwrite: standardLogHandler([
      {
        event: 'LogReceiveFunds'
      }, {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('Policy underwritten by oracle')
        }
      }
    ]),
    logHandlerPayout: standardLogHandler([
      {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('Payout successful!')
        }
      }
    ]),
    tx: standardTx(2500),
    payoutTx: standardTx(0)
  }, {
    testId: '#04',
    shouldDoSomething: 'should process with USD #04 - Category 4 hurricane event (full payout)',
    data: standardPolicy('39.6695997,-82.9857354', 'PR', '2018', 'A000004', 2 /* USD */),
    timeoutHandler: standardTimeoutHandler,
    timeoutValue: 80000,
    logHandlerUnderwrite: standardLogHandler([
      {
        event: 'LogReceiveFunds'
      }, {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('Policy underwritten by oracle')
        }
      }
    ]),
    logHandlerPayout: standardLogHandler([
      {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('Payout successful!')
        }
      }
    ]),
    tx: standardTx(2500),
    payoutTx: standardTx(0)
  }, {
    testId: '#05',
    shouldDoSomething: 'should process with USD #05 - Category 3 hurricane event (full payout)',
    data: standardPolicy('41.0037069,43.1534068', 'PR', '2018', 'A000005', 2 /* USD */),
    timeoutHandler: standardTimeoutHandler,
    timeoutValue: 80000,
    logHandlerUnderwrite: standardLogHandler([
      {
        event: 'LogReceiveFunds'
      }, {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('Policy underwritten by oracle')
        }
      }
    ]),
    logHandlerPayout: standardLogHandler([
      {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('Payout successful!')
        }
      }
    ]),
    tx: standardTx(2500),
    payoutTx: standardTx(0)
  }, {
    testId: '#06',
    shouldDoSomething: 'should process with USD #06 - Category 3 hurricane event (5 - 15 miles, partial payout)',
    data: standardPolicy('-31.399401,-64.2643845', 'PR', '2018', 'A000006', 2 /* USD */),
    timeoutHandler: standardTimeoutHandler,
    timeoutValue: 80000,
    logHandlerUnderwrite: standardLogHandler([
      {
        event: 'LogReceiveFunds'
      }, {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('Policy underwritten by oracle')
        }
      }
    ]),
    logHandlerPayout: standardLogHandler([
      {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('Payout successful!')
        }
      }
    ]),
    tx: standardTx(2500),
    payoutTx: standardTx(0)
  }, {
    testId: '#07',
    shouldDoSomething: 'should process with USD #07 - Category 4 hurricane event (15 - 30 miles, partial payout)',
    data: standardPolicy('-45.6585008,-71.6193204', 'PR', '2018', 'A000007', 2 /* USD */),
    timeoutHandler: standardTimeoutHandler,
    timeoutValue: 80000,
    logHandlerUnderwrite: standardLogHandler([
      {
        event: 'LogReceiveFunds'
      }, {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('Policy underwritten by oracle')
        }
      }
    ]),
    logHandlerPayout: standardLogHandler([
      {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('Payout successful!')
        }
      }
    ]),
    tx: standardTx(2500),
    payoutTx: standardTx(0)
  }, {
    testId: '#08',
    shouldDoSomething: 'should process with USD #08 - Category 5 hurricane event (5 - 15 miles, partial payout)',
    data: standardPolicy('75.8728916,-88.3949288', 'PR', '2018', 'A000008', 0 /* ETH */),
    timeoutHandler: standardTimeoutHandler,
    timeoutValue: 80000,
    logHandlerUnderwrite: standardLogHandler([
      {
        event: 'LogReceiveFunds'
      }, {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('Policy underwritten by oracle')
        }
      }
    ]),
    logHandlerPayout: standardLogHandler([
      {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('Payout successful!')
        }
      }
    ]),
    tx: standardTx(web3.toWei(0.25, 'ether')),
    payoutTx: standardTx(0)
  }, {
    testId: '#09',
    shouldDoSomething: 'should process with USD #09 - Category 5 hurricane event (+30 miles, no payout)',
    data: standardPolicy('76.0125982,-88.6843306', 'PR', '2018', 'A000009', 2 /* USD */),
    timeoutHandler: standardTimeoutHandler,
    timeoutValue: 80000,
    logHandlerUnderwrite: standardLogHandler([
      {
        event: 'LogReceiveFunds'
      }, {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('Policy underwritten by oracle')
        }
      }
    ]),
    logHandlerPayout: standardLogHandler([
      {
        event: 'LogSetState',
        args: {
          _stateMessage: bytes32('Too far for payout')
        }
      }
    ]),
    tx: standardTx(2500),
    payoutTx: standardTx(0)
  }
]

module.exports = testSuite

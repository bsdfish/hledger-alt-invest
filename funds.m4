define(INVEST,
  $1 Invest
    $2     
    $3      $$4
    `ifelse(len(`$5'), 0, , Income:Fee:WireFee   $$5)'
)

define(CAP_CALL,
  $1 Capital Call
    $2     
    $3      $$4
    `ifelse(len(`$5'), 0, , Income:Fee:WireFee   $$5)'
)

define(DISTRIBUTION,
  $1 Distribution
    $2       $$4
    $3      
)

define(INCOME,
  $1 Distribution(Income)
    $3       0
    $2       $$4
    `ifelse(len(`$5'), 0, , Income:Fee:IncomingWireFee   $$5)'
    `patsubst(`$3', `Asset', `Income:PNL')'
)

define(MTM,
  $1 Mark To Market
  $2  =       $$3
  `patsubst(`$2', `Asset', `Income:PNL')'
)

define(MTM_ILL,
  $1 Mark To Market (illiquid)
  $2  =       $$3
  `patsubst(`$2', `Asset', `Income:M')'
)


INVEST(2023-01-01, Asset:Bank:MyBank,   Asset:Alt:PE:GoodFund,     50000, 20)
INVEST(2023-01-01, Asset:Bank:MyBank,   Asset:Alt:PE:BadFund,      30000, 20)
INVEST(2023-01-01, Asset:Bank:MyBank,   Asset:Alt:RE:FancyHouse,   25000, 20)
INVEST(2023-07-01, Asset:Bank:MyBank,   Asset:Alt:PE:GoodFund,     50000, 20)
INVEST(2023-09-25, Asset:Bank:MyBank,   Asset:Alt:PE:GoodFund,     20000, 20)

INCOME(2023-10-05, Asset:Bank:MyBank,   Asset:Alt:PE:GoodFund,      5000, 10)
MTM(2023-12-30, Asset:Alt:PE:GoodFund,                            140000)
MTM(2023-12-30, Asset:Alt:PE:BadFund,                              20000)



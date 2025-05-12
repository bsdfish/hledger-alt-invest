# Hledger for alternative investments

## Hledger 101

[Hledger](https://hledger.org/) is a great command line accounting tool.  The basic idea is that you have a text file of transactions and can then do queries on them.  Every transaction is double-entry though unlike conventional accounting, it doesn't do debits and credits and instead, has one side of the ledger with a negative sign.

For example, a basic file could be
```
2025/01/01  Earned Salary
    Asset:Bank       $1000
    Income:Job      -$1000

2025/01/05 Bought Groceries
   Expense:Groceries  $50
   Asset:Bank        -$50
```

and then, you can run 
```
(base) asimma@rad2:~/ledger/tutorial$ hledger -f sample.journal bal
                $950  Asset:Bank
                 $50  Expense:Groceries
              $-1000  Income:Job
--------------------
                   0  
```

showing that in the end, you have $950 in your bank account, spent $50 on groceries and have -$1000 (in other words, were paid $1000) from your job.

You can also see a register like
```
(base) asimma@rad2:~/ledger/tutorial$ hledger -f sample.journal reg
2025-01-01 Earned Salary                    Asset:Bank                              $1000         $1000
                                            Income:Job                             $-1000             0
2025-01-05 Bought Groceries                 Expense:Groceries                         $50           $50
                                            Asset:Bank                               $-50             0

```

Anyway, you can learn more about hleder on your own if you'd like, here I'll write about how it's useful for tracking alternative investments.  One last note: every transaction must balance to 0 so you can omit some number and hledger will calculate it from the rest.  It's good practice not for error-checking purposes with manual entry but may be helpful for scripts, etc later.

##  Manual alternative investment use

My (sample) register file looks something like:
```
2023-01-01  Invested in GoodFund (PE)
   Asset:Alt:PE:GoodFund            $50000
   Expense:Fee:WireFee                 $20
   Asset:Bank:MyBank               $-50020

2023-01-01  Invested in BadFund (PE)
   Asset:Alt:PE:BadFund             $30000
   Expense:Fee:WireFee                 $20
   Asset:Bank:MyBank               $-30020

2023-01-01  Invested in FancyHouse (RE)
   Asset:Alt:RE:BadFund             $25000
   Expense:Fee:WireFee                 $20
   Asset:Bank:MyBank               $-25020

2023-07-01  GoodFund capital call
   Asset:Alt:PE:GoodFund            $50000
   Expense:Fee:WireFee                 $20
   Asset:Bank:MyBank               $-50020

2023-09-25  BadFund capital call
   Asset:Alt:PE:GoodFund            $20000
   Expense:Fee:WireFee                 $20
   Asset:Bank:MyBank               $-20020
```

Now we can query our balances and see
```
(base) asimma@rad2:~/ledger/tutorial$ hledger -f funds.journal bal -e 2023-09-30
              $30000  Asset:Alt:PE:BadFund
             $120000  Asset:Alt:PE:GoodFund
              $25000  Asset:Alt:RE:BadFund
            $-175100  Asset:Bank:MyBank
                $100  Expense:Fee:WireFee
```

Now, our funds produce some distributions.  We always have to determine whether the distributions are return on capital vs return of capital.  For now, lets assume they're return on capital.

```
2023-10-05  GoodFund distributes $5000 in earnings
    Asset:Bank:MyBank               $4990
    Expense:Fee:InboundWireFee        $10
    Income:Alt:PE:GoodFund         -$5000
    Asset:Alt:PE:GoodFund              $0  ; No change to value of asset, needed for ROI later
```

So the value of each fund shouldn't change but there was $5000 of income

```
(base) asimma@rad2:~/ledger/tutorial$ hledger -f funds.journal bal -e 2023-10-06
              $30000  Asset:Alt:PE:BadFund
             $120000  Asset:Alt:PE:GoodFund
              $25000  Asset:Alt:RE:BadFund
            $-170110  Asset:Bank:MyBank
                 $10  Expense:Fee:InboundWireFee
                $100  Expense:Fee:WireFee
              $-5000  Income:Alt:PE:GoodFund
```

Lets look at our ROI:
```
(base) asimma@rad2:~/ledger/tutorial$ hledger -f funds.journal roi --inv Asset:Alt:PE:GoodFund --pnl Income -e 2023-10-15
+---++------------+------------++---------------+----------+-------------+-------++-------+-------+
|   ||      Begin |        End || Value (begin) | Cashflow | Value (end) |   PnL ||   IRR |   TWR |
+===++============+============++===============+==========+=============+=======++=======+=======+
| 1 || 2023-01-01 | 2023-10-14 ||             0 |  $115000 |     $120000 | $5000 || 9.27% | 5.33% |
+---++------------+------------++---------------+----------+-------------+-------++-------+-------+
```

Not great but not terrible.  What about for all of our PE investments?

```
(base) asimma@rad2:~/ledger/tutorial$ hledger -f funds.journal roi --inv Asset:Alt:PE --pnl Income -e 2023-10-15
+---++------------+------------++---------------+----------+-------------+-------++-------+-------+
|   ||      Begin |        End || Value (begin) | Cashflow | Value (end) |   PnL ||   IRR |   TWR |
+===++============+============++===============+==========+=============+=======++=======+=======+
| 1 || 2023-01-01 | 2023-10-14 ||             0 |  $145000 |     $150000 | $5000 || 6.44% | 4.25% |
+---++------------+------------++---------------+----------+-------------+-------++-------+-------+
```

Less inspiring.  OK, now it's the end of the year and we have new marks for every fund.  GoodFund did great and is now marked at $140,000; BadFund sucked and is only worth $20,000 and the RE fund just has no new updates.

```
2023-12-30 GoodFund Mark
   Asset:Alt:PE:GoodFund           = $140000
   Income:MTM:Alt:PE:GoodFund    ; Gains come from the 'MTM' account

2023-12-30 BadFund Mark
   Asset:Alt:PE:BadFund           = $20000
   Income:MTM:Alt:PE:BadFund    ; Gains come from the 'MTM' account
```


Returns are 
```
(base) asimma@rad2:~/ledger/tutorial$ hledger -f funds.journal roi --inv Asset:Alt:PE:GoodFund --pnl Income -e 2023-12-31
+---++------------+------------++---------------+----------+-------------+--------++--------+--------+
|   ||      Begin |        End || Value (begin) | Cashflow | Value (end) |    PnL ||    IRR |    TWR |
+===++============+============++===============+==========+=============+========++========+========+
| 1 || 2023-01-01 | 2023-12-30 ||             0 |  $115000 |     $140000 | $25000 || 32.52% | 21.60% |
+---++------------+------------++---------------+----------+-------------+--------++--------+--------+

(base) asimma@rad2:~/ledger/tutorial$ hledger -f funds.journal roi --inv Asset:Alt:PE:BadFund --pnl Income -e 2023-12-31
+---++------------+------------++---------------+----------+-------------+---------++---------+---------+
|   ||      Begin |        End || Value (begin) | Cashflow | Value (end) |     PnL ||     IRR |     TWR |
+===++============+============++===============+==========+=============+=========++=========+=========+
| 1 || 2023-01-01 | 2023-12-30 ||             0 |   $30000 |      $20000 | $-10000 || -33.41% | -33.40% |
+---++------------+------------++---------------+----------+-------------+---------++---------+---------+

(base) asimma@rad2:~/ledger/tutorial$ hledger -f funds.journal roi --inv Asset:Alt:PE --pnl Income -e 2023-12-31
+---++------------+------------++---------------+----------+-------------+--------++--------+--------+
|   ||      Begin |        End || Value (begin) | Cashflow | Value (end) |    PnL ||    IRR |    TWR |
+===++============+============++===============+==========+=============+========++========+========+
| 1 || 2023-01-01 | 2023-12-30 ||             0 |  $145000 |     $160000 | $15000 || 13.90% | 10.25% |
+---++------------+------------++---------------+----------+-------------+--------++--------+--------+
```


## Macros
Unfortunately, our journal file is pretty long and ugly.  However, with some m4 (ugh, I'm sorry) magic, we can have a journal that looks like


```
INVEST(2023-01-01, Asset:Bank:MyBank,   Asset:Alt:PE:GoodFund,     50000, 20)
INVEST(2023-01-01, Asset:Bank:MyBank,   Asset:Alt:PE:BadFund,      30000, 20)
INVEST(2023-01-01, Asset:Bank:MyBank,   Asset:Alt:RE:FancyHouse,   25000, 20)
INVEST(2023-07-01, Asset:Bank:MyBank,   Asset:Alt:PE:GoodFund,     50000, 20)
INVEST(2023-09-25, Asset:Bank:MyBank,   Asset:Alt:PE:GoodFund,     20000, 20)

INCOME(2023-10-05, Asset:Bank:MyBank,   Asset:Alt:PE:GoodFund,      5000, 10)
MTM(2023-12-30, Asset:Alt:PE:GoodFund,                            140000)
MTM(2023-12-30, Asset:Alt:PE:BadFund,                              20000)

```

For my own setup, I have the following macros:
* INVEST: New investment or capital call
* INCOME: A distribution that doesn't reduce the value of the investment (Return On Capital)
* DISTRIBUTION: A distribution that redues the value of the account (Return Of Capital)
* MTM:  Mark to Market: when we have a new valuation of the fund.  I use this only for 'true' marks, ie hedge funds with marketable securities.
* MTM_ILL: Illiquid Mark To Market: used when there's a valuation but it's based on some valuation process that's not necessarily reliable.  I can exclude these in my reports.


## Notes and tips

 * The start date gets included in the time period, the end date doesn't.  So '-e 2023-12-31' actually excludes the last day December.  This makes the more common case much more convenient though: to select just 2024, do '-b 2024 -e 2025', to do the first half do '-b 2024 -e 2024-07', etc.
 * This is great for self-directed 401k.  You can have things like Asset:Roth:Bank, Asset:Roth:Fund1, Asset:Rollover:Fund2, etc.  I have a few extra add-ons to track tax basis for Roth conversions if I have some after-tax traditional funds, etc.  Contributions can come from Contrib:Roth:2025 account so you can see how much Roth contributions you did in 2025, etc.  

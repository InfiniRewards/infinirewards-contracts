# Cafe Rewards Template

This template provides a simple loyalty program for cafés using Cairo 2.0.
Customers collect digital stamps and redeem a free drink once they reach the
configured threshold. When a free drink is redeemed the customer also receives
points via the `InfiniRewardsPoints` contract.

## Key Features

- Track stamps per customer address.
- Configurable number of stamps required for a reward.
- Basic functions to issue a stamp and redeem a free drink.
- Demonstrates calling the shared `InfiniRewardsPoints` token contract to reward
  customers.

This contract is intended as a starting point and can be extended with
additional logic or reward types.

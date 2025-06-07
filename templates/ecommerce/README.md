# E-commerce Rewards Template

A minimal loyalty contract for online stores. It records purchases and directly
mints points for the buyer via the shared `InfiniRewardsPoints` contract. It can
also issue voucher collectibles through the `InfiniRewardsCollectible` contract.
The template can be expanded to include cashback logic or deeper integration
with the broader InfiniRewards ecosystem.

## Key Features

- Stores an optional cashback rate parameter.
- Function to record a purchase and mint loyalty points for the buyer.
- Ability to issue voucher collectibles to customers.

# Gym Membership Template

This template implements a basic membership system for gyms. Each member
receives a membership with a fixed duration. When a member registers a
collectible token is minted via the `InfiniRewardsCollectible` contract to
represent the membership. The contract also stores the expiry timestamp and
provides functions to register members and check their active status.

## Key Features

- Set a global membership duration on deployment.
- Register members with an expiry date.
- View method to verify if a membership is active.

Extend this contract to add more advanced features such as session tracking or
additional collectible types.

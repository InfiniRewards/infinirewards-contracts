mod InfiniRewardsUserAccount;
mod InfiniRewardsMerchantAccount;
mod InfiniRewardsFactory;
mod InfiniRewardsPoints;
mod InfiniRewardsCollectible;
mod interfaces {
    pub mod IInfiniRewards;
    pub mod IInfiniRewardsPoints;
    pub mod IInfiniRewardsMerchantAccount;
    pub mod IInfiniRewardsUserAccount;
    pub mod permission;
    pub mod policy;
    pub mod session_key;
}

pub mod components {
    pub mod account;
}

pub mod utils {
    pub mod asserts;
}